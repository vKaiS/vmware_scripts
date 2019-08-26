#!/usr/bin/env powershell
# Author: Kai Scharwies
# Site: blog.scharwies.net
#
# This script sets the ESXi kernel parameter ignoreHeadless to TRUE to workaround a problem on older hardware, e.g. Sun x86 servers, as described here:
# https://talesfromthedatacenter.com/2016/02/esxi-6-install-stuck-on-relocating-modules-and-starting-up-the-kernel/

Param
  (
     [parameter(Position=0)]
     [String]
     $hosts=$(throw "Please provide target ESXi hosts. Usage Example: .\esx_set_kernelparam_ignoreheadless.ps1 172.16.11.101,esx2")
  )

$esxcredential = Get-Credential -UserName "root" -Message "Enter root password"

foreach ($esx in $hosts.split(",")) {

	"##### Opening connection to $esx"

	Connect-VIServer $esx -Credential $esxcredential

	$esxcli = Get-VMHost | Get-EsxCli -V2

	"##### Invoking kernel setting ignoreHeadless=TRUE"
	
	$parmssun = @{
		setting = "ignoreHeadless"
		value = "TRUE"
	}

	$esxcli.system.settings.kernel.set.Invoke($parmssun)
}
