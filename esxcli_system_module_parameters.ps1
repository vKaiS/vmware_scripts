#!/usr/bin/env powershell
# Author: Kai Scharwies
# Site: blog.scharwies.net
#
# This script sets the LLDP-filter parameter for the i40en ESXi kernel module to be able to view LLDP information in vSphere on Intel 10 GbE Quad NICs
# http://www.vexpertconsultancy.com/2018/05/lldp-not-working-with-dell-poweredge-intel-x710-10gb-cards/

param
  (
    #[parameter(Position=0)]
    [String]$hosts=$(throw "Please provide target ESXi hosts. Usage Example: .\esx_system.module.parameters.set.ps1 172.16.11.101,esx2")
  )

$esxcredential = Get-Credential -UserName "root" -Message "Enter root password"

foreach ($esx in $hosts.split(" ")) {

	"##### Opening connection to $esx"

	Connect-VIServer $esx -Credential $esxcredential

	$esxcli = Get-VMHost | Get-EsxCli -V2

	$Parameters = $esxcli.system.module.parameters.set.CreateArgs()

	$Parameters['module'] = 'i40en'

	$Parameters['parameterstring'] = 'LLDP=0,0,0,0'

	$esxcli.system.module.parameters.set.Invoke($Parameters)
	
	"##### Closing connection"
	
	Disconnect-VIServer $esx -Confirm:$false
}
