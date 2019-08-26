#!/usr/bin/env powershell
# Author: Kai Scharwies
# Site: blog.scharwies.net
#
# This script uploads a file to one or more ESXi hosts

Param
  (
     [parameter(Position=0)]
     [String]
     $hosts=$(throw "Please provide target ESXi hosts. Usage Example: .\esx_file_upload.ps1 172.16.11.101,esx2")
  )

$esxcredential = Get-Credential -UserName "root" -Message "Enter root password"
$datastorename = "datastore1"
$esxfile = "ESXi670-201906002.zip"
$filelocation = "C:\Users\Kai\Downloads\"+$esxfile

foreach ($esx in $hosts.split(",")) {

	"##### Opening connection to $esx"

	Connect-VIServer $esx -Credential $esxcredential
	
	"##### Uploading file"

	$datastore = Get-VMHost | Get-Datastore $datastorename
	New-PSDrive -Location $datastore -Name ds -PSProvider VimDatastore -Root "\"
	Copy-DatastoreItem -Item $filelocation -Destination ds:\
	Remove-PSDrive -Name ds

	"##### Closing connection"
	
	Disconnect-VIServer $esx -Confirm:$false
  
}
