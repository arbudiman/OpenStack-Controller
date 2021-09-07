#!/bin/sh
. /etc/os-release
export distro=$NAME
export versi=$VERSION
export id_versi=$VERSION_ID
export virt=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
export vendor=$(cat /proc/cpuinfo | grep 'vendor' | uniq | awk '{print $3}')
export model_name=$(cat /proc/cpuinfo | grep 'model name' | uniq | awk '{print $4 $5 $6 $7 $8 $9}')
export jml_prosesor=$(cat /proc/cpuinfo | grep processor | wc -l)
export jml_core=$(cat /proc/cpuinfo | grep 'core id')
