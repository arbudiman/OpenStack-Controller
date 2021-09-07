#!/bin/sh
source conf_color.sh
source conf_netCheck.sh
source conf_distro.sh
source conf_package.sh
source conf_cdr.sh
source conf_ipc.sh
clear
check_hosts=$(hostnamectl | grep hostname | awk '{print $3}')
pack=($check_packet)
dash_check=(openstack-dashboard openstack-dashboard-common)
check_dash=($check_dashboard)
echo "${B}${r}###################################### KONFIGURASI DASHBOARD ####################################${R}"
echo "${B}Instalasi Openstack Dashboard :${R}"
if [[ ${check_dash[@]} = ${dash_check[@]} ]]
then
  echo "${B}${r}Openstack Dashboard sudah terinstall${R}"
  echo "${B}...Uninstall Openstack Dashboard...${R}"
  echo -e "\n"
  apt remove --purge ${check_dash[@]} -y
  echo "${B}...Uninstall Openstack Dashboard Sukses...${R}"
fi
apt install openstack-dashboard -y
echo "${B}...Install Openstack Dashboard Sukses...${R}"
echo "${B}${b}<---Konfigurasi Openstack Dashboard--->${R}"
read -r -p "Membuat nama domain dashboard openstack, contoh awan.tasikmalayakota.go.id : " domDash
sed -i -e 's/^OPENSTACK_HOST \= \"127\.0\.0\.1\"/OPENSTACK_HOST \= \"'$check_hosts'\"/g' /etc/openstack-dashboard/local_settings.py
sed -i -e "s/#ALLOWED_HOSTS/ALLOWED_HOSTS/g" /etc/openstack-dashboard/local_settings.py
sed -i -e "s/'horizon.example.com', /'$domDash'/g" /etc/openstack-dashboard/local_settings.py
sed -i -e "s/'127.0.0.1:11211'/'$check_hosts:11211'/g" /etc/openstack-dashboard/local_settings.py
sed -i -e "/^CACHES/i SESSION_ENGINE = 'django.contrib.sessions.backends.cache'" /etc/openstack-dashboard/local_settings.py
sed -i -e '/^OPENSTACK_NEUTRON_NETWORK.*/i OPENSTACK_API_VERSIONS = {\n   "identity": 3,\n   "image": 2,\n   "volume": 3,\n}' /etc/openstack-dashboard/local_settings.py
sed -i -e '/^OPENSTACK_KEYSTONE_URL.*/a OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True' /etc/openstack-dashboard/local_settings.py
sed -i -e '/^OPENSTACK_NEUTRON_NETWORK.*/i OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"' /etc/openstack-dashboard/local_settings.py
sed -i -e '/^OPENSTACK_NEUTRON_NETWORK.*/i OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"' /etc/openstack-dashboard/local_settings.py
sed -i -e 's/_member_/user/g' /etc/openstack-dashboard/local_settings.py
sed -i -e "s/'enable_distributed_router': False/'enable_distributed_router': True/g" /etc/openstack-dashboard/local_settings.py
sed -i -e "s/'enable_ha_router': False/'enable_ha_router': True/g" /etc/openstack-dashboard/local_settings.py
sed -i "/'enable_ha_router'/a     'enable_firewall': False," /etc/openstack-dashboard/local_settings.py
sed -i "/'enable_ha_router'/a     'enable_lb': False," /etc/openstack-dashboard/local_settings.py
echo "${B}...Restart Service Apache2...${R}"
systemctl reload apache2.service
