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
nov_check=(nova-api nova-common nova-conductor nova-consoleauth nova-novncproxy nova-placement-api nova-scheduler)
check_nov=($check_nova)
check_apc=($check_apache)
check_lib_apc=($check_lib_apache)
echo "${B}${r}###################################### KONFIGURASI COMPUTE ####################################${R}"
echo  "${B}Membuat Database Nova :${R}"
echo  "${B}Masukkan password MariaDB Server :${R}"
if [[ "${pack[@]}" = queen ]]
then
  echo "Library ${pack[@]}"
  mysql -u root -p <<MYSQL_SCRIPT
  CREATE DATABASE IF NOT EXISTS nova_api;
  CREATE DATABASE IF NOT EXISTS nova;
  CREATE DATABASE IF NOT EXISTS nova_cell0;
  GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$dbPWD';
  FLUSH PRIVILEGES;
MYSQL_SCRIPT
else
  echo "Library ${pack[@]}"
  mysql -uroot -p <<MYSQL_SCRIPT
  CREATE DATABASE IF NOT EXISTS nova_api;
  CREATE DATABASE IF NOT EXISTS nova;
  CREATE DATABASE IF NOT EXISTS nova_cell0;
  CREATE DATABASE IF NOT EXISTS placement;
  GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '$dbPWD';
  GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '$dbPWD';
MYSQL_SCRIPT
fi
echo  "${B}Membuat Database Nova Sukses.... :${R}"
echo -e "\n"
echo "${B}Instalasi Service nova :${R}"
. admin-openrc
echo "${B}Membuat User nova..${R}"
openstack user create --domain default --password "$admPWD" nova
echo "${B}Menambahkan role admin untuk user nova dan service project..${R}"
openstack role add --project service --user nova admin
echo "${B}Membuat entitas layanan nova..${R}"
openstack service create --name nova --description "OpenStack Compute" compute
echo "${B}Membuat endpoint nova service..${R}"
openstack endpoint create --region RegionOne compute public http://"$check_hosts":8774/v2.1
openstack endpoint create --region RegionOne compute internal http://"$check_hosts":8774/v2.1
openstack endpoint create --region RegionOne compute admin http://"$check_hosts":8774/v2.1
echo "${B}Membuat User Placement..${R}"
openstack user create --domain default --password "$admPWD" placement
echo "${B}Menambahkan role admin untuk user placement dan service project..${R}"
openstack role add --project service --user placement admin
echo "${B}Membuat entitas layanan placement..${R}"
openstack service create --name placement --description "Placement API" placement
echo "${B}Membuat endpoint placement service..${R}"
openstack endpoint create --region RegionOne placement public http://"$check_hosts":8778
openstack endpoint create --region RegionOne placement internal http://"$check_hosts":8778
openstack endpoint create --region RegionOne placement admin http://"$check_hosts":8778

if [[ ${check_nov[@]} = ${nov_check[@]} ]]
then
  echo "${B}${r}Service nova sudah terinstall${R}"
  echo "${B}...Uninstall Service nova...${R}"
  echo -e "\n"
  apt remove --purge ${check_nov[@]} -y
  echo "${B}...Uninstall Service nova Sukses...${R}"
fi
echo "${B}${r}Install Service Nova dan Placement${R}"
if [[ "${pack[@]}" = queen ]] || [[ "${pack[@]}" = rocky ]]
then
  echo "Library.. ${pack[@]}"
  apt install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler nova-placement-api -y
elif [[ "${pack[@]}" = stein ]]
then
  echo "Library.. ${pack[@]}"
  apt install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler placement-api -y
else
  echo "Library.. ${pack[@]}"
  apt install nova-api nova-conductor nova-novncproxy nova-scheduler placement-api -y
