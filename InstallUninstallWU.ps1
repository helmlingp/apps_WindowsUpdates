<#	
  .Synopsis
    Install or Uninstall Windows Quality Update (KB)
  .NOTES
		Created:       May, 2021
		Created by:     Grischa Ernst, 
		Updated by:	    Phil Helmling, @philhelmling
		Organization:   VMware, Inc.
		Filename:       InstallUninstallWU.ps1
	.DESCRIPTION
    Installs or Uninstalls a Windows Quality Update KB, does not wait for WU Schedule.
    Helps with deploying Zero Day/Urgent Patches.
		Also can install all available KBs using -InstallAvailable switch

		Uninstalling updates tries 4 methods in the following order:
		1. PSWindowsUpdate module using Remove-WindowsUpdate. Uses https://www.powershellgallery.com/packages/PSWindowsUpdate Module which is automatically installed
		2. WU API calls
		3. WUSA.EXE
		4. DISM.EXE

		Exit code 0 (zero) is a success for all methods. Exit code 4 (four) is fail for PSWindowsUpdate and WU API methods. Exit code 87 is fail for DISM. Exit code NULL is for WUSA.

		Be aware that cumulative updates can take 30+ minutes to uninstall.

		Install Command: see examples below
		Uninstall Command: .
		Installer Success Exit Code: 0
		When to Call Install Complete: Registry Exists
			Path: HKEY_LOCAL_MACHINE\SOFTWARE\Company
			Value Name: see examples below
			Value Type: see examples below
			Value Data: see examples below

		Exit codes
  .EXAMPLE
    Install a specific KB & Reboot automatically if needed
    Install Command: powershell.exe -ep bypass -file .\InstallUninstallWU.ps1 -InstallKBs KB897894 -Reboot
		When to Call Install Complete: Registry Exists
			Path: HKEY_LOCAL_MACHINE\SOFTWARE\Company
			Value Name: "Install $InstallKB" (replace $InstallKB with KB number)
			Value Type: DWORD
			Value Data: 2
		
    Uninstall a specific KB & do not reboot
    Install Command: powershell.exe -ep bypass -file .\InstallUninstallWU.ps1 -UnInstallKBs KB897894
		When to Call Install Complete: Registry Exists
			Path: HKEY_LOCAL_MACHINE\SOFTWARE\Company
			Value Name: "UnInstall $UnInstallKB" (replace $UnInstallKB with KB number)
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

$ec = ""
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
	write-host "Uninstalling $UnInstallKBs"
	
	foreach ($unInstallKB in $UnInstallKBs){
		$isinstalled = Get-WUHistory -last 30 | Where-Object {$_.KB -eq $UnInstallKB}
		if(!$isinstalled){$ec = 404}

		#Try removal approach 1 - use PSWindowsUpdate
		write-host "Trying PSWindowsUpdate to uninstall update $unInstallKB"
		$name = "Uninstall $UnInstallKB"
		$uninstall = Remove-WindowsUpdate -KBArticleID $UnInstallKB -Confirm:$false -IgnoreReboot -Debuger:$true
		$ec = $uninstall.ResultCode

		#Try removal approach 2 - use WU API directly
		if(!$ec -or $ec -eq 4){
			write-host "Trying WU API to uninstall update $unInstallKB"
			$Searcher = New-Object -ComObject Microsoft.Update.Searcher
			$RemoveCollection = New-Object -ComObject Microsoft.Update.UpdateColl
			#Gather All Installed Updates
			$SearchResult = $Searcher.Search("IsInstalled=1")
			$RemoveKB = $UninstallKB -replace "KB"
			#Add any of the specified KBs to the RemoveCollection
			$SearchResult.Updates | Where-Object { $_.KBArticleIDs -in $RemoveKB } | ForEach-Object { $RemoveCollection.Add($_) }
			if ($RemoveCollection.Count -gt 0) {
				$wuapi = New-Object -ComObject Microsoft.Update.Installer
				$wuapi.Updates = $RemoveCollection
				$wuapi.Uninstall()
				$ec = $wuapi.ResultCode
			}
		}

		#Try removal approach 3 - get uninstall string from registry to use with WUSA.EXE. Needs exe/msi/msu/cab available on disk.
		if(!$ec -or $ec -eq 4){
			write-host "Trying WUSA to uninstall update $unInstallKB"
			$Session = New-Object -ComObject Microsoft.Update.Session
			$UpdateSearcher = $Session.CreateUpdateSearcher()
			$UpdateHistory = $UpdateSearcher.QueryHistory(0,100)
			$upd = $UpdateHistory | where-Object {$_.Title -like "*($UninstallKB)"} | Select-Object -First 1
			[string]$updID = $upd.UpdateIdentity.UpdateID
			$dismpackagespath = "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\*"
			$installpackage = (Get-ItemProperty -Path $dismpackagespath | where-Object { $_.PSChildName -like "Package_for_$UninstallKB*"}).InstallLocation
			if($installpackage){
				$installpackage = $installpackage -replace "\\\\\?\\",""
				if(Test-Path -Path $installpackage){
					$wusapinfo = New-Object System.Diagnostics.ProcessStartInfo
					$wusapinfo.FileName = "WUSA.exe"
					$wusapinfo.RedirectStandardError = $true
					$wusapinfo.RedirectStandardOutput = $true
					$wusapinfo.UseShellExecute = $false
					$wusapinfo.Arguments = "/uninstall $updID /quiet /norestart"
					$wusap = New-Object System.Diagnostics.Process
					$wusap.StartInfo = $wusapinfo
					$wusap.Start() | Out-Null
					$wusap.WaitForExit()
					write-host $wusap.ExitCode
					$ec = $wusap.ExitCode
					#$wusaremove = wusa.exe /uninstall $updID /quiet /norestart
				}
			}
		}

		#Try removal approach 4 - use DISM
		if(!$ec -or $ec -eq 4){
			write-host "Trying DISM to uninstall update $unInstallKB"
			$currentbuild = (Get-ItemProperty	"Registry::HKLM\Software\Microsoft\Windows NT\CurrentVersion").currentbuild
			$ubr = (Get-ItemProperty	"Registry::HKLM\Software\Microsoft\Windows NT\CurrentVersion").ubr
			$osbuild = "$currentbuild.$ubr"
			$searchupdates = dism.exe /online /Get-Packages | findstr "Package_for"
			$updates = $searchupdates -match $unInstallKB -replace "Package Identity : "
			$dismpinfo = New-Object System.Diagnostics.ProcessStartInfo
			$dismpinfo.FileName = "DISM.exe"
			$dismpinfo.RedirectStandardError = $true
			$dismpinfo.RedirectStandardOutput = $true
			$dismpinfo.UseShellExecute = $false
			$dismpinfo.Arguments = "/Online /Remove-Package /PackageName:$updates /quiet /norestart"
			$dismp = New-Object System.Diagnostics.Process
			$dismp.StartInfo = $dismpinfo
			$dismp.Start() | Out-Null
			$dismp.WaitForExit()
			write-host $dismp.ExitCode
			$ec = $dismp.ExitCode
			#DISM.exe /Online /Remove-Package /PackageName:$updates /quiet /norestart
		}
		if(!$ec){$ec = 404}
		$name = "Uninstall $UnInstallKB"
		WriteRegKey -name $name -type "DWORD" -value $ec
	}
	if($Reboot){
		Restart-Computer
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
