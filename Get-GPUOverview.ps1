#!/usr/bin/env powershell
# Author: Kai Scharwies
# Site: blog.scharwies.net
#
# This script retrieves all GPU cards (e.g. nVidia Tesla) from vCenter and outputs them sorted by cluster, host and PCI-ID
# Cluster with no GPUs are ignored
#
# Based on Get-vGPUOverview.ps1 by:
# Author: Sander van Gelderen
# Site: www.vblog.nl
# Reference: https://www.vblog.nl/vmware-powercli-vgpu-overview/

function Get-GPUOverview {

    Param (
        $Cluster
    )

    $vmhosts = Get-VMHost -Location $Cluster
    $output=@()
    foreach($vmhost in $vmhosts){
        $VMhost = Get-VMhost $VMhost
        $VMs = get-vmhost -name $vmhost | get-vm
		
		$GPUs = $vmhost.ExtensionData.Config.GraphicsConfig.DeviceType.length
		
		for ($g=0; $g -lt $GPUs; $g++) {
			$object = New-Object PSObject
			Add-Member -InputObject $object NoteProperty HostName $vmhost.Name
			Add-Member -InputObject $object NoteProperty CardType $vmhost.ExtensionData.Config.GraphicsInfo[$g].DeviceName
			Add-Member -InputObject $object NoteProperty CardId $vmhost.ExtensionData.Config.GraphicsInfo[$g].PciId
			$output+= $object
		}
    }

	if ($output.length -gt 0) {
		Write-Host ($cluster)
		$output | sort HostName,CardId | ft
	}
	
	
}

foreach ($cluster in Get-Cluster) {
		Get-GPUOverview -Cluster $cluster
}