fi
echo "${B}${r}Install Service Nova dan Placement Sukses...${R}"
check_db1=$(cat /etc/nova/nova.conf | grep 'connection = sqlite' | awk '{ print $1 $2 $3; exit}')
check_db3=$(cat /etc/nova/nova.conf | grep 'connection = sqlite' | awk '{ print $1 $2 $3; exit}')
echo "${B}${r}<--- Konfigurasi Service Nova --->${R}"
if [[ "${pack[@]}" = rocky ]]
then
  if [[ -n ${check_db1[@]} ]]
  then
    echo "Library... ${pack[@]}"
    sed -i -e 's/connection = sqlite/#&/' /etc/nova/nova.conf #menambahkan teks
    sed -i '/^\[api_database\]/a connection \= mysql\+pymysql\:\/\/nova\:'$dbPWD'\@'$check_hosts'\/nova_api' /etc/nova/nova.conf
    sed -i '/^\[database\]/a connection \= mysql\+pymysql\:\/\/nova\:'$dbPWD'\@'$check_hosts'\/nova' /etc/nova/nova.conf
    sed -i '/^\[placement_database\]/a connection \= mysql\+pymysql\:\/\/placement\:'$dbPWD'\@'$check_hosts'\/placement' /etc/nova/nova.conf
  else
    sed -i '/^\[api_database\]/a connection \= mysql\+pymysql\:\/\/nova\:'$dbPWD'\@'$check_hosts'\/nova_api' /etc/nova/nova.conf
    sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/nova\:'$dbPWD'\@'$check_hosts'\/nova' /etc/nova/nova.conf
    sed -i '/^\[placement_database\]/a connection \= mysql\+pymysql\:\/\/placement\:'$dbPWD'\@'$check_hosts'\/placement' /etc/nova/nova.conf
  fi
else
  echo "Library... ${pack[@]}"
  if [[ -n ${check_db1[@]} ]]
  then
    sed -i -e 's/connection = sqlite/#&/' /etc/nova/nova.conf #menambahkan teks
    sed -i '/^\[api_database\]/a connection \= mysql\+pymysql\:\/\/nova\:'$dbPWD'\@'$check_hosts'\/nova_api' /etc/nova/nova.conf
    sed -i '/^\[database\]/a connection \= mysql\+pymysql\:\/\/nova\:'$dbPWD'\@'$check_hosts'\/nova' /etc/nova/nova.conf
  else
    sed -i '/^\[api_database\]/a connection \= mysql\+pymysql\:\/\/nova\:'$dbPWD'\@'$check_hosts'\/nova_api' /etc/nova/nova.conf
    sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/nova\:'$dbPWD'\@'$check_hosts'\/nova' /etc/nova/nova.conf
  fi
fi
sed -i '/^\[DEFAULT\]/a firewall_driver \= nova\.virt\.firewall\.NoopFirewallDriver' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a use_neutron \= true' /etc/nova/nova.conf
sed -i '/^\[DEFAULT\]/a my_ip \= '$ipcontroller'' /etc/nova/nova.conf
if [[ "${pack[@]}" = train ]]
then
  echo "Library.... ${pack[@]}"
  sed -i '/^\[DEFAULT\]/a transport_url \= rabbit\:\/\/openstack\:'$rabPWD'\@'$check_hosts':5672' /etc/nova/nova.conf
else
  echo "Library.... ${pack[@]}"
  sed -i '/^\[DEFAULT\]/a transport_url \= rabbit\:\/\/openstack\:'$rabPWD'\@'$check_hosts'' /etc/nova/nova.conf
fi
sed -i '/^\[api\]/a auth_strategy \= keystone' /etc/nova/nova.conf
if [[ "${pack[@]}" = train ]]
then
  echo "Library..... ${pack[@]}"
  sed -i '/^\[keystone_authtoken\]/a password \= '$admPWD'' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a username \= nova' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a project_name \= service' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a user_domain_name \= Default' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a project_domain_name \= Default' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a auth_type \= password' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a memcached_servers \= '$check_hosts':11211' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a auth_url \= http\:\/\/'$check_hosts':5000\/' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a www_authenticate_uri \= http\:\/\/'$check_hosts'\:5000\/' /etc/nova/nova.conf
else
  echo "Library..... ${pack[@]}"
  sed -i '/^\[keystone_authtoken\]/a password \= '$admPWD'' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a username \= nova' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a project_name \= service' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a user_domain_name \= Default' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a project_domain_name \= Default' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a auth_type \= password' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a memcached_servers \= '$check_hosts':11211' /etc/nova/nova.conf
  sed -i '/^\[keystone_authtoken\]/a auth_url \= http\:\/\/'$check_hosts':5000\/' /etc/nova/nova.conf
fi
sed -i '/^\[vnc\]/a server_proxyclient_address \= $my_ip' /etc/nova/nova.conf
sed -i '/^\[vnc\]/a server_listen \= $my_ip' /etc/nova/nova.conf
sed -i '/^\[vnc\]/a enabled \= true' /etc/nova/nova.conf
sed -i '/^\[glance\]/a api_servers \= http\:\/\/'$check_hosts'\:9292' /etc/nova/nova.conf
sed -i '/^\[oslo_concurrency\]/a lock_path \= \/var\/lib\/nova\/tmp' /etc/nova/nova.conf
sed -i '/^\[scheduler\]/a discover\_hosts\_in\_cells\_interval \= 300' /etc/nova/nova.conf

