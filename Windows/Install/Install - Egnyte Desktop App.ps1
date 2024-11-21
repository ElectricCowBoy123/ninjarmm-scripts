#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "Egnyte"
# Uninstaller Display Name.
$strRegDisplayName = "Egnyte Desktop App"
# Download URL.
$strDownloadURL = "https://egnyte-cdn.egnyte.com/egnytedrive/win/en-us/3.17.2/EgnyteDesktopApp_3.17.2_145.msi"
# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\DIT"
# Installer MSI file name.
$strInstallerFileName = "EgnyteDesktopApp_3.17.2_145.msi"
# Installer MSI file location.
$strDestinationPath = "$strFolderPath\$strInstallerFileName"
# Installer Log File.
$strInstallerLogFile = "$strFolderPath\EgnyteDesktopAppInstallLog.txt"
# Check if it's already installed.
$boolIsInstalled32 = $False
$boolIsInstalled64 = $False
#endregion

#region Validation
foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
    if($objRegKey.DisplayName -eq $strRegDisplayName) {
        $boolIsInstalled32 = $True
    }
}

foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
    if($objRegKey.DisplayName -eq $strRegDisplayName) {
        $boolIsInstalled64 = $True
    }
}

# If it's already installed, just do nothing.
if ($boolIsInstalled32) {
    Write-Output "[Informational] $strSoftwareName already installed. Exiting."
    Exit 0
}
if ($boolIsInstalled64) {
    Write-Output "[Informational] $strSoftwareName already installed. Exiting."
    Exit 0
}

# If not installed, check for required folder path and create if required.
if(!(Test-Path -PathType container $strFolderPath)) {
      New-Item -ItemType Directory -Path $strFolderPath
}

# Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script. If so, remove existing installer and re-download.
if (Test-Path $strDestinationPath) {
   Remove-Item $strDestinationPath
   Write-Output "[Informational] Removed $strDestinationPath..."
}
#endregion

#region Logic
try {
    Write-Output "[Informational] Beginning download of $strSoftwareName to $strDestinationPath"
    Invoke-WebRequest -Uri $strDownloadURL -OutFile $strDestinationPath
} catch {
    Write-Output "[Error] Error Downloading - $_.Exception.Response.StatusCode.value_"
    Write-Output $_
    Exit 1
}

# Start the install
Write-Output "[Informational] Initiating install of $strSoftwareName..."
try {
    Start-Process msiexec "/i $strDestinationPath /qn /norestart" -wait
}
catch {
    Write-Output "[Error] Failed to install $strSoftwareName."
    Write-Output "[Error] HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$strRegDisplayName"
    Write-Output "[Error] HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$strRegDisplayName"
    Write-Output "[Error] If not present the installation has failed. Check the log file below for more detials"
    Write-Output "[Error] $strInstallerLogFile"
    Exit 1
}

while($True) {
    Start-Sleep -Seconds 30

    foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
        if($objRegKey.DisplayName -eq $strRegDisplayName) {
            $boolIsInstalled32 = $True
        }
    }
    
    foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
        if($objRegKey.DisplayName -eq $strRegDisplayName) {
            $boolIsInstalled64 = $True
        }
    }

    if ($boolIsInstalled64) {
        Write-Output "[Informational] $strSoftwareName successfully installed."
        Remove-Item $strDestinationPath
        Write-Output "[Informational] Removed installer from $strDestinationPath..."
        Exit 0
    }
    if ($boolIsInstalled32) {
        Write-Output "[Informational] $strSoftwareName successfully installed."
        Remove-Item $strDestinationPath
        Write-Output "[Informational] Removed installer from $strDestinationPath..."
        Exit 0
    }
}
#endregion