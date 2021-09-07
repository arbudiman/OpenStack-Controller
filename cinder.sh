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
cin_check=(cinder-api cinder-common cinder-scheduler)
check_cin=($check_cinder)
source updateDB.sh
echo "${B}${r}###################################### KONFIGURASI STORAGE ####################################${R}"
echo  "${B}Membuat Database Cinder :${R}"
echo  "${B}Masukkan password MariaDB Server :${R}"
mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$dbPWD';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$dbPWD';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
echo  "${B}Membuat Database Cinder Sukses.... :${R}"
echo -e "\n"
echo "${B}Instalasi Service Cinder :${R}"
. admin-openrc
echo "${B}Membuat User Cinder..${R}"
openstack user create --domain default --password $admPWD cinder
echo "${B}Menambahkan role admin untuk user cinder dan service project..${R}"
openstack role add --project service --user cinder admin
echo "${B}Membuat entitas layanan cinder..${R}"
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
echo "${B}Membuat endpoint cinder service..${R}"
openstack endpoint create --region RegionOne volumev2 public http://$check_hosts:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://$check_hosts:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://$check_hosts:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 public http://$check_hosts:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://$check_hosts:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://$check_hosts:8776/v3/%\(project_id\)s
echo  "${B}Instalasi Service Cinder :${R}"
if [[ ${check_cin[@]} = ${cin_check[@]} ]]
then
  echo "${B}${r}Service Cinder sudah terinstall${R}"
  echo "${B}...Uninstall Service cinder...${R}"
  echo -e "\n"
  apt remove --purge ${cin_check[@]} -y
  echo "${B}...Uninstall Service Cinder Sukses...${R}"
fi
apt install cinder-api cinder-scheduler -y
echo "${B}${r}...Install Service Cinder Sukses...${R}"
echo "${B}${r}<--- Konfigurasi Service Cinder --->${R}"
check_db1=$(cat /etc/cinder/cinder.conf | grep 'connection = sqlite' | awk '{ print $1 $2 $3; exit}')
check_db2=$(cat /etc/cinder/cinder.conf | grep 'auth_strategy = keystone' | awk '{ print $1 $2 $3; exit}')
if [[ -n ${check_db1[@]} ]]
then
  sed -i -e 's/connection = sqlite/#&/' /etc/cinder/cinder.conf #menambahkan teks
  sed -i '/^\[database\]/a connection \= mysql\+pymysql\:\/\/cinder\:'$dbPWD'\@'$check_hosts'\/cinder' /etc/cinder/cinder.conf
else
  sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/cinder\:'$dbPWD'\@'$check_hosts'\/cinder' /etc/cinder/cinder.conf
fi
if [[ -n ${check_db2[@]} ]]
then
  sed -i -e 's/auth_strategy = keystone/#&/' /etc/cinder/cinder.conf #menambahkan teks
  sed -i '/^verbose/a auth_strategy \= keystone' /etc/cinder/cinder.conf
else
  sed -i '/^verbose/a auth_strategy \= keystone' /etc/cinder/cinder.conf
fi
sed -i '/^api_paste_confg/a transport_url \= rabbit\:\/\/openstack\:'$rabPWD'\@'$check_hosts'' /etc/cinder/cinder.conf
echo -e "\n" >> /etc/cinder/cinder.conf
echo "[keystone_authtoken]" >> /etc/cinder/cinder.conf
sed -i '/^\[keystone_authtoken\]/a password \= '$admPWD'' /etc/cinder/cinder.conf
sed -i '/^\[keystone_authtoken\]/a username \= cinder' /etc/cinder/cinder.conf
sed -i '/^\[keystone_authtoken\]/a project_name \= service' /etc/cinder/cinder.conf
sed -i '/^\[keystone_authtoken\]/a user_domain_name \= Default' /etc/cinder/cinder.conf
sed -i '/^\[keystone_authtoken\]/a project_domain_name \= Default' /etc/cinder/cinder.conf
sed -i '/^\[keystone_authtoken\]/a auth_type \= password' /etc/cinder/cinder.conf
sed -i '/^\[keystone_authtoken\]/a memcached_servers \= '$check_hosts':11211' /etc/cinder/cinder.conf
sed -i '/^\[keystone_authtoken\]/a auth_url \= http\:\/\/'$check_hosts':5000' /etc/cinder/cinder.conf
if [[ "${pack[@]}" = queen ]]
then
  echo "Library..... ${pack[@]}"
  sed -i '/^\[keystone_authtoken\]/a auth_uri \= http\:\/\/'$check_hosts'\:5000' /etc/cinder/cinder.conf
else
  echo "Library..... ${pack[@]}"
  sed -i '/^\[keystone_authtoken\]/a www_authenticate_uri \= http\:\/\/'$check_hosts'\:5000' /etc/cinder/cinder.conf
fi
sed -i '/^enabled_backends/a my_ip \= '$ipm1'' /etc/cinder/cinder.conf
echo -e "\n" >> /etc/cinder/cinder.conf
echo "[oslo_concurrency]" >> /etc/cinder/cinder.conf
sed -i '/^\[oslo_concurrency\]/a lock_path \= \/var\/lib\/cinder\/tmp' /etc/cinder/cinder.conf
echo "${B}...Sinkronisasi Database cinder...${R}"
su -s /bin/sh -c "cinder-manage db sync" cinder
sed -i '/^\[cinder\]/a os_region_name = RegionOne' /etc/nova/nova.conf
echo "${B}...Restart Service Nova-Api...${R}"
service nova-api restart
echo "${B}...Restart Service Cinder...${R}"
service cinder-scheduler restart
service apache2 restart
. admin-openrc
echo "${B}...Verifikasi Service Cinder...${R}"
openstack volume service list
