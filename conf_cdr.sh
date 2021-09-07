#!/bin/sh
#ipm1=$(ifconfig | awk '/inet / {print $2; exit}')
ipm1=$(cat /etc/hosts | grep controller | awk '{print $1}')
netmask1=$(ifconfig | awk '/netmask / {print $4; exit}')
export pref=$(/sbin/ip -o -4 addr | awk 'NR==2 { print substr($4,length($4)-1); exit}')

IFS=. read -r i1 i2 i3 i4 <<< "$ipm1"
IFS=. read -r m1 m2 m3 m4 <<< "$netmask1"
export net="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))"
export net2="$((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$((i4 & m4 | 255-m4))"
export ip1="$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$(((i4 & m4)+1))"
export ipn="$((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$(((i4 & m4 | 255-m4)-1))"
