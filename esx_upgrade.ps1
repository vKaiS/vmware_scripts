#!/usr/bin/env powershell
# Author: Kai Scharwies
# Site: blog.scharwies.net
#
# This script installs an update depot file directly on ESXi hosts. The zip file should already be present on a local/NFS datastore.

Param
  (
     [parameter(Position=0)]
     [String]
     $hosts=$(throw "Please provide target ESXi hosts. Usage Example: .\esx_upgrade.ps1 172.16.11.101,esx2")
  )

$esxcredential = Get-Credential -UserName "root" -Message "Enter root password"
$datastorename = "Public"
$esxfile = "VMware-ESXi-7.0b-16324942-depot.zip"
$esxprofile = "ESXi-7.0b-16324942-standard"

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

	"##### Putting host into maintenance mode"

	Get-VMHost | Set-VMHost -State Maintenance

	"##### Rebooting host"
	
	Get-VMHost | Restart-VMHost -Confirm:$false

	"##### Closing connection"
	
	Disconnect-VIServer $esx -Confirm:$false
}
