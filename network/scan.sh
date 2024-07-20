#/!bin/bash
# https://raspberrypi.stackexchange.com/questions/13936/find-raspberry-pi-address-on-local-network

ip neigh

#search arp table (local cache of hosts) (fast)
arp -na

#actively iterate all connection devices to find hosts (slow)
devices=$(nmcli device status |  tail -n +2 | cut -d" " -f1) 
IFS=$'\n' ;for device in $devices ; do 
  network=$(nmcli dev show $device | grep "GATEWAY" |  tr -s ' ' | cut -d" " -f2)
  IFS=$'\n' ;for mask in $network ; do 
    #todo fix ipv6 cider notation
    nmap -sA $mask/24
  done
done

echo "done"
