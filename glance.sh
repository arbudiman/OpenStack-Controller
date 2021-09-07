#!/bin/sh
source conf_color.sh
source conf_netCheck.sh
source conf_distro.sh
source conf_package.sh
source conf_cdr.sh
source conf_ipc.sh
source conf_file.sh
clear
check_hosts=$(hostnamectl | grep hostname | awk '{print $3}')
pack=($check_packet)
gla_check=(glance glance-api glance-common glance-registry glance-store-common)
check_gla=($check_glance)
check_apc=($check_apache)
check_lib_apc=($check_lib_apache)
echo "${B}${r}###################################### KONFIGURASI GLANCE ####################################${R}"
echo  "${B}Membuat Database Glance :${R}"
echo  "${B}Masukkan password MariaDB Server :${R}"
mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$dbPWD';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$dbPWD';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
echo  "${B}Membuat Database Glance Sukses.... :${R}"
echo -e "\n"
echo "${B}Instalasi Service Glance :${R}"
. admin-openrc
echo "${B}Membuat User Glance..${R}"
openstack user create --domain default --password "$admPWD" glance
echo "${B}Menambahkan role admin untuk user glance dan service project..${R}"
openstack role add --project service --user glance admin
echo "${B}Membuat entitas layanan Glance..${R}"
openstack service create --name glance --description "OpenStack Image" image
echo "${B}Membuat endpoint image service..${R}"
openstack endpoint create --region RegionOne image public http://"$check_hosts":9292
openstack endpoint create --region RegionOne image internal http://"$check_hosts":9292
openstack endpoint create --region RegionOne image admin http://"$check_hosts":9292
if [[ ${check_gla[@]} = ${gla_check[@]} ]]
then
  echo "${B}${r}Service Glance sudah terinstall${R}"
  echo "${B}...Uninstall Service Glance...${R}"
  echo -e "\n"
  apt remove --purge ${check_gla[@]} -y
  echo "${B}...Uninstall Service Glance Sukses...${R}"
fi
echo "${B}${b}...Install Service Glance...${R}"
apt install glance -y
apt install python3-openstackclient -y
echo "${B}...Install Service Glance Sukses...${R}"
echo -e "\n"
check_db=$(cat /etc/glance/glance-api.conf | grep 'connection = sqlite' | awk '{ print $1 $2 $3; exit}')
if [[ -n ${check_db[@]} ]]
then
  sed -i -e 's/connection = sqlite/#&/' /etc/glance/glance-api.conf #menambahkan teks
  sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/glance\:'$dbPWD'\@controller\/glance' /etc/glance/glance-api.conf
else
  sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/glance\:'$dbPWD'\@controller\/glance' /etc/glance/glance-api.conf
fi
sed -i '/^\[keystone_authtoken\]/a password = '$admPWD'' /etc/glance/glance-api.conf
sed -i '/^\[keystone_authtoken\]/a username = glance' /etc/glance/glance-api.conf
sed -i '/^\[keystone_authtoken\]/a project_name = service' /etc/glance/glance-api.conf
sed -i '/^\[keystone_authtoken\]/a user_domain_name = Default' /etc/glance/glance-api.conf
sed -i '/^\[keystone_authtoken\]/a project_domain_name = Default' /etc/glance/glance-api.conf
sed -i '/^\[keystone_authtoken\]/a auth_type = password' /etc/glance/glance-api.conf
sed -i '/^\[keystone_authtoken\]/a memcached_servers = '$check_hosts':11211' /etc/glance/glance-api.conf
sed -i '/^\[keystone_authtoken\]/a auth_url = http://'$check_hosts':5000' /etc/glance/glance-api.conf
if [[ "${pack[@]}" = queen ]]
then
  echo "Library ${pack[@]}"
  sed -i '/^\[keystone_authtoken\]/a auth_uri = http://'$check_hosts':5000' /etc/glance/glance-api.conf
else
  echo "Library ${pack[@]}"
  sed -i '/^\[keystone_authtoken\]/a www_authenticate_uri = http://'$check_hosts':5000' /etc/glance/glance-api.conf
fi
sed -i '/^\[paste_deploy\]/a flavor = keystone' /etc/glance/glance-api.conf
sed -i '/^\[glance_store\]/a filesystem_store_datadir = \/var\/lib\/glance\/images\/' /etc/glance/glance-api.conf
sed -i '/^\[glance_store\]/a default_store = file' /etc/glance/glance-api.conf
sed -i '/^\[glance_store\]/a stores = file\,http' /etc/glance/glance-api.conf
if [[ "${pack[@]}" = train ]]
then
  echo "Library ${pack[@]}"
  echo "${B}...Sinkronisasi Database glance...${R}"
  su -s /bin/sh -c "glance-manage db_sync" glance
  systemctl restart glance-api
else
  echo "Library ${pack[@]}"
  check_db2=$(cat /etc/glance/glance-registry.conf | grep 'connection = sqlite' | awk '{ print $1 $2 $3; exit}')
  if [[ -n ${check_db2[@]} ]]
  then
    sed -i -e 's/connection = sqlite/#&/' /etc/glance/glance-registry.conf #menambahkan teks
    sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/glance\:'$dbPWD'\@controller\/glance' /etc/glance/glance-registry.conf
  else
    sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/glance\:'$dbPWD'\@controller\/glance' /etc/glance/glance-registry.conf
  fi
  sed -i '/^\[keystone_authtoken\]/a password = '$admPWD'' /etc/glance/glance-registry.conf
  sed -i '/^\[keystone_authtoken\]/a username = glance' /etc/glance/glance-registry.conf
  sed -i '/^\[keystone_authtoken\]/a project_name = service' /etc/glance/glance-registry.conf
  sed -i '/^\[keystone_authtoken\]/a user_domain_name = Default' /etc/glance/glance-registry.conf
  sed -i '/^\[keystone_authtoken\]/a project_domain_name = Default' /etc/glance/glance-registry.conf
  sed -i '/^\[keystone_authtoken\]/a auth_type = password' /etc/glance/glance-registry.conf
  sed -i '/^\[keystone_authtoken\]/a memcached_servers = '$check_hosts':11211' /etc/glance/glance-registry.conf
  sed -i '/^\[keystone_authtoken\]/a auth_url = http://'$check_hosts':5000' /etc/glance/glance-registry.conf
  if [[ "${pack[@]}" = queen ]]
  then
    echo "Library ${pack[@]}"
    sed -i '/^\[keystone_authtoken\]/a auth_uri = http://'$check_hosts':5000' /etc/glance/glance-registry.conf
  else
    echo "Library ${pack[@]}"
    sed -i '/^\[keystone_authtoken\]/a www_authenticate_uri = http://'$check_hosts':5000' /etc/glance/glance-registry.conf
  fi
  sed -i '/^\[paste_deploy\]/a flavor = keystone' /etc/glance/glance-registry.conf
  echo "${B}...Sinkronisasi Database glance...${R}"
  su -s /bin/sh -c "glance-manage db_sync" glance
  systemctl restart glance-registry
  systemctl restart glance-api
fi
echo "${B}...Konfigurasi glance Sukses...${R}"
echo "${B}...Verifikasi Service Glance...${R}"
