#!/bin/bash
env_file="/etc/mdns_add_alias/mdns_add_alias.env"
failed_pings=0
if [[ ! -f "$env_file" ]]; then
  echo "[WARN] Config file not found: $env_file"
else
  source "$env_file"
  for host in "${hosts[@]}"; do
    if ! ping -c 1 -W 2 "$host.local" &> /dev/null; then
      ((failed_pings++))
    fi
  done
fi
if [ $failed_pings -gt 0 ]; then
   exit 1
else
  exit 0
fi
