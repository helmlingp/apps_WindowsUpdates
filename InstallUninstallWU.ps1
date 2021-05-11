<#	
  .Synopsis
    Uninstall or Install Windows Update Quality Update (KB)
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
    Install a KB
    powershell.exe -ep bypass -file .\InstallUninstallWU.ps1 -InstallKBs KB897894

    Uninstall a KB
    powershell.exe -ep bypass -file .\InstallUninstallWU.ps1 -UnInstallKBs KB897894
#>


param (
[Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$InstallKBs=$script:InstallKBs,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$UnInstallKBs=$script:UnInstallKBs
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
    Get-WindowsUpdate -KBArticleID $InstallKBs -Install -AcceptAll -AutoReboot
}

if($UnInstallKBs){
    #Call PSWindowsUpdate module
    Remove-WindowsUpdate -KBArticleID $UnInstallKBs -AcceptAll -NoRestart -WUSAMode
}
