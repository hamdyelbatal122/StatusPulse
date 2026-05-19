#!/usr/bin/env bash
# ==============================================================================
# StatusPulse - Index Creator Script
# Initializes the daily service monitoring SVG page and sets up components.
# ==============================================================================

set -eo pipefail

# Error Handler
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Environment & File Variables Setup
enfilevar_setup() {
  STATFILE="${CURRHOME}/StatusOutput"
  OUT="${CURRHOME}/today.html"
  CONFIG_PATH="${CURRHOME}/config/app.conf"
  INST_URLS="${CURRHOME}/config/instanceurl_file"
  INST_NAMES="${CURRHOME}/config/instance_names"
  XDATAFILE="${CURRHOME}/xdata.pid"
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
}

# Setup Design Tokens and SVG Framework Elements
envar_setup() {
  avgspacefortile=32
  
  if [ ! -f "$CONFIG_PATH" ]; then
    error_exit "Configuration file missing at: $CONFIG_PATH"
  fi
  
  local line_count
  line_count=$(wc -l < "$CONFIG_PATH")
  height=$((line_count * avgspacefortile + 60))
  
  # Premium Glassmorphic design style matching StatusPulse dashboard
  FRAME='<!DOCTYPE html>
<html lang="en">
<head>
  <title>StatusPulse Service Grid</title>
  <link rel="icon" type="image/x-icon" href="favicon.ico" />
  <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
  <meta http-equiv="refresh" content="30" />
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Outfit:wght@500;600&display=swap" rel="stylesheet">
  <style>
    body {
      background-color: #0b0f19;
      margin: 0;
      padding: 0;
      overflow-x: auto;
      overflow-y: hidden;
    }
    svg {
      background-color: #0b0f19;
      font-family: "Inter", -apple-system, sans-serif;
      user-select: none;
    }
    .pass {
      fill: #10b981;
      filter: drop-shadow(0 0 2px rgba(16, 185, 129, 0.4));
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .pass:hover {
      fill: #34d399;
      filter: drop-shadow(0 0 6px rgba(52, 211, 153, 0.8));
    }
    .fail {
      fill: #ef4444;
      filter: drop-shadow(0 0 2px rgba(239, 68, 68, 0.4));
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .fail:hover {
      fill: #f87171;
      filter: drop-shadow(0 0 6px rgba(248, 113, 113, 0.8));
    }
    .warn {
      fill: #f59e0b;
      filter: drop-shadow(0 0 2px rgba(245, 158, 11, 0.4));
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .warn:hover {
      fill: #fbbf24;
      filter: drop-shadow(0 0 6px rgba(251, 191, 36, 0.8));
    }
    .status {
      fill: #1e293b;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .status:hover {
      fill: #334155;
    }
    text.comp-name {
      fill: #f3f4f6;
      font-size: 13px;
      font-weight: 500;
      font-family: "Outfit", sans-serif;
    }
    text.clock-label {
      fill: #64748b;
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.5px;
    }
  </style>
</head>
<body>
<div>
  <div>'
  
  SIZEDEF="<svg width=\"1900\" height=\"$height\">"
  HEADER="${FRAME}${SIZEDEF}"
  FOOTER='</svg></div></div></body></html>'
  GTRANSFORM='<g transform="translate(0, 40)">'
  CLOSEG='</g>'
  TILE='<rect class="status" width="22" height="22" rx="6" ry="6" x="xdata" y="ydata" v="version" />'
  CLOCK='<text class="clock-label" x="xtimloc" y="ytimloc">hour:00</text>'
  COMP='<text class="comp-name" x="xaxis" y="yaxis">__COMP__</text>'
  ver_re='^[0-9]+([.][0-9]+)?$'
  CURRDATE=$(date -d "-1 days" +%Y%m%d)
}

# Read Configuration Content and parse Headers and URLs
read_config() {
  local content
  content=$(cat "$CONFIG_PATH")
  
  if [[ "$content" == *,* ]]; then
    COMPHEADER=$(echo "$content" | sed 's/,[A-Za-z0-9.:-]*//g' | sed 's/\/[A-Za-z0-9-]*//g' | sed 's/fulfillment-//g')
    COMPURL=$(echo "$content" | sed 's/[A-Za-z0-9_/-]*,//g')
  elif [[ "$content" == */* ]]; then
    COMPHEADER=$(echo "$content" | sed 's/[A-Za-z0-9.:-]*\///g' | sed 's/fulfillment-//g')
    COMPURL="$content"
  elif ! ([[ "$content" == *,* ]] || [[ "$content" == */* ]]); then
    if [ -f "$INST_NAMES" ] && [ -f "$INST_URLS" ]; then
      COMPHEADER=$(cat "$INST_NAMES")
      COMPURL=$(cat "$INST_URLS")
    else
      error_exit "Required instances config files are missing."
    fi
  else
    echo "<h1>Can't monitor the application. Config file is missing or corrupted.</h1>" >> "$OUT"
    exit 1
  fi
}

xdatafile_checker() {
  if [ -f "${XDATAFILE}" ]; then
    rm -f "${XDATAFILE}"
  fi
}

statfile_checker() {
  if [ -f "${STATFILE}" ]; then
    rm -f "${STATFILE}"
  fi
}

remove_vhost() {
  rm -f vhost_unknown* 2>/dev/null || true
}

# Rotate and archive old index/today HTML outputs
env_check() {
  if [ -f "${OUT}" ]; then
    index_end
    if [[ "$OUT" =~ '/instances/' ]]; then
      local instarchpath
      instarchpath=$(echo "$OUT" | rev | cut -d"/" -f2- | rev)
      instarchpath="${instarchpath}/${CURRDATE}.html"
      mv "${OUT}" "${instarchpath}"
    else
      mv "${OUT}" "${CURRDATE}.html"
    fi
    xdatafile_checker
  fi
}

index_start() {
  echo "$HEADER" >> "$OUT"
  echo "$GTRANSFORM" >> "$OUT"
}

get_compnt_list() {
  apps="$COMPHEADER"
}

# Inject the visual Grid components and time headers
index_addcomp() {
  local xaxis=15
  local yaxis=20
  local xdata=350
  local ydata=5
  
  # Write component titles
  while read -r app; do
    if [ -n "$app" ]; then
      echo "$COMP" | sed "s/__COMP__/$app/g" | sed "s/xaxis/$xaxis/g" | sed "s/yaxis/$yaxis/g" >> "$OUT"
      yaxis=$((yaxis + 30))
    fi
  done <<< "$apps"

  # Write timeline hours
  local xtimloc=360
  local ytimloc=-10
  for hour in {00..23}; do
    echo "$CLOCK" | sed "s/hour/$hour/g" | sed "s/xtimloc/$xtimloc/g" | sed "s/ytimloc/$ytimloc/g" >> "$OUT"
    xtimloc=$((xtimloc + 60))
  done
}

index_addafterblack() {
  for xval in {1800..1850..30}; do
    echo "<rect width=\"20\" height=\"20\" fill=\"#0b0f19\" x=\"$xval\" y=\"0\" />" >> "$OUT"
  done
}

index_end() {
  echo "$CLOSEG" >> "$OUT"
  echo "$FOOTER" >> "$OUT"
}

# Core compiler routine
executor() {
  envar_setup
  env_check
  statfile_checker
  index_start
  read_config
  get_compnt_list
  index_addcomp
}

# Setup instances configuration maps
instmain_setup() {
  if ls config/*.insta >/dev/null 2>&1; then
    instacomp=$(ls config/*.insta | awk -F/ '{print $NF}' | sed 's/\.insta//g')
  else
    echo "Instance file doesn't exist"
    exit 0
  fi
  
  for i in $instacomp; do
    if [ ! -d "$i" ]; then
      mkdir -p "$i"
    fi
    ienfilevar_setup "$i"
    executor
  done
}

appmain_setup() {
  enfilevar_setup
  executor
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
elif [ $# -eq 0 ] ; then
  appmain_setup
  exit 0
else
  exit 0
fi

main "$EXEFOR"