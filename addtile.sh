#!/usr/bin/env bash
# ==============================================================================
# StatusPulse - Add Tile Status Agent
# Regularly queries service endpoints and updates the dashboard with visual tiles.
# ==============================================================================

set -eo pipefail

# Environment & File Variables Setup
enfilevar_setup() {
  STATFILE="${CURRHOME}/StatusOutput"
  OUT="${CURRHOME}/today.html"
  CONFIG_PATH="${CURRHOME}/config/app.conf"
  INST_URLS="${CURRHOME}/config/instanceurl_file"
  INST_NAMES="${CURRHOME}/config/instance_names"
  XDATAFILE="${CURRHOME}/xdata.pid"
  LOGFILE="${CURRHOME}/log.out"
}

# Instance-level File Variables Setup
ienfilevar_setup() {
  local instance="$1"
  CONFIG_PATH="${CURRHOME}/config/${instance}.insta"
  CURRHOME="${CURRHOME}/instances/${instance}"
  STATFILE="${CURRHOME}/StatusOutput"
  OUT="${CURRHOME}/index.html"
  INST_URLS="${CURRHOME}/config/${instance}_instanceurl_file"
  INST_NAMES="${CURRHOME}/config/${instance}_instance_names"
  XDATAFILE="${CURRHOME}/xdata.pid"
  LOGFILE="${CURRHOME}/log.out"
}

STARTXDATA=350
TILE='<rect class="status" width="22" height="22" rx="6" ry="6" x="xdata" y="ydata"><title>version</title></rect>'
ver_re='^[0-9]+(.*)?$'

# Parse URLs list from config file
read_config() {
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "<h1>Can't monitor the application. Config file is missing.</h1>" >> "$OUT"
    exit 1
  fi
  
  local content
  content=$(cat "$CONFIG_PATH")
  
  if [[ "$content" == *,* ]]; then
    COMPURL=$(echo "$content" | sed 's/[A-Za-z0-9_/-]*,//g')
  elif [[ "$content" == */* ]]; then
    COMPURL="$content"
  elif ! ([[ "$content" == *,* ]] || [[ "$content" == */* ]]); then
    if [ -f "$INST_URLS" ]; then
      COMPURL=$(cat "$INST_URLS")
    else
      echo "<h1>Can't monitor the application. Config file is missing or corrupted.</h1>" >> "$OUT"
      exit 1
    fi
  fi
}

remove_vhost() {
  rm -f vhost_unknown* 2>/dev/null || true
}

# Syntactically inject the tile element inside the SVG and maintain valid tags
add_tile() {
  local xval="$1"
  local yval="$2"
  local status_class="$3"
  local version_str="$4"
  
  # Format tile HTML
  local formatted_tile
  formatted_tile=$(echo "$TILE" | sed "s/xdata/$xval/g" | sed "s/ydata/$yval/g" | sed "s/status/$status_class/g" | sed "s/version/$version_str/g")
  
  if [ -f "$OUT" ]; then
    # Create temporary file containing everything except closed SVG/HTML lines
    # Safe fallback if file is short
    local total_lines
    total_lines=$(wc -l < "$OUT")
    if [ "$total_lines" -gt 3 ]; then
      head -n -2 "$OUT" > "${OUT}.tmp"
      mv "${OUT}.tmp" "$OUT"
    fi
    
    # Append the new grid tile
    echo "$formatted_tile" >> "$OUT"
    
    # Re-close SVG and HTML document structures
    echo "</g>" >> "$OUT"
    echo "</svg></div></div></body></html>" >> "$OUT"
  else
    # Fallback to appending if file is not initialized
    echo "$formatted_tile" >> "$OUT"
  fi
}

# Queries status from configured Tomcat endpoints
status_puller() {
  local xval="$1"
  local yval=5
  
  for line in $COMPURL; do
    if [ -z "$line" ]; then
      continue
    fi
    
    local val=0
    local version_no="UNKNOWN"
    
    # Clean temporary files first
    rm -f version.html* 2>/dev/null || true
    
    # Attempt wget with connection timeouts
    if wget -S --timeout=2 --waitretry=1 --tries=2 --retry-connrefused "http://${line}/version.html" -O version.html >/dev/null 2>&1; then
      val=200
    else
      val=500
    fi
    
    if [ "$val" -eq 200 ] && [ -f version.html ]; then
      # Parse Tomcat version.html
      # Format expected: "Version : 1.2.3"
      if grep -q 'Version :' version.html; then
        version_no=$(grep 'Version :' version.html | awk '{print $3}' | awk -F '<' '{print $2}' | awk -F '>' '{print $2}' || echo "VALID")
      fi
      
      # Clean fallback if parsing returned empty
      if [ -z "$version_no" ]; then
        version_no="ACTIVE"
      fi
      
      if [[ "$version_no" =~ $ver_re ]]; then
        add_tile "$xval" "$yval" "pass" "$version_no"
      else
        add_tile "$xval" "$yval" "pass" "VERSION ISSUE"
      fi
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') - Connection error on: $line" >> "$LOGFILE"
      add_tile "$xval" "$yval" "fail" "DOWN"
    fi
    
    rm -f version.html* 2>/dev/null || true
    yval=$((yval + 30))
  done
}

post_executor() {
  local xval="$1"
  echo "$((xval + 30))" > "$XDATAFILE"
  remove_vhost
}

microexecutor() {
  local xval="$1"
  read_config
  status_puller "$xval"
  post_executor "$xval"
}

# Computes precise horizontal coordinate offset based on execution time
getxdata() {
  local csttime
  csttime=$(TZ=":US/Central" date +%Y-%m-%d-%H:%M)
  local regextz="^([^-]+)-(.*)-(.*)-(.*):(.*)$"
  local initial_pixel=60
  
  if [[ "$csttime" =~ $regextz ]]; then
    local currhr="${BASH_REMATCH[4]}"
    local currmin="${BASH_REMATCH[5]}"
    
    # Strip leading zeros to avoid octal math parse errors in bash
    currhr=$((10#$currhr * initial_pixel))
    xdata=$((STARTXDATA + currhr))
    
    if [ "$((10#$currmin))" -ge 30 ]; then
      xdata=$((xdata + 30))
    fi
  else
    # Fallback to safe default
    xdata=350
  fi
}

executor() {
  getxdata
  if [[ "$xdata" -ge 350 && "$xdata" -le 1760 ]]; then
    microexecutor "$xdata"
  else
    exit 1
  fi
}

appmain_addtile() {
  if [ -f "${OUT}" ]; then
    executor
  else
    exit 1
  fi
}

instmain_setup() {
  if ls config/*.insta >/dev/null 2>&1; then
    instacomp=$(ls config/*.insta | awk -F/ '{print $NF}' | sed 's/\.insta//g')
  else
    echo "Instance configuration doesn't exist"
    exit 0
  fi
  
  for i in $instacomp; do
    if [ -d "$i" ]; then
      ienfilevar_setup "$i"
      appmain_addtile
    fi
  done
}

appmain_setup() {
  enfilevar_setup
  appmain_addtile
}

main() {
  local exefor="$1"
  if [ "$exefor" == "i" ]; then
    instmain_setup
  elif [ "$exefor" == "a" ]; then
    appmain_setup
  else
    exit 0
  fi
}

# Program Entry Point
cd "$(dirname "$0")"
CURRHOME=$(pwd)

EXEFOR="a"
if [ $# -eq 1 ]; then
  EXEFOR="$1"
elif [ $# -eq 0 ]; then
  appmain_setup
  exit 0
else
  exit 0
fi

main "$EXEFOR"
