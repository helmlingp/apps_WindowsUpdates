# apps_WindowsUpdates
Various Windows Update related scripts and profiles

Quality Update Custom Profiles for Pilot, Ring1, Ring2, Ring3 & VIP Deployment Rings referencing settings
described in "Windows Update Ring Deferral Calculator.xlsx" in same repo. 
Quality Update Custom Profiles prefixed with WU_QU

Feature Update Custom Profiles for Pilot, Ring1, Ring2, Ring3 & VIP Deployment Rings prefixed with WU_FU
Settings described in "Windows Update Ring Deferral Calculator.xlsx"

Delivery Optimization Custom Profiles for two different locations prefixed with WU_DO and referencing
settings in "Windows Update Ring Deferral Calculator.xlsx"

InstallUninstallWU.ps1
Installs or Uninstalls a Windows Update Quality Update KB, does not wait for WU Schedule.
Helps with deploying Zero Day/Urgent Patches.
Uses https://www.powershellgallery.com/packages/PSWindowsUpdate Module which is automatically installed

HideUnhideWU.ps1
Hides or Unhides a Windows Update KB. WU will then install as per existing schedule.
Helps with incompatible updates such as drivers and can be used instead of GUI tool:
https://support.microsoft.com/en-us/windows/hide-windows-updates-or-driver-updates-5df410a1-90f7-b744-0682-43be9c8fa17c
Uses https://www.powershellgallery.com/packages/PSWindowsUpdate Module which is automatically installed