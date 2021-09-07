#!/bin/sh
export ipstatus=$(cat /etc/network/interfaces | grep static | awk '{print $2; exit}')
#export ipcontroller=$(ifconfig $ipstatus | awk '/inet / {print $2; exit}')
export ipcontroller=$(cat /etc/hosts | grep controller | awk '{print $1}')
export ethManual=$(cat /etc/network/interfaces | grep manual | awk '{print $2; exit}')
