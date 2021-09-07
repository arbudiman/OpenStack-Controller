#!/bin/sh
source conf_color.sh
source conf_netCheck.sh
source conf_distro.sh

check=($nic)
if [ "$id_versi" = 18.04 ]
then
  check_ifup=$(dpkg -l | grep ifupdown | awk '{print $2; exit}')
  ifup=($check_ifup)
  if [[ -n ${ifup[@]} ]]
  then
    echo "${B}Paket Ifup sudah terinstall${R}"
    echo -e "\n"
  else
    echo "${B}Install Paket Ifup....${R}"
    apt update -y
    apt install ifupdown -y
    echo -e "\n"
  fi
  echo  "${B}Pilih Interface :${R}"
  select konfig in "Interface Manajemen" "Interface Provider" "Keluar"
  do
    case $konfig in
      "Interface Manajemen")
      while true
      do
        check_type_1=$(cat /etc/network/interfaces | awk '/inet static/ {print $4}')
        if [ "$check_type_1" = static ]
        then
          echo "${B}${r}Interface manajemen sudah dikonfigurasi${R}"
          echo "Pilih konfigurasi :"
          echo a | select konfig2 in "Interface Manajemen" "Interface Provider" "Keluar";do break;done
          break
        else
          while true
          do
            echo "${B}Pilih interface manajemen :${R}"
            select reply in "${check[@]}"
            do
              [ -n "${reply}" ] && break
            done
            echo "${B}Interface Manajemen yang dipilih: ${r}${reply}${R}"
            check_point_1=$(cat /etc/network/interfaces | awk '/iface '${reply}' inet manual/ {print $2}')
            if [ "$check_point_1" = ${reply} ]
            then
              echo "${B}${r}Interface ${reply} sudah digunakan interface provider${R}"
            else
              while :
              do
                while :
                do
                  read -r -p "${B}Masukan IP Address :${R} " ipm1
                  test='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
                  if [[ $ipm1 =~ ^$test\.$test\.$test\.$test$ ]]
                  then
                    break
                  else
                    echo "${B}${y}......... IP Address $ipm1 tidak valid .........${R}"
                    continue
                  fi
                done
                while :
                do
                  validate_netmask()
                  {
                    local netmask=$1
                    local netmask_binary
                    local octet
                    local stat
                    if [[ $netmask =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
                    then
                      stat=0
                      for ((i=0; i<4; i++))
                      do
                        octet=${netmask%%.*}
                        netmask=${netmask#*.}
                        [[ $octet -gt 255 ]] && { stat=1; break; }
                        netmask_binary=$netmask_binary$( echo "obase=2; $octet" | bc )
                        [[ $netmask_binary =~ 01 ]] && { stat=1; break; }
                      done
                    else
                      stat=1
                    fi
                    return $stat
                  }
                  read -r -p "${B}Masukan Netmask    :${R} " netmask1
                  if validate_netmask $netmask1
                  then
                    break
                  else
                    echo "${B}${y}............ Subnet $netmask1 tidak valid .......${R}"
                    continue
                  fi
                done
                IFS=. read -r i1 i2 i3 i4 <<< "$ipm1"
                IFS=. read -r m1 m2 m3 m4 <<< "$netmask1"
                net="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))"
                net2="$((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$((i4 & m4 | 255-m4))"
                ip1="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$(((i4 & m4)+1))"
                ipn="$((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$(((i4 & m4 | 255-m4)-1))"
                if [ "$ipm1" == "$net" ]
                then
                  echo "$......... {B}${y}IP Address $ipm1 yang anda masukan alamat network .......${R}"
                  continue
                else
                  break
                fi
              done
              while :
              do
                read -r -p "${B}Masukan Gateway :${R} " gw
                test='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
                if [[ $gw =~ ^$test\.$test\.$test\.$test$ ]]
                then
                  break
                else
                  echo "${B}${y}......... Format Gateway $gw tidak valid .........${R}"
                  continue
                fi
              done
              while :
              do
                read -r -p "${B}DNS Nameservers :${R} " dns
                test='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
                if [[ $dns =~ ^$test\.$test\.$test\.$test$ ]]
                then
                  break
                else
                  echo "${B}${y}......... Format DNS Nameserver $dns tidak valid .........${R}"
                  continue
                fi
              done
              #read -r -p "${B}Masukan Gateway    :${R} " gw
              #read -r -p "${B}Masukan Nameserver :${R} " dns
              check_eth=$(cat /etc/network/interfaces | awk '/iface '${reply}'/ {print $2}')
              if [ "$check_eth" = ${reply} ]
              then
                sed -i 's/allow-hotplug .*/allow-hotplug '${reply}'/' /etc/network/interfaces
                sed -i 's/auto .*/auto '${reply}'/' /etc/network/interfaces
                sed -i 's/iface .*/iface '${reply}' inet static/' /etc/network/interfaces
                sed -i 's/address .*/address  '$ipm1'/' /etc/network/interfaces
                sed -i 's/netmask .*/netmask  '$netmask1'/' /etc/network/interfaces
                sed -i 's/gateway .*/\#gateway  '$gw'/' /etc/network/interfaces
                sed -i 's/dns-nameservers .*/\#dns-nameservers  '$dns'/' /etc/network/interfaces
                echo -e "\n" >> /etc/network/interfaces
              else
                #truncate -s 0 /etc/network/interfaces.asli
                #echo >> /etc/network/interfaces.asli
                #sed -i '6i\allow-hotplug '${reply}'' /etc/network/interfaces
                #sed -i '7i\auto '${reply}'' /etc/network/interfaces
                #sed -i '8i\iface '${reply}' inet static' /etc/network/interfaces
                #sed -i '9i\ address         '$ipm1'' /etc/network/interfaces
                #sed -i '10i\ netmask        '$netmask1'' /etc/network/interfaces
                #sed -i '11i\ gateway        '$gw'' /etc/network/interfaces
                #sed -i '12i\ dns-nameservers '$dns'' /etc/network/interfaces

                sed -i '6i\ \#dns-nameservers '$dns' \n' /etc/network/interfaces
                sed -i '6i\ \#gateway        '$gw'' /etc/network/interfaces
                sed -i '6i\ netmask        '$netmask1'' /etc/network/interfaces
                sed -i '6i\ address         '$ipm1'' /etc/network/interfaces
                sed -i '6i\iface '${reply}' inet static' /etc/network/interfaces
                sed -i '6i\auto '${reply}'' /etc/network/interfaces
                sed -i '6i\allow-hotplug '${reply}'' /etc/network/interfaces
                #echo allow-hotplug ${reply} >> /etc/network/interfaces
                #echo auto ${reply}  >> /etc/network/interfaces
                #echo iface ${reply} inet static >> /etc/network/interfaces
                #echo " address"         $ipm1 >> /etc/network/interfaces
                #echo " netmask"         $netmask1 >> /etc/network/interfaces
                #echo " gateway"         $gw >> /etc/network/interfaces
                #echo " dns-nameservers" $dns >> /etc/network/interfaces
              fi
              ip addr flush dev ${reply}
              ifdown --force ${reply} && ifup -a
              echo ""
              echo "${B}${I}Konfigurasi Interface Manajemen${R}"
              echo "${B}${r}Nama Kartu Jaringan  :${R} ${reply}"
              echo "${B}${r}IP Address Manajemen :${R} $ipm1"
              echo "${B}${r}netmask              :${R} $netmask1"
              echo "${B}${r}Gateway              :${R} $gw"
              echo "${B}${r}DNS Nameserver       :${R} $dns"
              echo "${B}${r}Network ID           :${R} $net"
              echo "${B}${r}Broadcast ID         :${R} $net2"
              break
              #echo "Konfigurasi lainnya?"
              #echo a | select konfig2 in "Interface Manajemen" "Interface Provider" "Keluar";do break;done
            fi
            echo "${B}${b}Konfigurasi Interface Provider${R}"
            echo a | select konfig2 in "Interface Manajemen" "Interface Provider" "Keluar";do break;done
            #break
          done
          #break
        fi
      done
      ;;
      "Interface Provider")
      #while true
      #do
        check_type_2=$(cat /etc/network/interfaces | awk '/inet manual/ {print $4}')
        if [ "$check_type_2" = manual ]
        then
          echo "${B}${r}Interface provider sudah dikonfigurasi${R}"
          #echo "${B}Pilih konfigurasi :${R}"
          #echo a | select konfig2 in "Interface Manajemen" "Interface Provider" "Keluar";do break;done
          #break
        else
          echo "${B}Konfigurasi Interface Provider${R}"
          while true
          do
            echo "${B}Pilih interface provider :${R}"
            select reply in "${check[@]}"
            do
              [ -n "${reply}" ] && break
            done
            echo "${B}Interface Provider yang dipilih: ${r}${reply}${R}"
            check_point_2=$(cat /etc/network/interfaces | awk '/iface '${reply}' inet static/ {print $2}')
            if [ "$check_point_2" = ${reply} ]
            then
              echo "${B}Interface ${reply} sudah digunakan interface manajemen${R}"
              #select reply2 in "${check[@]}";do break;done
              #break
            else
              check_eth_1=$(cat /etc/network/interfaces | awk '/iface '${reply}'/ {print $2}')
              echo "Test ${reply} -->  $check_eth_1"
              if [ "$check_eth_1" = ${reply} ]
              then
                sed -i 's/allow-hotplug .*/allow-hotplug '${reply}'/' /etc/network/interfaces
                sed -i 's/auto .*/auto '${reply}'/' /etc/network/interfaces
                sed -i 's/iface .*/iface '${reply}' inet manual/' /etc/network/interfaces
              else
                #truncate -s 0 /etc/network/interfaces.asli
                #sed -i '14i\allow-hotplug '${reply}'' /etc/network/interfaces
                #sed -i '15i\auto '${reply}' /etc/network/interfaces
                sed -i '14i\iface '${reply}' inet manual' /etc/network/interfaces
                sed -i '14i\auto '${reply}'' /etc/network/interfaces
                sed -i '14i\allow-hotplug '${reply}'' /etc/network/interfaces
                #echo -e "\n" >> /etc/network/interfaces
                #echo "" >> /etc/network/interfaces
                #echo allow-hotplug ${reply} >> /etc/network/interfaces
                #echo auto ${reply} >> /etc/network/interfaces
                #echo iface ${reply} inet manual >> /etc/network/interfaces
              fi
              sed -i '17i\ down ip link set dev \$IFACE down \n' /etc/network/interfaces
              sed -i '17i\ up ip link set dev \$IFACE up' /etc/network/interfaces
              #sed -i '18i\ down ip link set dev \$IFACE down' /etc/network/interfaces
              ip addr flush dev ${reply}
              ifdown --force ${reply} && ifup -a
              #systemctl unmask networking
              #systemctl enable networking
              #systemctl restart networking
              #systemctl stop systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
              #systemctl disable systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
              #systemctl mask systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
              #apt-get --assume-yes purge nplan netplan.io
              break
              echo -e "\n"
              echo "${B}Konfigurasi Interface Manajemen dan Interface Provider :${R}"
              cek_conf=$(cat /etc/network/interfaces)
              echo "${B}${r}$cek_conf${R}"
              echo -e "\n"
            fi
            #break
          done
        fi
        #break
      #done
      break 2
      ;;
      "Keluar")
      break 2
      ;;
      *)
      echo "Opsi Pilihan 1-3...."
      ;;
    esac
  done
else
  echo "Ubuntu 16.04"
  echo -e "\n"
  echo "${B}Konfigurasi Interface Manajemen dan Interface Provider :${R}"
  cek_conf=$(cat /etc/network/interfaces)
  echo "${B}${r}$cek_conf${R}"
  echo -e "\n"
fi
