#!/usr/bin/env powershell
# Author: Kai Scharwies
# Site: blog.scharwies.net
#
# This script prepares freshly installed ESXi hosts for either being used by:
#  -VMware Cloud Builder to deploy the VMware Cloud Foundation management workload domain
#  or
#  -VMware SDDC Manager to be commissioned for usage in a VMware Cloud Foundation workload domain

Param
  (
     [parameter(Position=0)]
     [String]
     $hosts=$(throw "Please provide target ESXi hosts. Usage Example: .\esx_vcf_preparation.ps1 172.16.11.101,esx2")
  )

$esxcredential = Get-Credential -UserName "root" -Message "Enter root password"
$datastorename = "datastore1"
$ntpserver = "172.16.11.1"
$dnsserver = "172.16.11.1"
$domainname = "rainpole.local"
$esxfile = "ESXi670-201906002.zip"
$esxprofile = "ESXi-6.7.0-20190604001-standard"

foreach ($esx in $hosts.split(",")) {

	"##### Opening connection to $esx"

	Connect-VIServer $esx -Credential $esxcredential
	$esxcli = Get-VMHost | Get-EsxCli -V2

	"##### Invoking ESXi upgrade"
	
	$parms = @{
		depot = "/vmfs/volumes/$datastorename/"+$esxfile
		profile = $esxprofile
	}

	$esxcli.software.profile.update.Invoke($parms)

	"##### Enabling SSH and setting SSH service policy to 'Start and stop with host'"
	
	Get-VMHost | Get-VmHostService | Where-Object {$_.key -eq "TSM-SSH"} | Start-VMHostService
	Get-VMhost | Get-VmHostService | Where-Object {$_.key -eq "TSM-SSH"} | Set-VMHostService -policy "On"

	"##### Configuring NTP servers $ntpserver and setting NTP service policy to 'Start and stop with host'."

	Get-VMHost | Get-VmHostService | Where-Object {$_.key -eq "ntpd"}
	Get-VMHost | Get-VMHostFirewallException | where {$_.Name -eq "NTP client"}
	Get-VMHost | Add-VMHostNtpServer $ntpserver
	Get-VMHost | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService
	Get-VMhost | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "On"

	"##### Configuring DNS servers $dnsserver and setting domain to $domainname"

	Get-VMHost | Get-VMHostNetwork | Set-VmHostNetwork -DomainName $domainname -DnsAddress $dnsserver

	"##### Setting MTU to 9000"

	Get-VirtualSwitch  | Set-VirtualSwitch -Mtu 9000 -Confirm:$false

	"##### Configuring the default port group 'VM Network' with the same VLAN ID as the 'management network'"

	$mgmtpg = Get-VMHost |Get-VirtualPortGroup -Name "Management Network"
	$vmnetpg = Get-VMHost | Get-VirtualPortGroup -Name "VM Network"
	Set-VirtualPortGroup -VirtualPortGroup $vmnetpg -VLanId $mgmtpg.VLanId

	"##### Putting host into maintenance mode"

	Get-VMHost | Set-VMHost -State Maintenance

	"##### Rebooting host"
	
	Get-VMHost | Restart-VMHost -Confirm:$false

	"##### Closing connection"
	
	Disconnect-VIServer $esx -Confirm:$false
}
