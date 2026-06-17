<#	
  .Synopsis
    Hide or Unhide Windows Update Quality Update (KB)
  .NOTES
	Created:   	    March, 2021
    Created by:     Grischa Ernst, 
	Updated by:	    Phil Helmling, @philhelmling
	Organization:   VMware, Inc.
	Filename:       HideUnhideWU.ps1
    Updated:        October, 2021
	.DESCRIPTION
    Hides or Unhides a Windows Update KB. WU will then install as per existing schedule.
    Helps with incompatible updates such as drivers and can be used instead of GUI tool:
    https://support.microsoft.com/en-us/windows/hide-windows-updates-or-driver-updates-5df410a1-90f7-b744-0682-43be9c8fa17c

    Uses https://www.powershellgallery.com/packages/PSWindowsUpdate Module which is automatically installed.

    Works as self-contained script accepting parameters or using environment variables provided by Workspace ONE Scripts.

    Workspace ONE Application Parameters
    *** Hide KB
    Install: powershell.exe -ep bypass -file .\HideUnhideWU.ps1 -HideKBs KBARTICLEID
    Uninstall: Two options exist for uninstall:
        1 - do nothing, 
        2 - unhide the update -> powershell.exe -ep bypass -file .\HideUnhideWU.ps1 -UnhideKBs KBARTICLEID
    When to Call Install Complete use Custom Script TestHideUnhideWU.ps1 in the same repo.
        Identify Application By: Using Custom Script
        Script Type: Powershell
        Command to run script: powershell.exe -ep bypass -file .\TestHideUnhideWU.ps1 -HideKBs KBARTICLEID
        Success Exit Code: 0
    
        **** IMPORTANT ****
        -HideKBs KBARTICLEID parameter must match the Install Command -HideKBs KBARTICLEID parameter
    
    *** Unhide KB
    Install: powershell.exe -ep bypass -file .\HideUnhideWU.ps1 -UnhideKBs KBARTICLEID
    Uninstall: .
    When to Call Install Complete use Custom Script TestHideUnhideWU.ps1 in the same repo.
        Identify Application By: Using Custom Script
        Script Type: Powershell
        Command to run script: powershell.exe -ep bypass -file .\TestHideUnhideWU.ps1 -UnhideKBs KBARTICLEID
        Success Exit Code: 0
    
        **** IMPORTANT ****
        -UnhideKBs KBARTICLEID parameter must match the Install Command -UnhideKBs KBARTICLEID parameter
  .EXAMPLE
    Hide a KB from being approved. 
    powershell.exe -ep bypass -file .\HideUnhideWU.ps1 -HideKBs KB897894

    Unhide KB so device can approve and install
    powershell.exe -ep bypass -file .\HideUnhideWU.ps1 -UnhideKBs KB897894
#>

param (
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$HideKBs=$HideKBs,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$UnhideKBs=$UnhideKBs
)

if ($HideKBs) {}else{$HideKBs=$env:HideKBs}
if ($UnhideKBs) {}else{$UnhideKBs=$env:UnhideKBs}

# First, check if the final goal—the module—is already installed.
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    
    Write-Host "PSWindowsUpdate module not found. Beginning installation process..."

    # --- Prerequisite Check: NuGet Provider ---
    # This check only runs if the module needs to be installed.
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Host "Prerequisite 'NuGet' is missing. Installing NuGet provider..."
        Install-PackageProvider -Name NuGet -Force
    }

    # --- Module Installation ---
    # Now that the prerequisite is confirmed, install the main module.
    Write-Host "Installing PSWindowsUpdate module..."
    Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
}

# --- Import Module ---
# This line runs regardless, ensuring the module is loaded into the current session.
Import-Module -Name PSWindowsUpdate -MinimumVersion 2.2.0.2
Write-Host "PSWindowsUpdate module is ready to use."

if($HideKBs){
    #Call PSWindowsUpdate module
    #Hide-WUUpdate -KBArticleID $HideKBs -Hide -Confirm:$false
    Hide-WindowsUpdate -KBArticleID $HideKBs -AcceptAll
}

if($UnhideKBs){
    #Call PSWindowsUpdate module
    #UnHide-WindowsUpdate -KBArticleID $UnhideKBs -Confirm:$false
    Show-WindowsUpdate -KBArticleID $UnhideKBs -AcceptAll
}
