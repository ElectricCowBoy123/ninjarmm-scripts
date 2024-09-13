#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "ConnectWise Manage"
# Uninstaller Display Name.
$strRegDisplayName = "ConnectWise Manage Client 64-bit"
# Download URL.
$strDownloadURL = "https://university.connectwise.com/install/2022.2.2/ConnectWise-Manage-Internet-Client-x64.msi"
# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\DIT"
# Installer MSI file name.
$strInstallerFileName = "ConnectWise-Manage-Internet-Client-x64.msi"
# Installer MSI file location.
$strDestinationPath = "$strFolderPath\$strInstallerFileName"
#endregion

#region Check If Already Installed
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
if(!(Test-Path -Path $strFolderPath)){
    New-Item -ItemType Directory -Path $strFolderPath
}

# Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script. If so, remove existing installer and re-download.
if (Test-Path -Path $strFolderPath) {
    Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
    Write-Host "[Informational] Removed $strFolderPath..."
}
#endregion

#region Download Software
try {
    Write-Output "Beginning download of $strSoftwareName to $strDestinationPath"
    Invoke-WebRequest -Uri $strDownloadURL -OutFile $strDestinationPath
} catch {
    throw "[Error] Error Downloading - $($_.Exception.Response.StatusCode.value_)"
}
#endregion  
 
#region Begin Install
try {
    # Start the install
    Write-Output "[Informational] Initiating install of $strSoftwareName..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$strDestinationPath`" /quiet /norestart" -Wait -NoNewWindow
} catch {
    throw "[Error] Error installing $strSoftwareName Exception: $($_.Exception)"
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