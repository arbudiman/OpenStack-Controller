#!/bin/sh
read -r -p "Masukkan Password Baru MariaDB : " pwdDB
systemctl stop mysql
killall -vw mysqld
mysqld_safe --skip-grant-tables >res 2>&1 &
sleep 5
mysql mysql -e "update user set plugin='mysql_native_password';"
mysql mysql -e "update user set password=PASSWORD('$pwdDB') where User='root';FLUSh PRIVILEGES"
killall -v mysqld
systemctl restart mysql
