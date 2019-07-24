#!/bin/bash
# Author: Kai Scharwies
# Site: blog.scharwies.net
#
# Based on deploy_vcsa6_mgmt_to_vc.sh by:
# Author: William Lam
# Site: www.virtuallyghetto.com
# Reference: http://www.virtuallyghetto.com/2015/01/ultimate-automation-guide-to-deploying-vcsa-6-0-part-4-vcenter-server-management-node.html

OVFTOOL="/Applications/VMware OVF Tool/ovftool"
VCSA_OVA="~/Downloads/VMware-Cloud-Builder-2.1.0.0-14172583_OVF10.ova"

ESXI_USERNAME=root
ESXI_PASSWORD=VMware123!
ESXI_HOST=mini.primp-industries.com
VM_NETWORK="VM Network"
VM_DATASTORE=datastore1

# Configurations for VC Management Node
CB_VMNAME=cloud-builder
#SKU: Deployment Architecture. Options: vcf, vcf-vxrail, vvd
CB_SKU=vcf
CB_ADMIN_USER=admin
CB_ADMIN_PASSWORD="W2V4yACKidQ#"
CB_ROOT_PASSWORD="qOBg02#t93K1"
CB_HOSTNAME="cloud-builder"
CB_IP="172.16.11.250"
CB_NETWORK_MASK="255.255.255.0"
CB_GATEWAY="172.16.11.1"
#WARNING: Do not specify more than two entries for DNS
CB_DNS="172.16.11.4, 172.16.11.5"
CB_DOMAIN="rainpole.local"
CB_SEARCHPATH="rainpole.local, sfo01.rainpole.local"
CB_NTP_SERVERS="ntp0.rainpole.local,ntp1.rainpole.local"


### DO NOT EDIT BEYOND HERE ###

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }
VAR=$("${OVFTOOL}" --version | awk '{print $3}')
if [ $(version $VAR) -ge $(version "4.1.0") ]; then

	echo -e "\nDeploying Cloud Builder ${CB_VMNAME} ..."
	"${OVFTOOL}" --acceptAllEulas --skipManifestCheck --X:injectOvfEnv --allowExtraConfig --X:enableHiddenProperties --X:waitForIp --sourceType=OVA --powerOn \
	"--net:Network 1=${VM_NETWORK}" --datastore=${VM_DATASTORE} --diskMode=thin --name=${CB_VMNAME} \
	"--prop:guestinfo.sku=${CB_SKU}" \
	"--prop:guestinfo.ADMIN_USERNAME=${CB_ADMIN_USER}" \
	"--prop:guestinfo.ADMIN_PASSWORD=${CB_ADMIN_PASSWORD}" \
	"--prop:guestinfo.ROOT_PASSWORD=${CB_ROOT_PASSWORD}" \
	"--prop:guestinfo.hostname=${CB_HOSTNAME}" \
	"--prop:guestinfo.ip0=${CB_IP}" \
	"--prop:guestinfo.netmask0=${CB_NETWORK_MASK}" \
	"--prop:guestinfo.gateway=${CB_GATEWAY}" \
	"--prop:guestinfo.DNS=${CB_DNS}" \
	"--prop:guestinfo.domain=${CB_DOMAIN}" \
	"--prop:guestinfo.searchpath=${CB_SEARCHPATH}" \
	"--prop:guestinfo.ntp=${CB_NTP_SERVERS}" \
	${VCSA_OVA} "vi://${ESXI_USERNAME}:${ESXI_PASSWORD}@${ESXI_HOST}"

	echo "Checking to see if the Cloud Builder endpoint https://${CB_IP}/ is ready ..."
	until [[ $(curl --connect-timeout 30 -s -o /dev/null -w "%{http_code}" -i -k https://${CB_IP}/login) -eq 200 ]];
	do
		echo "Not ready, sleeping for 30sec"
		sleep 30
	done

	echo "Cloud Builder Management Node (${CB_VMNAME}) is now ready!"
	exit 0
else
	echo "This script requires ovftool 4.1.0 or higher..."
	exit 1
fi
