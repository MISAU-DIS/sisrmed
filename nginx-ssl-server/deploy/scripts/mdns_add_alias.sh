#!/bin/bash

LOCKFILE="/var/run/mdns_add_alias.lock"
ENV_FILE="/etc/mdns_add_alias/mdns_add_alias.env"
CHECK_DIR="/etc/mdns_add_alias/check.d"
TMP_STATE="/tmp/mdns_env_file.size"
RECHECK_INTERVAL=10

# --- PID-based lockfile with stale lock detection ---
if [ -f "$LOCKFILE" ]; then
  old_pid=$(<"$LOCKFILE")
  if ! ps -p "$old_pid" > /dev/null 2>&1; then
    echo "[WARN] Stale lock found with PID $old_pid. Removing lockfile."
    rm -f "$LOCKFILE"
  else
    echo "[ERROR] Another instance is already running with PID $old_pid."
    exit 1
  fi
fi

# Create lockfile with current PID
echo $$ > "$LOCKFILE"

# Ensure lockfile is removed on exit
trap 'rm -f "$LOCKFILE"' EXIT

echo "[INFO] mdns_add_alias started."

# --- Initial alias publishing ---
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
  current_published=$(ps -ef | grep '[a]vahi-publish' | awk '{print $NF}' | sed 's/.local//')

  for published in $current_published; do
    if [[ ! " ${hosts[@]} " =~ " ${published} " ]]; then
      echo "[INFO] Removing stale alias: $published"
      pkill -f "avahi-publish -a -R $published.local"
    fi
  done

  for host in "${hosts[@]}"; do
    if ! pgrep -f "avahi-publish -a -R $host.local" > /dev/null; then
      ip_addr=$(ip route get 1.1.1.1 | awk '{print $7}')
      echo "[INFO] Publishing alias: $host.local -> $ip_addr"
      /usr/bin/avahi-publish -a -R "$host.local" "$ip_addr" &
    fi
  done
else
  echo "[WARN] Alias environment file not found: $ENV_FILE"
fi

# --- Main health check loop ---
env_size=$(stat -c %s "$ENV_FILE" 2>/dev/null || echo 0)
echo "$env_size" > "$TMP_STATE"

while true; do
  for check in "$CHECK_DIR"/*; do
    if [[ -x "$check" && ! -d "$check" ]]; then
      "$check"
      status=$?
      if [[ $status -ne 0 ]]; then
        echo "[ERROR] Check '$check' failed with code $status. Restarting service..."
        systemctl restart mdns_add_alias.service
        exit 0
      fi
    fi
  done
  sleep "$RECHECK_INTERVAL"
done
