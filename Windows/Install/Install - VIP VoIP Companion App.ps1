#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "VIP VoIP Companion App"

# Uninstaller Display Name.
$strRegDisplayName = "VIP VoIP Companion"

# Download URL.
$strDownloadURL = "https://vipvoip.co.uk/vipvoipCompanion-latest.msi"

# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\DIT"

# Installer MSI file name.
$strInstallerFileName = "VIPVoIPCompanionAppSetup.msi"

# Installer MSI file location.
$strInstallerLogFile = "$strFolderPath\VIPVoIPCompanionAppInstallLog.txt"
$strDestinationPath = "$strFolderPath\$strInstallerFileName"
#endregion

#region Logic
foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")){
    if($objRegKey.DisplayName -eq $strRegDisplayName){
        Write-Host "[Informational] $strSoftwareName x32 already installed. Exiting."
        Exit 0
    }
}

foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")){
    if($objRegKey.DisplayName -eq $strRegDisplayName){
        Write-Host "[Informational] $strSoftwareName x64 already installed. Exiting."
        Exit 0
    }
}

# If not installed, check for required folder path and create if required.
if(!(Test-Path -PathType container $strFolderPath)) {
    New-Item -ItemType Directory -Path $strFolderPath
}

# Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script. If so, remove existing installer and re-download.
if (Test-Path $strDestinationPath) {
   Remove-Item $strDestinationPath
   Write-Host "[Informational] Removed $strDestinationPath..."
}

try {
    Write-Host "[Informational] Beginning download of $strSoftwareName to $strDestinationPath"
    Invoke-WebRequest -Uri $strDownloadURL -OutFile $strDestinationPath
} catch {
    throw "[Error] Error Downloading - $($_.Exception.Response.StatusCode.value_)"
}
    
try {
    # Start the install
    Write-Host "[Informational] Initiating install of $strSoftwareName..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$strDestinationPath`" /qn /norestart /l `"$strInstallerLogFile`" REBOOT=REALLYSUPPRESS" -Wait -NoNewWindow
} catch {
    throw "[Error] Error installing $strSoftwareName"
}
while($True) {
    Start-Sleep -Seconds 30

    foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")){
        if($objRegKey.DisplayName -eq $strRegDisplayName){
            Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strFolderPath..."
            Write-Host "[Informational] $strSoftwareName x32 already installed. Exiting."
            Exit 0
        }
    }
    
    foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")){
        if($objRegKey.DisplayName -eq $strRegDisplayName){
            Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strFolderPath..."
            Write-Host "[Informational] $strSoftwareName x64 already installed. Exiting."
            Exit 0
        }
    }
}
#endregion