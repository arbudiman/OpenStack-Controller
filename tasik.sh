#!/bin/bash
locale-gen "en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
source conf_color.sh
echo ${B}${y}
echo "##############################################################################################################"
echo "# ---------------------------------------- Installer Openstack V.1.0 ----------------------------------------#"
echo "#                                          Created By arbudiman0504                                          #"
echo "#                                          Diskominfo Kota Tasikmalaya                                       #"
echo "#                                          Code Purbaratu 21.06                                              #"
echo "##############################################################################################################"
echo ${R}
echo "${B}# Installer Openstack ini bebas digunakan sebagai bahan pembelajaran Cloud Private"
echo "# installer Openstack versi pertama hanya dapat digunakan untuk Ubuntu 16.04 dan Ubuntu 18.04"
echo "# Installer Openstack ini dapat digunakan di real mesin, VMWare dan Virtual Box"
echo "# Installer Openstack ini dapat didistribusikan, dimodifikasi secara bebas dengan memperhatikan aturan GNU"
echo "# Installer Openstack ini bersifat Opensource"
echo ${R}
echo "${B}${r}############################### CEK VERSI UBUNTU DAN INFORMASI CPU  #################################${R}"
source conf_bar.sh
source conf_distro.sh
echo
echo "${B}${b}1. Versi Ubuntu Anda saat ini :${R}"
echo "   ${B}Distro          :${R} $distro"
echo "   ${B}Versi           :${R} $versi"
echo "   ${B}Versi ID        :${R} $id_versi"
echo "2. ${B}${b}Informasi CPU :${R}"
echo "   ${B}Vendor          :${R} $vendor"
echo "   ${B}Model           :${R} $model_name"
echo "   ${B}Jumlah CPU      :${R} $jml_prosesor"
echo "   ${B}Jumlah Core     :${R} $virt core"
echo
echo "${B}${r}###################################### CEK KONFIGURASI JARINGAN ####################################${R}"
source conf_bar.sh
echo
echo "${B}${b}Hasil pengecekan :${R}"
source conf_netCheck.sh
declare -a AR=($check)
jml=0
for i in "${!AR[@]}"; do
  name="eth$i"
  eth="${AR[i]}"
  jml=$(expr $jml + 1)
  netConf=$(awk -v par="$eth" '/^iface/ && $2==par {f=1} /^iface/ && $2!=par {f=0} f {print $2; f=0}' /etc/network/interfaces)
  if [ -n "$netConf" ]
  then
   ip4=$(awk -v par="$eth" '/^iface/ && $2==par {f=1} /^iface/ && $2!=par {f=0} f && /^\s*address/ {print $2; f=0}' /etc/network/interfaces)
   net=$(awk -v par="$eth" '/^iface/ && $2==par {f=1} /^iface/ && $2!=par {f=0} f && /^\s*netmask/ {print $2; f=0}' /etc/network/interfaces)
   echo " Interface ${B}${r}$eth${R} sudah di konfigurasi | IP Address : ${B}${r}$ip4${R} | Netmask : ${B}${r}$net${R}"
  else
   echo " Interface ${B}${r}$eth${R} belum di konfigurasi"
  fi
done
echo
echo "${B}${r}######################################### Cek Koneksi Internet ########################################${R}"
if ping -q -c 1 -W 1 google.com >/dev/null
then
  echo "${B}${b}Koneksi internet ok....${R}"
  while true
  do
    echo "${B}${U}${b}[ Menu Instalasi Openstack ]${R}"
    select menu in "Konfigurasi Jaringan" "Konfigurasi Hostname" "Konfigurasi Host" "Konfigurasi Environment Openstack" "Konfigurasi Service Openstack" "Keluar"
    do
      case $menu in
        "Konfigurasi Jaringan")
        clear
        echo "${B}${r}######################################### KONFIGURASI JARINGAN ########################################${R}"
        source conf_net_1.sh
        break 2
        ;;
        "Konfigurasi Hostname")
        clear
        echo "${B}${r}######################################### KONFIGURASI HOSTNAME ########################################${R}"
        source conf_hostname.sh
        break 2
        ;;
        "Konfigurasi Host")
        clear
        echo "${B}${r}########################## KONFIGURASI HOST CONTROLLER DAN HOST COMPUTE ###############################${R}"
        source conf_hosts.sh
        break 2
        ;;
        "Konfigurasi Environment Openstack")
        clear
        echo "${B}${r}################################ KONFIGURASI OPENSTACK ENVIRONMENT ####################################${R}"
        source env_basic.sh
        break 2
        ;;
        "Konfigurasi Service Openstack")
        clear
        echo "${B}${r}################################### KONFIGURASI SERVICE OPENSTACK #####################################${R}"
        source service.sh
        break 2
        ;;
        "Keluar")
        break 2
        ;;
        *)
        echo "Pilih 1-6..."
        ;;
      esac
    done
    #break
  done
else
  echo "Tidak ada koneksi internet... Periksa konfigurasi jaringan anda..."
  source conf_net.sh
fi
echo "${B}Terima Kasih Sudah Menggunakan Installer Openstack Diskominfo Kota Tasikmalaya..... ${R}"
