#!/bin/sh
source conf_color.sh
source conf_netCheck.sh
source conf_distro.sh
source conf_package.sh
source conf_cdr.sh
source conf_ipc.sh
chrony=($check_chrony)
soft=($check_software)
repository=($check_repository)
lib_openstack=($check_library)
mariadb=($check_mariadb)
pymysql=($check_pymysql)
rabbitmq=($check_rabbitmq)
memcached=($check_memcached)
memcache=($check_memcache)
etcd=($check_etcd)
pack=($check_packet)
#echo -e "\n"
while true
do
  echo  "${B}Instalasi Environment Openstack :${R}"
  select konfig in "Chrony" "Repository Openstack" "Openstack Client" "Basic Environment" "Keluar"
  do
    case $konfig in
      "Chrony")
      echo "${B}Cek Paket Chrony${R}"
      if [[ -n ${chrony[@]} ]]
      then
        echo "${B}${r}Paket Chrony sudah terinstall${R}"
        echo "...Uninstall paket Chrony..."
        echo
        apt remove --purge ${chrony[@]} -y
      fi
      echo
      echo "${B}Paket Chrony belum terinstall${R}"
      echo "...Install  paket Chrony..."
      apt install chrony -y
      cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.ori
      sed -i -e 's/^pool/#&/' /etc/chrony/chrony.conf #menambahkan teks
      cek2=$(cat /etc/chrony/chrony.conf | grep pool | awk '/^#pool/{ print $1 $2 }')
      ln=$(awk '/^#pool/{ print NR; exit }' /etc/chrony/chrony.conf) #line number dgn teks tertentu
      sed -i -e ''$ln' i\server 1.id.pool.ntp.org iburst' /etc/chrony/chrony.conf
      sed -i -e ''$ln' i\server 0.id.pool.ntp.org iburst' /etc/chrony/chrony.conf
      ln2=$(awk '/^keyfile/{ print NR; exit }' /etc/chrony/chrony.conf)
      allow="$net/$pref"
      sed -i -e ''$ln2' i\allow '$allow'' /etc/chrony/chrony.conf
      systemctl restart chrony
      systemctl enable chrony
      systemctl start chrony
      chronyc sources
      break
      ;;
      "Repository Openstack")
      echo "${B}Cek Software-Common-Properties${R}"
      if [[ -n ${soft[@]} ]]
      then
        echo "${B}${r}Software-Properties-Common sudah di install...${R} "
        apt purge --auto-remove ${soft[@]} -y
      fi
      echo "${B}${b}Re-install Software Properties Common...${R}"
      apt install software-properties-common -y
      echo
      apt update -y
      echo "Menambahkan Repository Openstack"
      if [[ "$id_versi" = 18.04 ]]
      then
        echo "${B}Cek Repository Openstack${R}"
        if [[ -n ${repository[@]} ]]
        then
          echo "${B}${r}Repository Openstack sudah ada...${R} "
          echo "...Hapus Repository Openstack..."
          echo
          rm -f /etc/apt/sources.list.d/cloudarchive*
          apt remove --purge ubuntu-cloud-keyring -y
          echo
        fi
        select repo in "Rocky" "Stein" "Train" "Keluar"
        do
          case $repo in
            "Rocky")
            echo "${B}Menambahkan Repository Openstack Rocky${R}"
            add-apt-repository cloud-archive:rocky
            echo
            break
            ;;
            "Stein")
            echo "${B}Menambahkan Repository Openstack Stein${R}"
            add-apt-repository cloud-archive:stein
            echo
            break
            ;;
            "Train")
            echo "${B}Menambahkan Repository Openstack Train${R}"
            add-apt-repository cloud-archive:train
            echo
            break
            ;;
            "Keluar")
            break 2
            ;;
            *)
            echo "Pilih 1-4..."
            ;;
          esac
        done
      else
        echo
        echo "${B}Menambahkan Repository Openstack Queens${R}"
        add-apt-repository cloud-archive:queens
      fi
      echo "${B}Update System...${R}"
      apt update && apt dist-upgrade -y
      echo
      break
      ;;
      "Openstack Client")
      echo "${B}Install Library Openstack Client${R}"
      if [[ "$id_versi" = 18.04 ]]
      then
        echo "${B}Cek Library Openstack${R}"
        if [[ -n ${lib_openstack[@]} ]]
        then
          echo "${B}${r}Library Openstack sudah terinstall${R}"
          echo "...Uninstall Library Openstack..."
          echo
          apt purge --auto-remove ${lib_openstack[@]} -y
        fi
        echo
        echo "Pilih Library Openstack Client"
        if [[ "${pack[@]}" = rocky ]]
        then
          echo "Install Library Openstack ${pack[@]}"
          apt install python3-openstackclient -y
          echo
          break
        elif [[ "${pack[@]}" = stein ]]
        then
          echo "Install Library Openstack Stein ${pack[@]}"
          apt install python3-openstackclient -y
          echo
        else
          echo "Install Library Openstack ${pack[@]}"
          apt install python3-openstackclient -y
          echo
          break
        fi
      else
        echo
        echo "Install Library Openstack Queens"
        apt install python3-openstackclient -y
      fi
      break
      ;;
      "Basic Environment")
      while true
      do
        echo
        echo "Install Basic Environment"
        select envi in "Mariadb" "Rabbitmq-Server" "Memcached" "ETCD" "Keluar"
        do
          case $envi in
            "Mariadb")
            echo "${B}Cek Paket Mariadb, Python-PyMySql${R}"
            if [[ -n ${mariadb[@]} ]]
            then
              echo "${B}${r}Paket Maridb sudah terinstall${R}"
              echo "...Uninstall paket Mariadb..."
              echo
              apt remove --purge ${mariadb[@]} -y
            fi
            echo
            if [[ -n ${pymysql[@]} ]]
            then
              echo "${B}${r}Paket Python-PyMySQL sudah terinstall${R}"
              echo "...Uninstall paket Python-PyMySQL..."
              echo
              apt remove --purge ${pymysql[@]} -y
            fi
            echo
            echo "${B}Install Mariadb Server, Python-PyMySQL${R}"
            apt install mariadb-server python-pymysql -y
            echo "Konfigurasi Mariadb..."
            echo > /etc/mysql/mariadb.conf.d/99-openstack.cnf
            echo "[mysqld]" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
            echo "bind-address = $ipcontroller" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
            echo >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
            echo "default-storage-engine = innodb" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
            echo "innodb_file_per_table = on" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
            echo "max_connections = 4096" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
            echo "collation-server = utf8_general_ci" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
            echo "character-set-server = utf8" >> /etc/mysql/mariadb.conf.d/99-openstack.cnf
            systemctl restart mysql
            mysql_secure_installation
            break
            ;;
            "Rabbitmq-Server")
            echo "${B}Cek Paket Rabbitmq-Server ${R}"
            if [[ -n ${rabbitmq[@]} ]]
            then
              echo "${B}${r}Rabbitmq-Server sudah terinstall${R}"
              echo "...Uninstall Rabbitmq-Server..."
              echo
              apt remove --purge ${rabbitmq[@]} -y
            fi
            echo
            echo "${B}Install Rabbitmq-Server${R}"
            apt install rabbitmq-server -y
            read -r -p "Masukkan Password Rabbitmq-Server : " pass
            echo "export rabPWD=$pass" > conf_file.sh
            rabbitmqctl add_user openstack $pass
            rabbitmqctl set_permissions openstack ".*" ".*" ".*"
            break
            ;;
            "Memcached")
            echo "${B}Cek Paket Memcached${R}"
            if [[ -n ${memcached[@]} ]]
            then
              echo "${B}${r}Paket Memcached sudah terinstall${R}"
              echo "...Uninstall Paket Memcached..."
              echo
              apt remove --purge ${memcached[@]} -y
            fi
            echo
            echo "${B}Install Paket Memcached${R}"
            apt install memcached python-memcache -y
            cp /etc/memcached.conf /etc/memcached.conf.ori
            sed -i -e 's/^-l/#&/' /etc/memcached.conf #menambahkan teks
            sln=$(awk '/^#-l/{ print NR; exit }' /etc/memcached.conf) #line number dgn teks tertentu
            sed -i -e ''$sln' i\-l '$ipcontroller'' /etc/memcached.conf
            systemctl restart memcached
            break
            ;;
            "ETCD")
            echo "${B}Cek Paket ETCD${R}"
            if [[ -n ${etcd[@]} ]]
            then
              echo "${B}${r}Paket ETCD sudah terinstall${R}"
              echo "...Uninstall Paket ETCD..."
              echo
              apt remove --purge ${etcd[@]} -y
            fi
            echo
            echo "${B}Install Paket ETCD${R}"
            apt install etcd -y
            hsn=$(hostnamectl | awk '/Static / {print $3; exit}')
            cp /etc/default/etcd /etc/default/etcd.ori
            echo > /etc/default/etcd
            echo "ETCD_NAME=\"$hsn\"" >> /etc/default/etcd
            echo "ETCD_DATA_DIR=\"/var/lib/etcd\"" >> /etc/default/etcd
            echo "ETCD_INITIAL_CLUSTER_STATE=\"new\"" >> /etc/default/etcd
            echo "ETCD_INITIAL_CLUSTER_TOKEN=\"etcd-cluster-01\"" >> /etc/default/etcd
            echo "ETCD_INITIAL_CLUSTER=\"$hsn=http://$ipcontroller:2380\"" >> /etc/default/etcd
            echo "ETCD_INITIAL_ADVERTISE_PEER_URLS=\"http://$ipcontroller:2380\"" >> /etc/default/etcd
            echo "ETCD_ADVERTISE_CLIENT_URLS=\"http://$ipcontroller:2379\"" >> /etc/default/etcd
            echo "ETCD_LISTEN_PEER_URLS=\"http://0.0.0.0:2380\"" >> /etc/default/etcd
            echo "ETCD_LISTEN_CLIENT_URLS=\"http://$ipcontroller:2379\"" >> /etc/default/etcd
            systemctl enable etcd
            systemctl restart etcd
            break
            ;;
            "Keluar")
            break 3
            ;;
            *)
            echo "Pilih 1-4..."
            ;;
          esac
        done
      done
      break 2
      ;;
      "Keluar")
      break 3
      ;;
      *)
      echo "Opsi Pilihan 1-4...."
      ;;
    esac
  done
done
echo "Lanjut...."
