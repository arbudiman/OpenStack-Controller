#!/bin/sh
echo "${B}${r}############################ Konfigurasi Host Controller dan Host Compute ##########################${R}"
check_hosts=$(hostnamectl | grep hostname | awk '{print $3}')
check_ip=$(cat /etc/network/interfaces | awk '/address / {print $2}')
echo "${B}${r}Host Controller :${R} $check_ip   $check_hosts"
truncate -s 0 /etc/hosts
echo >> /etc/hosts
echo "$check_ip     $check_hosts"  >> /etc/hosts
echo
echo "${B}${r}Konfigurasi Host Compute :${R}"
read -r -p "${B}Masukan Jumlah Node :${R} " angka
if ! [[ "$angka" =~ ^[0-9]+$ ]]
then
  echo "${B}Masukkan Jumlah Node Compute dalam angka....${R} "
else
  i=1
  while [ "$i" -le "$angka" ]
  do
    #echo "$i"
    number=$(($i+0))
    read -r -p "${B}Masukan Nama Node $number${R} : " node
    while :
    do
      read -r -p "${B}Masukan Alamat IP Node :${R} " compute
      test='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
      if [[ $compute =~ ^$test\.$test\.$test\.$test$ ]]
      then
        break
      else
        echo "${B}${y}......... Format alamat $compute tidak valid .........${R}"
        continue
      fi
    done
    echo "$compute         $node" >> /etc/hosts
    i=$(($i+1))
  done
fi
cat /etc/hosts
break
