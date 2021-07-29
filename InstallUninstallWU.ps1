<#	
  .Synopsis
    Install or Uninstall Windows Update Quality Update (KB)
  .NOTES
	Created:   	    May, 2021
    Created by:     Grischa Ernst, 
	Updated by:	    Phil Helmling, @philhelmling
	Organization:   VMware, Inc.
	Filename:       InstallUninstallWU.ps1
	.DESCRIPTION
    Installs or Uninstalls a Windows Update Quality Update KB, does not wait for WU Schedule.
    Helps with deploying Zero Day/Urgent Patches.

    Uses https://www.powershellgallery.com/packages/PSWindowsUpdate Module which is automatically installed
    
  .EXAMPLE
    Install a specific KB & Reboot automatically if needed
    powershell.exe -ep bypass -file .\InstallUninstallWU.ps1 -InstallKBs KB897894 -Reboot

    Uninstall a specific KB & do not reboot
    powershell.exe -ep bypass -file .\InstallUninstallWU.ps1 -UnInstallKBs KB897894

    Install all available updates and reboot if needed
    powershell.exe -ep bypass -file .\InstallUninstallWU.ps1 -InstallAvailable -Reboot
#>


param (
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$InstallKBs=$script:InstallKBs,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$UnInstallKBs=$script:UnInstallKBs,
    [switch] $InstallAvailable,
    [Switch] $Reboot
)
Try { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop } Catch {}
 
$PackageProvider = Get-PackageProvider -ListAvailable
$NuGetInstalled = $false
 
foreach ($item in $PackageProvider.name){
    if($item -eq "NuGet")
    {
        $NuGetInstalled = $tru
    }
}
if($NuGetInstalled = $false){
    Install-PackageProvider NuGet -Force
}else{
    Get-PackageProvider -Name NuGet -Force
    Write-Output "NuGet is already installed"
    }

$ModuleInstalled = Get-Module PSWindowsUpdate
if(!$ModuleInstalled){
    Install-Module -Name PSWindowsUpdate -Force
}else{
    Write-Output "PSWindowsUpdate Module is already installed"
    }
 
Import-Module -Name "PSwindowsUpdate" 

if($InstallKBs){
    #Call PSWindowsUpdate module
    if($Reboot){
        Get-WindowsUpdate -KBArticleID $InstallKBs -Install -AcceptAll -AutoReboot
    } else {
        Get-WindowsUpdate -KBArticleID $InstallKBs -Install -AcceptAll -IgnoreReboot
    }
}

if($UnInstallKBs){
    #Call PSWindowsUpdate module
    if($Reboot){
        Remove-WindowsUpdate -KBArticleID $UnInstallKBs -AcceptAll -AutoReboot -WUSAMode
    } else {
        Remove-WindowsUpdate -KBArticleID $UnInstallKBs -AcceptAll -IgnoreReboot -WUSAMode
    }
}

if($InstallAvailable){
    #Call PSWindowsUpdate module
    if($Reboot){
        Get-WindowsUpdate -Install -AcceptAll -AutoReboot
    } else {
        Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
    }
    
}
