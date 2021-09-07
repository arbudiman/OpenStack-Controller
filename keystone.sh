#!/bin/sh
source conf_color.sh
source conf_netCheck.sh
source conf_distro.sh
source conf_package.sh
source conf_cdr.sh
source conf_ipc.sh
check_hosts=$(hostnamectl | grep hostname | awk '{print $3}')
pack=($check_packet)
key_check=(keystone keystone-common)
check_key=($check_keystone)
check_apc=($check_apache)
check_lib_apc=($check_lib_apache)
clear
echo "${B}${r}###################################### KONFIGURASI KEYSTONE ####################################${R}"
echo  "${B}Membuat Database Keystone :${R}"
read -r -p "Membuat Password Database Keystone => Password DBKeystone : " pwdKey
echo  "${B}Masukkan password MariaDB Server :${R}"
mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$pwdKey';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$pwdKey';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
echo  "${B}Membuat Database Keystone Sukses.... :${R}"
echo -e "\n"
echo "${B}Instalasi Service Keystone :${R}"
if [[ "${pack[@]}" = stein ]] || [[ "${pack[@]}" = train ]]
then
  echo "Library ${pack[@]}"
  if [[ ${check_key[@]} = ${key_check[@]} ]]
  then
    echo "${B}${r}Service Keystone sudah terinstall${R}"
    echo "${B}...Uninstall Service Keystone...${R}"
    echo -e "\n"
    apt remove --purge ${check_key[@]} -y
    echo "${B}...Uninstall Service Keystone Sukses...${R}"
  fi
  echo "${B}${b}...Install Service Keystone...${R}"
  apt install keystone -y
  echo "${B}...Install Service Keystone Sukses...${R}"
  echo -e "\n"
else
  echo "Library ${pack[@]}"
  if [[ ${check_key[@]} = ${key_check[@]} ]]
  then
    echo "${B}${r}Service Keystone sudah terinstall${R}"
    echo "${B}...Uninstall Service Keystone...${R}"
    echo -e "\n"
    apt remove --purge ${check_key[@]} -y
    echo "${B}...Uninstall Service Keystone Sukses...${R}"
  fi

  if [[ -n ${check_apc[@]} ]]
  then
    echo "${B}${r}Service Apache2 sudah terinstall${R}"
    echo "${B}...Uninstall Service Apache2...${R}"
    echo -e "\n"
    apt remove --purge ${check_apc[@]} -y
    echo "${B}...Uninstall Service Apache2 Sukses...${R}"
  fi

  if [[ -n ${check_lib_apc[@]} ]]
  then
    echo "${B}${r}Service Lib Mod Apache2 sudah terinstall${R}"
    echo "${B}...Uninstall Service Lib Mod Apache2...${R}"
    echo -e "\n"
    apt remove --purge ${check_lib_apc[@]} -y
    echo "${B}...Uninstall Service Lib Mod Apache2 Sukses...${R}"
  fi

  echo "${B}${b}...Install Service Keystone...${R}"
  apt install keystone  apache2 libapache2-mod-wsgi -y
  echo "${B}...Install Service Keystone Sukses...${R}"
fi
echo -e "\n"
echo "${B}...Konfigurasi Keystone...${R}"
check_db=$(cat /etc/keystone/keystone.conf | grep 'connection = sqlite' | awk '{ print $1 $2 $3; exit}')
if [[ -n ${check_db[@]} ]]
then
  sed -i -e 's/connection = sqlite/#&/' /etc/keystone/keystone.conf #menambahkan teks
  sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/keystone\:'$pwdKey'\@controller\/keystone' /etc/keystone/keystone.conf
  sed -i '/^\[token\]/a provider = fernet' /etc/keystone/keystone.conf
else
  sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/keystone\:'$pwdKey'\@controller\/keystone' /etc/keystone/keystone.conf
  sed -i '/^\[token\]/a provider = fernet' /etc/keystone/keystone.conf
fi
echo "${B}...Konfigurasi Keystone Sukses...${R}"
echo -e "\n"
echo "${B}...Sinkronisasi Database Keystone...${R}"
su -s /bin/sh -c "keystone-manage db_sync" keystone
echo -e "\n"
echo "${B}...Inisialisasi Fernet Key...${R}"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
echo -e "\n"
echo "${B}...Inisialisasi Identity Service...${R}"
read -r -p "Membuat Password Admin => Password Admin : " pwdAdmin
keystone-manage bootstrap --bootstrap-password "$pwdAdmin" \
--bootstrap-admin-url http://"$check_hosts":5000/v3/ \
--bootstrap-internal-url http://"$check_hosts":5000/v3/ \
--bootstrap-public-url http://"$check_hosts":5000/v3/ \
--bootstrap-region-id RegionOne
sed -i '/^\#ServerRoot /a ServerName '$check_hosts'' /etc/apache2/apache2.conf
systemctl restart apache2
#echo "" > conf_file.sh
echo "export admPWD=$pwdAdmin" >> conf_file.sh
echo "export dbPWD=$pwdKey" >> conf_file.sh
#sed -i '$ a export admPWD='$pwdAdmin'' conf_file.sh
#sed -i '$ a export dbPWD='$pwdKey'' conf_file.sh
echo "export OS_USERNAME=admin" > admin-openrc
sed -i '$ a export OS_PASSWORD='$pwdAdmin'' admin-openrc
sed -i '$ a export OS_PROJECT_NAME=admin' admin-openrc
sed -i '$ a export OS_USER_DOMAIN_NAME=Default' admin-openrc
sed -i '$ a export OS_PROJECT_DOMAIN_NAME=Default' admin-openrc
sed -i '$ a export OS_AUTH_URL=http://'$check_hosts':5000/v3' admin-openrc
sed -i '$ a export OS_IDENTITY_API_VERSION=3' admin-openrc
. admin-openrc
echo "${B}Membuat Domain Baru..${R}"
read -r -p "Masukan nama domain : " newDomain
#echo "$newDomain"
openstack domain create --description "Domain '$newDomain'" $newDomain
echo -e "\n"
echo "${B}Membuat Service Keystone...${R}"
openstack project create --domain default --description "Service Project" service
echo -e "\n"
echo "${B}Membuat Project Openstack...${R}"
read -r -p "Masukan nama project : " newProject
#echo "$newProject"
openstack project create --domain default --description "Project '$newProject'" $newProject
echo -e "\n"
echo "${B}Membuat User Openstack...${R}"
read -r -p "Masukan nama user : " newUser
#echo "$newUser"
openstack user create --domain default --password-prompt $newUser
echo -e "\n"
echo "${B}Membuat Role Openstack...${R}"
read -r -p "Masukan nama Role : " newRole
#echo "$newRole"
openstack role create $newRole
openstack role add --project $newProject --user $newUser $newRole
