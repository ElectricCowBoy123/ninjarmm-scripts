#region Variable Declaration
# Execute the query and retrieve the active user session
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
# Get the SID (Security Identifier) of the active user
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

$strRegistryPath = "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\WinDirStat"
$strDownloadPath = 'C:\DIT\WinDirStat'
$strURL = ""
$strInstallDir = "C:\Program Files (x86)\WinDirStat"
#endregion

#region Logic
if (-Not(Test-Path $strDownloadPath )) {
    New-Item -Path $strDownloadPath -ItemType Directory | Out-Null
}

try {
    Invoke-WebRequest -Uri $strURL -OutFile "$strDownloadPath\WinDirStatInstall.zip"
}
catch {
    throw "[Error] There was an error downloading windirstat. $($_.Exception)"
}

Expand-Archive -Path "$strDownloadPath\WinDirStatInstall.zip" -DestinationPath $strDownloadPath

if (-Not(Test-Path $strInstallDir )) {
    New-Item -Path $strInstallDir -ItemType Directory | Out-Null
}

Copy-Item -Path "$strDownloadPath\Uninstall.exe" -Destination $strInstallDir
Copy-Item -Path "$strDownloadPath\windirstat.chm" -Destination $strInstallDir
Copy-Item -Path "$strDownloadPath\windirstat.exe" -Destination $strInstallDir

<#
# Uninstaller doesn't remove desktop icons lets leave this out for now

[String]$homeFolder = "C:\Users\" + $($strActiveUser -replace '.*\\')

$WshShell = New-Object -comObject WScript.Shell
$objShortcut = $WshShell.CreateShortcut("$homeFolder\Desktop\WinDirStat.lnk")
$objShortcut.TargetPath = "$strInstallDir\windirstat.exe"
$objShortcut.Save()
#>

$objShortcut = $WshShell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\WinDirStat.lnk")
$objShortcut.TargetPath = "$strInstallDir\windirstat.exe"
$objShortcut.Save()

if (-not (Test-Path $strRegistryPath)) {
    New-Item -Path $strRegistryPath -Force
}

New-ItemProperty -Path $strRegistryPath -Name "UninstallString" -PropertyType ExpandString -Value "C:\Program Files (x86)\WinDirStat\Uninstall.exe" -Force
New-ItemProperty -Path $strRegistryPath -Name "InstallLocation" -PropertyType ExpandString -Value "C:\Program Files (x86)\WinDirStat" -Force
New-ItemProperty -Path $strRegistryPath -Name "DisplayName" -PropertyType String -Value "WinDirStat 1.1.2" -Force
New-ItemProperty -Path $strRegistryPath -Name "DisplayIcon" -PropertyType String -Value "C:\Program Files (x86)\WinDirStat\windirstat.exe,0" -Force
New-ItemProperty -Path $strRegistryPath -Name "dwVersionMajor" -PropertyType DWord -Value 0x00000001 -Force
New-ItemProperty -Path $strRegistryPath -Name "dwVersionMinor" -PropertyType DWord -Value 0x00000001 -Force
New-ItemProperty -Path $strRegistryPath -Name "dwVersionRev" -PropertyType DWord -Value 0x00000002 -Force
New-ItemProperty -Path $strRegistryPath -Name "dwVersionBuild" -PropertyType DWord -Value 0x0000004f -Force
New-ItemProperty -Path $strRegistryPath -Name "URLInfoAbout" -PropertyType String -Value "http://windirstat.info/" -Force
New-ItemProperty -Path $strRegistryPath -Name "NoModify" -PropertyType DWord -Value 0x00000001 -Force
New-ItemProperty -Path $strRegistryPath -Name "NoRepair" -PropertyType DWord -Value 0x00000001 -Force

Remove-Item -Path "$strDownloadPath" -Force -Recurse
#endregion