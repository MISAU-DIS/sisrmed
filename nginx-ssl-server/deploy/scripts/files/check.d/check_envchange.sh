#!/bin/bash

ENV_FILE="/etc/mdns_add_alias/mdns_add_alias.env"
TMP_STATE="/tmp/mdns_env_file.size"

# Get current size (0 if missing)
current_size=$(stat -c %s "$ENV_FILE" 2>/dev/null || echo 0)

# Get last known size (or default to current to avoid triggering on first run)
if [[ -f "$TMP_STATE" ]]; then
  last_size=$(cat "$TMP_STATE")
else
  echo "$current_size" > "$TMP_STATE"
  exit 0
fi

# Compare
if [[ "$current_size" -ne "$last_size" ]]; then
  echo "[INFO] Detected change in $ENV_FILE (size changed: $last_size → $current_size)"
  echo "$current_size" > "$TMP_STATE"
  exit 1  # signal restart
fi

exit 0
