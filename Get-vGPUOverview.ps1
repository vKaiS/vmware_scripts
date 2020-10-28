#!/usr/bin/env powershell
# Author: Kai Scharwies
# Site: blog.scharwies.net
#
# This script retrieves all VDIs from vCenter and outputs their VM name & profile (e.g. grid_p40-1b) sorted by cluster, host and GPU (PCI-ID)
# Cluster with no GPUs are ignored
#
# Based on Get-vGPUOverview.ps1 by:
# Author: Sander van Gelderen
# Site: www.vblog.nl
# Reference: https://www.vblog.nl/vmware-powercli-vgpu-overview/

function Get-vGPUOverview {

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

			$VDIs = $vmhost.ExtensionData.Config.GraphicsInfo[$g].vm
			if(!$VDIs){
				$object = New-Object PSObject
				Add-Member -InputObject $object NoteProperty HostName $vmhost.Name
				Add-Member -InputObject $object NoteProperty CardType $vmhost.ExtensionData.Config.GraphicsInfo[$g].DeviceName
				Add-Member -InputObject $object NoteProperty CardId $vmhost.ExtensionData.Config.GraphicsInfo[$g].PciId
				Add-Member -InputObject $object NoteProperty VDIName 'NoVDIs'
				Add-Member -InputObject $object NoteProperty ProfileType 'NoProfiles'
				$output+= $object
			}
			
			foreach($vdi in $VDIs){
				$vm = $VMs | ? {$_.id -match $vdi.Value}
				$vGPUDevice = $VM.ExtensionData.Config.hardware.Device | where {$_.Backing.Vgpu}
				$ProfileType = $vGPUDevice.Backing.Vgpu
				$object = New-Object PSObject
				Add-Member -InputObject $object NoteProperty HostName $vmhost.Name
				Add-Member -InputObject $object NoteProperty CardType $vmhost.ExtensionData.Config.GraphicsInfo[$g].DeviceName
				Add-Member -InputObject $object NoteProperty CardId $vmhost.ExtensionData.Config.GraphicsInfo[$g].PciId
				Add-Member -InputObject $object NoteProperty VDIName $vm.Name
				Add-Member -InputObject $object NoteProperty ProfileType $ProfileType
				$output+= $object
			}
		}
    }
	
	if ($output.length -gt 0) {
		Write-Host ($cluster)
		$output | sort HostName,CardId | ft
	}
}

foreach ($cluster in Get-Cluster) {
	Get-vGPUOverview -Cluster $cluster
}