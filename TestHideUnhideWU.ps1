<#
.Synopsis
    Used as When to Call Install Complete custom script for HideUnhideWU.ps1
 .NOTES
    Created:   	    October, 2021
    Created by:	    Phil Helmling, @philhelmling
    Organization:   VMware, Inc.
    Filename:       TestHideUnhideWU.ps1
    GitHub:         https://github.com/helmlingp/apps_WindowsUpdates
.DESCRIPTION
    Used to test if a KB is hidden or not. Used in conjunction with HideUnhideWU.ps1 in same repo for "When to Call Install Complete" logic.

    When to Call Install Complete:
        Identify Application By: Using Custom Script
        Script Type: Powershell
        Command to run script: powershell.exe -ep bypass -file .\TestHideUnhideWU.ps1 -HideKBs KBARTICLEID
        Success Exit Code: 0
    
        **** IMPORTANT ****
        -HideKBs KBARTICLEID parameter must match the Install Command -HideKBs KBARTICLEID parameter
#>
param (
[Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$HideKBs=$script:HideKBs,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$UnhideKBs=$script:UnhideKBs
)
Try { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop } Catch {}

$ec = 1

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
 
Import-Module -Name "PSwindowsUpdate" -MinimumVersion 2.2.0.2

if($HideKBs){$KB = $HideKBs}
if($UnhideKBs){$KB = $UnhideKBs}

$ishidden = Get-WindowsUpdate -IsHidden
foreach ($hiddenkb in $ishidden.KB) {
    if ($hiddenkb -eq $KB) {
        $ec = 0
    }
}

exit $ec