#!/bin/sh
source conf_color.sh
source conf_distro.sh
echo "${B}${r}######################################  Konfigurasi Zona Waktu  ####################################${R}"
timedatectl set-timezone Asia/Jakarta
time=$(timedatectl)
echo "${B}${b}$time${R}"
echo
echo "${B}${r}######################################   Konfigurasi Hostname   ####################################${R}"
if [ "$id_versi" = 18.04 ]
then
  check_hn=$(hostnamectl)
  check_hostname=$(cat /etc/cloud/cloud.cfg | grep preserve_hostname | awk '{print $2}')
  #echo $check_hostname
  if [ "$check_hostname" = false ]
  then
    sed -i '/preserve_hostname/ s/false/true/' /etc/cloud/cloud.cfg
    echo "${B}$check_hn${R}"
    read -r -p "Masukkan nama Hostname :" hn
    hostnamectl set-hostname $hn
  else
    echo "${B}$check_hn${R}"
    read -r -p "Masukkan nama Hostname :" hn
    hostnamectl set-hostname $hn
  fi
else
  echo "Ubuntu 16.04"
fi
echo
break
