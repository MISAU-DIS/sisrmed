#!/bin/bash
mdns_conf_dir="/etc/mdns_add_alias"
env_file="$mdns_conf_dir""/mdns_add_alias.env"
base_dir=$(dirname "$0")
#----------------------------------------------------------------------------
update_dns_env() {
  echo
  if [ ! -d "$mdns_conf_dir" ]; then
    mkdir $mdns_conf_dir
  fi
  echo "hosts=($@)" > "$env_file"
  echo "Updated $env_file with hosts: $@"
  # Set scripts permissions
}
#----------------------------------------------------------------------------
print_help() {
  echo
  echo "Please specify:"
  echo
  echo "$0 --install               Install avahi-daemon, avahi-utils and mDNS-alias"
  echo
  echo "$0 --update|--publish      <service_name1> <service_name2> <service_nameN>"
  echo "                           installs mDNS service, and add the specified service_names"
  echo "                           to the publish registry."
  echo               
  echo "                           e.g. $0 --publish sesp idmed"
  echo               
  echo "                           e.g. $0 --update sesp idmed"
  echo "$0 --test                  to ping <serviceN>.local"
  echo
  exit
}
#----------------------------------------------------------------------------
prompt_for_confirmation() {
  read -p "Please enter (Y/y) to confirm: " confirm
  if [[ $confirm =~ ^[yY]$ ]]; then
    return 0
  else
    return 1
  fi
}
#----------------------------------------------------------------------------
check_packages() {
  if [ `dpkg -l |grep -E 'avahi-daemon|avahi-utils' |wc -l` -lt 2 ]
  then
    echo
    echo "Installing avahi-daemon, avahi-utils and mdns_add_alias.service ......."
    echo
    sleep 1
    sudo apt-get install avahi-daemon avahi-utils -y
    echo
  fi
  echo "Installing mdns_add_alias.service"
  if [ ! -d "$mdns_conf_dir" ]; then
    mkdir $mdns_conf_dir
  fi
  sudo cp "$base_dir"/scripts/files/mdns_add_alias.service /etc/systemd/system/
  sudo cp "$base_dir"/scripts/mdns_add_alias.sh "$mdns_conf_dir"
  sudo cp -rp "$base_dir"/scripts/files/check.d "$mdns_conf_dir"
  sudo chmod -R 0755 "$mdns_conf_dir/check.d"
  sudo chmod 0755 "$mdns_conf_dir/mdns_add_alias.sh"
  sudo chmod 0744 "$mdns_conf_dir/mdns_add_alias.env"
  sudo chown -R root:root "$mdns_conf_dir"
}
#----------------------------------------------------------------------------
install_mdns() {
  # Check if ports are open
  if ping -c 1 "www.google.com" &> /dev/null; then
      echo "Internet access OK."
  else
      echo "NO Internet access, please check your connectivity."
      exit
  fi
  abort=0
  for port in 80 443
  do
    if nc -zv localhost $port 2>&1 | grep -q 'succeeded'; then
        echo "Port $port is already in use."
        ((abort+=1))
    else
        echo "Port $port is available."
    fi
  done

  if [ "$abort" -gt 0 ]
  then
    echo "Please make sure port 80 and 443 are available."
    sudo apt-get install net-tools -y 2&1>/dev/null
    exit
  fi

  if [ `sudo ufw status |grep ": active" |wc -l ` -le 0 ];  then
    echo "firewall NOT enabled, it's not mandatory but recomended that you enable the firewall."
  else      
    abort=0
    echo "Firewall enabled, checking if ports 80 and 443 are open....."
    for i in 80 443
    do
      if [ `sudo ufw status |grep "^$i\/tcp" |wc -l` -gt 0 ]; then
        echo "  -  Port $i     OPEN"
      else
        echo "  -  Port $i     CLOSE"
        ((abort+=1))
      fi
    done
  fi
  echo
  if [ "$abort"  -gt 0 ]
  then
    echo "Firewall ports 80 and/or 443 are not open please open using."
    echo
    echo "sudo ufw allow 80/tcp"
    echo "sudo ufw allow 443/tcp"
    echo
    exit
  fi

  check_packages

  echo "Restart/Reloading Systemd daemon"
  sudo systemctl daemon-reload
  echo

  for i in avahi-daemon mdns_add_alias
  do
    echo -n "Enabling and starting $i.service... "
    sudo systemctl enable $i.service
    sudo systemctl restart $i.service
  done
  echo
  echo "Completed!"
  echo
}
#----------------------------------------------------------------------------
test_ping() {
  if [ -f "$env_file" ]; then
    source "$env_file"
  else
    echo "File $env_file not found."
    exit 1
  fi
  for host in "${hosts[@]}"; do
    echo -n "  Pinging $host.local ......"
    if ping -c 1 "$host.local" &> /dev/null; then
        echo "OK."
    else
        echo "FAILED!"
    fi
    sleep 1
  done
  echo
  if [ "$1" != "--test" ]
  then
    echo "Use $0 --test to repeat ping test only."
    echo
  fi
}
#----------------------------------------------------------------------------
### MAIN EXECUTION
#----------------------------------------------------------------------------
if [ "$1" == "--install" ]
then
  if [ `id -u` -ne 0 ]
    then echo Please run this script as root or using sudo!
    exit
  fi
  install_mdns
  exit
fi
if [ "$1" == "--test" ]
then
  test_ping
fi
if [ "$1" == "--update" ] || [ "$1" == "--publish" ]
then
  if [ `id -u` -ne 0 ]
    then echo Please run this script as root or using sudo!
    exit
  fi
  shift
  if [ "$#" -lt 1 ]; then
    echo "No hosts provided. Usage: $0 $1 service1 service2 serviceN..."
    exit 1
  fi
  if [ -f "$env_file" ]; then
    echo
    echo "File $env_file, already contains records" 
    cat $env_file |cut -d "(" -f2|cut -d ")" -f1
    echo
    echo "Do you want to replace with: $@"

    if prompt_for_confirmation; then
      update_dns_env "$@"
    else
      echo "Update cancelled."
      exit 0
    fi
  else
    update_dns_env "$@"
  fi
  delay_before_test=10
  echo
  echo -n "Going to ping new hosts... "
  while [ "$delay_before_test" -gt 0 ]
  do
    echo -n $delay_before_test" "
    delay_before_test=$((delay_before_test - 1))
    sleep 1
  done
  echo
  test_ping
fi
if [ "$1" == "" ] || [ "$1" == "--help" ]
then
  print_help
fi
exit
