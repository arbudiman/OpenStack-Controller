#!/bin/sh
source conf_color.sh
source conf_netCheck.sh
source conf_distro.sh
source conf_package.sh
source conf_cdr.sh
source conf_ipc.sh
while true
do
  echo  "${B}Instalasi Service Openstack :${R}"
  select opsi in "Keystone" "Glance" "Compute" "Neutron" "Storage" "Dashboard" "Keluar"
  do
    case $opsi in
      "Keystone")
      source keystone.sh
      break
      ;;
      "Glance")
      source glance.sh
      break
      ;;
      "Compute")
      source nova.sh
      break
      ;;
      "Neutron")
      source neutron.sh
      break
      ;;
      "Storage")
      source cinder.sh
      break
      ;;
      "Dashboard")
      source dashboard.sh
      break
      ;;
      "Keluar")
      break 3
      ;;
      *)
      echo "Opsi Pilihan 1-6...."
      ;;
    esac
  done
done
