<#	
  .Synopsis
    Install or Uninstall Windows Quality Update (KB)
  .NOTES
	Created:   	    May, 2021
    Created by:     Grischa Ernst, 
	Updated by:	    Phil Helmling, @philhelmling
	Organization:   VMware, Inc.
	Filename:       InstallUninstallWU.ps1
	.DESCRIPTION
    Installs or Uninstalls a Windows Quality Update KB, does not wait for WU Schedule.
    Helps with deploying Zero Day/Urgent Patches.
	Also can install all available KBs.

    Uses https://www.powershellgallery.com/packages/PSWindowsUpdate Module which is automatically installed
    
	Install Command: see examples below
	Uninstall Command: .
	Installer Success Exit Code: 0
	When to Call Install Complete: Registry Exists
		Path: HKEY_LOCAL_MACHINE\SOFTWARE\Company
		Value Name: see examples below
		Value Type: see examples below
		Value Data: see examples below
  .EXAMPLE
    Install a specific KB & Reboot automatically if needed
    Install Command: powershell.exe -ep bypass -file .\InstallUninstallWU.ps1 -InstallKBs KB897894 -Reboot
	When to Call Install Complete: Registry Exists
		Path: HKEY_LOCAL_MACHINE\SOFTWARE\Company
		Value Name: "Install $InstallKB"
		Value Type: DWORD
		Value Data: 2
		
    Uninstall a specific KB & do not reboot
    Install Command: powershell.exe -ep bypass -file .\InstallUninstallWU.ps1 -UnInstallKBs KB897894
	When to Call Install Complete: Registry Exists
		Path: HKEY_LOCAL_MACHINE\SOFTWARE\Company
		Value Name: "UnInstall $UnInstallKB"
		Value Type: DWORD
		Value Data: 2
		
    Install all available updates and reboot if needed
    Install Command: powershell.exe -ep bypass -file .\InstallUninstallWU.ps1 -InstallAvailable -Reboot
	When to Call Install Complete: Registry Exists
		Path: HKEY_LOCAL_MACHINE\SOFTWARE\Company
		Value Name: "Install All Available Updates"
		Value Type: String
#>


param (
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$InstallKBs=$script:InstallKBs,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$UnInstallKBs=$script:UnInstallKBs,
    [switch] $InstallAvailable,
    [Switch] $Reboot
)

Function WriteRegKey {
	Param (
		[Parameter(Mandatory=$true)]
		$name,
		[Parameter(Mandatory=$true)]
		$type,
		[Parameter(Mandatory=$true)]
		$value
	)
	$key = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Company";
	if(Get-Item -Path $key -ErrorAction Ignore){$true}else{New-Item -Path $key -ErrorAction SilentlyContinue -Force};
	New-ItemProperty $key -Name $name -Type $type -Value $value -ErrorAction SilentlyContinue -Force;
}
	
Try { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop } Catch {}
 
$PackageProvider = Get-PackageProvider -ListAvailable
$NuGetInstalled = $false
 
foreach ($item in $PackageProvider.name){
    if($item -eq "NuGet")
    {
        $NuGetInstalled = $true
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
 
Import-Module -Name "PSwindowsUpdate" -MinimumVersion 2.2.0.2

if($InstallKBs){
    #Call PSWindowsUpdate module
    if($Reboot){
        foreach ($InstallKB in $InstallKBs){
			Get-WindowsUpdate -KBArticleID $InstallKB -Install -AcceptAll -AutoReboot
			$name = "Install $InstallKB"
			$isinstalled = Get-WUHistory -last 30 | Where-Object {$_.KB -eq $installKB}
            $ec = $isinstalled.ResultCode
			WriteRegKey -name $name -type "DWORD" -value $ec
		}
    } else {
        foreach ($InstallKB in $InstallKBs){
			Get-WindowsUpdate -KBArticleID $InstallKB -Install -AcceptAll -IgnoreReboot
			$name = "Install $InstallKB"
			$isinstalled = Get-WUHistory -last 30 | Where-Object {$_.KB -eq $installKB}
            $ec = $isinstalled.ResultCode
			WriteRegKey -name $name -type "DWORD" -value $ec
		}
    }
}

if($UnInstallKBs){
    #Call PSWindowsUpdate module
    if($Reboot){
		foreach ($unInstallKB in $UnInstallKBs){
			$uninstall = Remove-WindowsUpdate -KBArticleID $UnInstallKB -Confirm:$false -AutoReboot
			$name = "Uninstall $UnInstallKB"
			$ec = $uninstall.ResultCode
			WriteRegKey -name $name -type "DWORD" -value $ec
		}
    } else {
        foreach ($unInstallKB in $UnInstallKBs){
			$uninstall = Remove-WindowsUpdate -KBArticleID $UnInstallKB -Confirm:$false -IgnoreReboot
			$name = "Uninstall $UnInstallKB"
			$ec = $uninstall.ResultCode
			WriteRegKey -name $name -type "DWORD" -value $ec
		}
    }
}

if($InstallAvailable){
    #Call PSWindowsUpdate module
    if($Reboot){
        Get-WindowsUpdate -Install -AcceptAll -AutoReboot
		#Write Reg Key to mark success
		$name = "Install All Available Updates"
		$date = Get-Date
		$value = $date.ToString()
		WriteRegKey -name $name -type "String" -value $value
    } else {
        Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
		#Write Reg Key to mark success
		$name = "Install All Available Updates"
		$date = Get-Date
		$value = $date.ToString()
		WriteRegKey -name $name -type "String" -value $value
    }
}