if [[ "${pack[@]}" = queen ]]
then
  echo "Library...... ${pack[@]}"
  sed -i '/^\[placement\]/a password \= '$admPWD'' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a username \= placement' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a auth_url \= http\:\/\/'$check_hosts'\:5000\/v3' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a user_domain_name \= Default' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a auth_type \= password' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a project_name \= service' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a project_domain_name \= Default' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a os_region_name \= RegionOne' /etc/nova/nova.conf
else
  echo "Library...... ${pack[@]}"
  sed -i '/^\[placement\]/a password \= '$admPWD'' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a username \= placement' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a auth_url \= http\:\/\/'$check_hosts'\:5000\/v3' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a user_domain_name \= Default' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a auth_type \= password' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a project_name \= service' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a project_domain_name \= Default' /etc/nova/nova.conf
  sed -i '/^\[placement\]/a region_name \= RegionOne' /etc/nova/nova.conf
fi
echo "${B}${r}<--- Konfigurasi Service Nova dan Placement Sukses... --->${R}"
echo "${B}${r}.... Sinkronisasi Database Nova-API ....${R}"
su -s /bin/sh -c "nova-manage api_db sync" nova
echo "${B}${r}.... Registrasi Database Cell0 ....${R}"
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
echo "${B}${r}.... Membuat Cell Cell1 ....${R}"
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
echo "${B}${r}.... Sinkronisasi Database Nova ....${R}"
su -s /bin/sh -c "nova-manage db sync" nova
if [[ "${pack[@]}" = queen ]]
then
  echo "Library....... ${pack[@]}"
  nova-manage cell_v2 list_cells
else
  echo "Library....... ${pack[@]}"
  su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
fi
echo "${B}${r}.... Restart Service Nova ....${R}"
if [[ "${pack[@]}" = train ]]
then
  echo "Library........ ${pack[@]}"
  service nova-api restart
  service nova-scheduler restart
  service nova-conductor restart
  service nova-novncproxy restart
else
  echo "Library........ ${pack[@]}"
  service nova-api restart
  service nova-consoleauth restart
  service nova-scheduler restart
  service nova-conductor restart
  service nova-novncproxy restart
fi

if [[ "${pack[@]}" = stein ]] || [[ "${pack[@]}" = train ]]
then
  echo "Library......... ${pack[@]}"
  echo "${B}${r}<--- Konfigurasi Service Placement --->${R}"
  check_db2=$(cat /etc/placement/placement.conf | grep 'connection = sqlite' | awk '{ print $1 $2 $3; exit}')
  if [[ -n ${check_db2[@]} ]]
  then
    sed -i -e 's/connection = sqlite/#&/' /etc/placement/placement.conf #menambahkan teks
    sed -i '/^\[placement_database\]/a connection \= mysql\+pymysql\:\/\/placement\:'$dbPWD'\@'$check_hosts'\/placement' /etc/placement/placement.conf
  else
    sed -i '/^\[placement_database\]/a connection \= mysql\+pymysql\:\/\/placement\:'$dbPWD'\@'$check_hosts'\/placement' /etc/placement/placement.conf
  fi
  sed -i '/^\[api\]/a auth_strategy \= keystone' /etc/placement/placement.conf
  sed -i '/^\[keystone_authtoken\]/a password \= '$admPWD'' /etc/placement/placement.conf
  sed -i '/^\[keystone_authtoken\]/a username \= placement' /etc/placement/placement.conf
  sed -i '/^\[keystone_authtoken\]/a project_name \= service' /etc/placement/placement.conf
  sed -i '/^\[keystone_authtoken\]/a user_domain_name \= Default' /etc/placement/placement.conf
  sed -i '/^\[keystone_authtoken\]/a project_domain_name \= Default' /etc/placement/placement.conf
  sed -i '/^\[keystone_authtoken\]/a auth_type \= password' /etc/placement/placement.conf
  sed -i '/^\[keystone_authtoken\]/a memcached_servers \= '$check_hosts':11211' /etc/placement/placement.conf
  sed -i '/^\[keystone_authtoken\]/a auth_url \= http\:\/\/'$check_hosts':5000\/' /etc/placement/placement.conf
  echo "${B}${r}.... Sinkronisasi Database Placement ....${R}"
  su -s /bin/sh -c "placement-manage db sync" placement
  service apache2 restart
  echo "${B}...Verifikasi Service Placement...${R}"
  placement-status upgrade check
fi
echo "${B}...Verifikasi Service Nova...${R}"
. admin-openrc
openstack catalog list
openstack compute service list
