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
net_check_1=(neutron-common neutron-dhcp-agent neutron-linuxbridge-agent neutron-metadata-agent neutron-plugin-ml2 neutron-server)
net_check_2=(neutron-common neutron-dhcp-agent neutron-fwaas-common neutron-l3-agent neutron-linuxbridge-agent neutron-metadata-agent neutron-plugin-ml2 neutron-server)
check_net_1=($check_neutron_ops1)
check_net_2=($check_neutron_ops2)
echo "${B}${r}###################################### KONFIGURASI NEUTRON ####################################${R}"
echo  "${B}Membuat Database Neutron :${R}"
echo  "${B}Masukkan password MariaDB Server :${R}"
mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$dbPWD';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$dbPWD';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
echo  "${B}Membuat Database Neutron Sukses.... :${R}"
echo -e "\n"
echo "${B}Instalasi Service neutron :${R}"
. admin-openrc
echo "${B}Membuat User neutron..${R}"
openstack user create --domain default --password $admPWD neutron
echo "${B}Menambahkan role admin untuk user neutron dan service project..${R}"
openstack role add --project service --user neutron admin
echo "${B}Membuat entitas layanan neutron..${R}"
openstack service create --name neutron --description "OpenStack Neutron" network
echo "${B}Membuat endpoint neutron service..${R}"
openstack endpoint create --region RegionOne network public http://$check_hosts:9696
openstack endpoint create --region RegionOne network internal http://$check_hosts:9696
openstack endpoint create --region RegionOne network admin http://$check_hosts:9696
while true
do
  echo  "${B}Instalasi Service Neutron :${R}"
  select opsi in "Providers Network" "Self-Service Network" "Keluar"
  do
    case $opsi in
      "Providers Network")
      echo "${B}${b}<--- Konfigurasi Providers Network --->${R}"
      if [[ ${check_net_1[@]} = ${net_check_1[@]} ]] || [[ ${check_net_2[@]} = ${net_check_2[@]} ]]
      then
        echo "${B}${r}Service Neutron sudah terinstall${R}"
        echo "${B}...Uninstall Service Neutron...${R}"
        echo -e "\n"
        apt remove --purge ${net_check_2[@]} -y
        echo "${B}...Uninstall Service Neutron Sukses...${R}"
      fi
      echo "${B}${r}<--- Install Service Neutron --->${R}"
      apt install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent -y
      echo "${B}${r}...Install Service Neutron Sukses...${R}"
      echo "${B}${r}<--- Konfigurasi Service Neutron --->${R}"
      check_db1=$(cat /etc/neutron/neutron.conf | grep 'connection = sqlite' | awk '{ print $1 $2 $3; exit}')
      if [[ -n ${check_db1[@]} ]]
      then
        sed -i -e 's/connection = sqlite/#&/' /etc/neutron/neutron.conf #menambahkan teks
        sed -i '/^\[database\]/a connection \= mysql\+pymysql\:\/\/neutron\:'$dbPWD'\@'$check_hosts'\/neutron' /etc/neutron/neutron.conf
      else
        sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/neutron\:'$dbPWD'\@'$check_hosts'\/neutron' /etc/neutron/neutron.conf
      fi
      sed -i '/^\[DEFAULT\]/a notify_nova_on_port_data_changes \= true' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a notify_nova_on_port_status_changes \= true' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a auth_strategy \= keystone' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a transport_url \= rabbit\:\/\/openstack\:'$rabPWD'\@'$check_hosts'' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a service_plugins \=' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a core_plugin \= ml2' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a password \= '$admPWD'' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a username \= neutron' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a project_name \= service' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a user_domain_name \= Default' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a project_domain_name \= Default' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a auth_type \= password' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a memcached_servers \= '$check_hosts':11211' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a auth_url \= http\:\/\/'$check_hosts':5000' /etc/neutron/neutron.conf
      if [[ "${pack[@]}" = queen ]]
      then
        echo "Library..... ${pack[@]}"
        sed -i '/^\[keystone_authtoken\]/a auth_uri \= http\:\/\/'$check_hosts'\:5000' /etc/neutron/neutron.conf
      else
        echo "Library..... ${pack[@]}"
        sed -i '/^\[keystone_authtoken\]/a www_authenticate_uri \= http\:\/\/'$check_hosts'\:5000' /etc/neutron/neutron.conf
      fi
      sed -i '/^\[nova\]/a password \= '$admPWD'' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a username \= nova' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a project_name \= service' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a region_name \= RegionOne' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a user_domain_name \= Default' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a project_domain_name \= Default' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a auth_type \= password' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a auth_url \= http\:\/\/'$check_hosts'\:5000' /etc/neutron/neutron.conf
      sed -i '/^\[oslo_concurrency\]/a lock_path \= \/var\/lib\/neutron\/tmp' /etc/neutron/neutron.conf
      sed -i '/^\[ml2\]/a extension_drivers \= port_security' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[ml2\]/a mechanism_drivers \= linuxbridge' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[ml2\]/a tenant_network_types \=' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[ml2\]/a type_drivers \= flat\,vlan' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[ml2_type_flat\]/a flat_networks \= provider' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[securitygroup\]/a enable_ipset \= true' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[linux_bridge\]/a physical_interface_mappings \= provider:'$ethManual'' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
      sed -i '/^\[vxlan\]/a enable_vxlan \= false' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
      sed -i '/^\[securitygroup\]/a enable_security_group \= true' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
      sed -i '/^\[securitygroup\]/a firewall_driver \= neutron\.agent\.linux\.iptables\_firewall\.IptablesFirewallDriver' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
      modprobe br_netfilter
      sed -i '/^\[DEFAULT\]/a enable_isolated_metadata \= true' /etc/neutron/dhcp_agent.ini
      sed -i '/^\[DEFAULT\]/a dhcp_driver \= neutron\.agent\.linux\.dhcp\.Dnsmasq' /etc/neutron/dhcp_agent.ini
      sed -i '/^\[DEFAULT\]/a interface_driver \= linuxbridge' /etc/neutron/dhcp_agent.ini
      sed -i '/^\[DEFAULT\]/a metadata_proxy_shared_secret = '$admPWD'' /etc/neutron/metadata_agent.ini
      sed -i '/^\[DEFAULT\]/a nova_metadata_host \= '$check_hosts'' /etc/neutron/metadata_agent.ini
      if [[ "${pack[@]}" = train ]]
      then
        echo "Library..... ${pack[@]}"
        sed -i '/^\[neutron\]/a metadata_proxy_shared_secret \= '$admPWD'' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a service_metadata_proxy \= true' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a password \= '$admPWD'' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a username \= neutron' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a project_name \= service' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a region_name \= RegionOne' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a user_domain_name \= Default' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a project_domain_name \= Default' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a auth_type \= password' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a auth_url = http://'$check_hosts':5000' /etc/nova/nova.conf
      else
        echo "Library..... ${pack[@]}"
        sed -i '/^\[neutron\]/a metadata_proxy_shared_secret \= '$admPWD'' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a service_metadata_proxy \= true' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a password \= '$admPWD'' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a username \= neutron' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a project_name \= service' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a region_name \= RegionOne' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a user_domain_name \= Default' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a project_domain_name \= Default' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a auth_type \= password' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a auth_url = http://'$check_hosts':5000' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a url = http://'$check_hosts':9696' /etc/nova/nova.conf
      fi
      echo "${B}...Upgrade MariaDB...${R}"
      systemctl stop mysqld
      apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
      add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://www.ftp.saix.net/DB/mariadb/repo/10.3/ubuntu bionic main'
      apt update
      apt install mariadb-server -y
      systemctl start mysqld
      echo "${B}...Sinkronisasi Database Neutron...${R}"
      su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
      echo "${B}...Restart Service Nova-Api...${R}"
      service nova-api restart
      echo "${B}...Restart Service Neutron...${R}"
      service neutron-server restart
      service neutron-linuxbridge-agent restart
      service neutron-dhcp-agent restart
      service neutron-metadata-agent restart
      . admin-openrc
      echo "${B}...Verifikasi Service Providers Network...${R}"
      openstack network agent list
      break 2
      ;;
      "Self-Service Network")
      echo "${B}${b}<--- Konfigurasi Self-Service Network --->${R}"
      if [[ ${check_net_2[@]} = ${net_check_2[@]} ]] || [[ ${check_net_1[@]} = ${net_check_1[@]} ]]
      then
        echo "${B}${r}Service Neutron sudah terinstall${R}"
        echo "${B}...Uninstall Service Neutron...${R}"
        echo -e "\n"
        apt remove --purge ${net_check_2[@]} -y
        echo "${B}...Uninstall Service Neutron Sukses...${R}"
      fi
      echo "${B}${r}<--- Install Service Neutron --->${R}"
      apt install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent -y
      echo "${B}${r}...Install Service Neutron Sukses...${R}"
      echo "${B}${r}<--- Konfigurasi Service Neutron --->${R}"
      check_db1=$(cat /etc/neutron/neutron.conf | grep 'connection = sqlite' | awk '{ print $1 $2 $3; exit}')
      if [[ -n ${check_db1[@]} ]]
      then
        sed -i -e 's/connection = sqlite/#&/' /etc/neutron/neutron.conf #menambahkan teks
        sed -i '/^\[database\]/a connection \= mysql\+pymysql\:\/\/neutron\:'$dbPWD'\@'$check_hosts'\/neutron' /etc/neutron/neutron.conf
      else
        sed -i '/\[database\]/a connection \= mysql\+pymysql\:\/\/neutron\:'$dbPWD'\@'$check_hosts'\/neutron' /etc/neutron/neutron.conf
      fi
      sed -i '/^\[DEFAULT\]/a notify_nova_on_port_data_changes \= true' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a notify_nova_on_port_status_changes \= true' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a auth_strategy \= keystone' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a transport_url \= rabbit\:\/\/openstack\:'$rabPWD'\@'$check_hosts'' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a allow_overlapping_ips \= true' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a service_plugins \= router' /etc/neutron/neutron.conf
      sed -i '/^\[DEFAULT\]/a core_plugin \= ml2' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a password \= '$admPWD'' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a username \= neutron' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a project_name \= service' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a user_domain_name \= Default' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a project_domain_name \= Default' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a auth_type \= password' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a memcached_servers \= '$check_hosts':11211' /etc/neutron/neutron.conf
      sed -i '/^\[keystone_authtoken\]/a auth_url \= http\:\/\/'$check_hosts':5000' /etc/neutron/neutron.conf
      if [[ "${pack[@]}" = queen ]]
      then
        echo "Library..... ${pack[@]}"
        sed -i '/^\[keystone_authtoken\]/a auth_uri \= http\:\/\/'$check_hosts'\:5000' /etc/neutron/neutron.conf
      else
        echo "Library..... ${pack[@]}"
        sed -i '/^\[keystone_authtoken\]/a www_authenticate_uri \= http\:\/\/'$check_hosts'\:5000' /etc/neutron/neutron.conf
      fi
      sed -i '/^\[nova\]/a password \= '$admPWD'' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a username \= nova' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a project_name \= service' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a region_name \= RegionOne' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a user_domain_name \= Default' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a project_domain_name \= Default' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a auth_type \= password' /etc/neutron/neutron.conf
      sed -i '/^\[nova\]/a auth_url \= http\:\/\/'$check_hosts'\:5000' /etc/neutron/neutron.conf
      sed -i '/^\[oslo_concurrency\]/a lock_path \= \/var\/lib\/neutron\/tmp' /etc/neutron/neutron.conf
      sed -i '/^\[ml2\]/a extension_drivers \= port_security' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[ml2\]/a mechanism_drivers \= linuxbridge\,l2population' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[ml2\]/a tenant_network_types \= vxlan' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[ml2\]/a type_drivers \= flat\,vlan\,vxlan' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[ml2_type_flat\]/a flat_networks \= provider' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[ml2_type_vxlan\]/a vni_ranges = 1:1000' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[securitygroup\]/a enable_ipset \= true' /etc/neutron/plugins/ml2/ml2_conf.ini
      sed -i '/^\[linux_bridge\]/a physical_interface_mappings \= provider:'$ethManual'' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
      sed -i '/^\[vxlan\]/a l2_population \= true' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
      sed -i '/^\[vxlan\]/a local_ip \= '$ipm1'' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
      sed -i '/^\[vxlan\]/a enable_vxlan \= true' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
      sed -i '/^\[securitygroup\]/a enable_security_group \= true' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
      sed -i '/^\[securitygroup\]/a firewall_driver \= neutron\.agent\.linux\.iptables\_firewall\.IptablesFirewallDriver' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
      modprobe br_netfilter
      sed -i '/^\[DEFAULT\]/a interface_driver \= linuxbridge' /etc/neutron/l3_agent.ini
      sed -i '/^\[DEFAULT\]/a enable_isolated_metadata \= true' /etc/neutron/dhcp_agent.ini
      sed -i '/^\[DEFAULT\]/a dhcp_driver \= neutron\.agent\.linux\.dhcp\.Dnsmasq' /etc/neutron/dhcp_agent.ini
      sed -i '/^\[DEFAULT\]/a interface_driver \= linuxbridge' /etc/neutron/dhcp_agent.ini
      sed -i '/^\[DEFAULT\]/a metadata_proxy_shared_secret = '$admPWD'' /etc/neutron/metadata_agent.ini
      sed -i '/^\[DEFAULT\]/a nova_metadata_host \= '$check_hosts'' /etc/neutron/metadata_agent.ini
      if [[ "${pack[@]}" = train ]]
      then
        echo "Library..... ${pack[@]}"
        sed -i '/^\[neutron\]/a metadata_proxy_shared_secret \= '$admPWD'' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a service_metadata_proxy \= true' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a password \= '$admPWD'' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a username \= neutron' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a project_name \= service' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a region_name \= RegionOne' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a user_domain_name \= Default' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a project_domain_name \= Default' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a auth_type \= password' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a auth_url = http://'$check_hosts':5000' /etc/nova/nova.conf
      else
        echo "Library..... ${pack[@]}"
        sed -i '/^\[neutron\]/a metadata_proxy_shared_secret \= '$admPWD'' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a service_metadata_proxy \= true' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a password \= '$admPWD'' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a username \= neutron' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a project_name \= service' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a region_name \= RegionOne' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a user_domain_name \= Default' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a project_domain_name \= Default' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a auth_type \= password' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a auth_url = http://'$check_hosts':5000' /etc/nova/nova.conf
        sed -i '/^\[neutron\]/a url = http://'$check_hosts':9696' /etc/nova/nova.conf
      fi
      echo "${B}...Sinkronisasi Database Neutron...${R}"
      su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
      echo "${B}...Restart Service Nova-Api...${R}"
      service nova-api restart
      echo "${B}...Restart Service Neutron...${R}"
      service neutron-server restart
      service neutron-linuxbridge-agent restart
      service neutron-dhcp-agent restart
      service neutron-metadata-agent restart
      service neutron-l3-agent restart
      echo "${B}...Verifikasi Service Providers Network...${R}"
      . admin-openrc
      openstack network agent list
      break 2
      ;;
      "Keluar")
      break 2
      ;;
      *)
      echo "Pilih 1-4..."
      ;;
    esac
  done
done
