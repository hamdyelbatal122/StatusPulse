#!/usr/bin/env bash
# ==============================================================================
# StatusPulse - Multi-Tenant Instance Directory Setup
# Configures and bootstraps directories for granular instance-level monitoring.
# ==============================================================================

set -euo pipefail

# Helper function to check if a directory path string is empty
check_folder_empty() {
  local dir="${1:-}"
  if [[ -z "$dir" ]]; then
    return 0 # True/Success
  else
    return 1 # False/Failure
  fi
}

# Poll for app.conf & extract list of applications
read_conf() {
  if [ -f "app.conf" ]; then
    apps=$(awk -F'/' '{print $1}' app.conf)
  elif [ -f "config/app.conf" ]; then
    apps=$(awk -F'/' '{print $1}' config/app.conf)
  else
    echo "Warning: app.conf file not found. Skipping config read."
    apps=""
  fi
}

# Create appropriate subdirectory scopes and copy bootstrapper executors
create_dir() {
  for app in $apps; do
    if [[ -z "$app" ]]; then
      continue
    fi

    # Create subdirectory if not already existing
    if [ ! -d "$app" ]; then
      echo "Creating directory: $app"
      mkdir -p "$app"
    fi

    # Check for direct monitoring url config map
    if [ ! -f "${app}/url_file" ]; then
      echo "Initializing bootstrap template scripts in $app"
      if [ -f "direct_mon.sh" ]; then
        cp "direct_mon.sh" "${app}/start_${app}.sh"
        chmod +x "${app}/start_${app}.sh"
      else
        # Safe dummy script fallback
        echo "#!/bin/bash" > "${app}/start_${app}.sh"
        echo "echo 'Initializing status audit loop for ${app}'" >> "${app}/start_${app}.sh"
        chmod +x "${app}/start_${app}.sh"
      fi
    fi
  done
}

# Copy executors and generate child instances assets mapping
copy_executor() {
  for app in $apps; do
    if [[ -z "$app" ]]; then
      continue
    fi
    
    if [ ! -f "${app}/url_file_${app}" ]; then
      echo "Configuring asset mapping tables inside: $app"
      mkdir -p "${app}/config"
      touch "${app}/url_file_${app}"
    fi
  done
}

main() {
  echo "--> Bootstrapping StatusPulse Directory Structure..."
  read_conf
  if [ -n "$apps" ]; then
    create_dir
    copy_executor
    echo "--> System bootstrapped successfully."
  else
    echo "--> No app configurations detected. Skipping initialization."
  fi
}

cd "$(dirname "$0")"
main
