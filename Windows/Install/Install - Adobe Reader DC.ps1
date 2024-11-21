# ENCOUNTERING ISSUE https://stackoverflow.com/questions/50944210/msi-installer-error-msiexec-failed-1603

#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "Adobe Reader"

# Download URL.
$strDownloadURL = ""

# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\DIT"

# Installer CMD file location.
$strDestinationPath = "$strFolderPath/install.cmd"

$strRegDisplayName = "Adobe Acrobat (64-bit)"
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
    Write-Host "[Informational] Beginning download of $strSoftwareName to $strFolderPath/$strSoftwareName.zip"
    Invoke-WebRequest -Uri $strDownloadURL -OutFile "$strFolderPath/$strSoftwareName.zip"
} catch {
    throw "[Error] Error Downloading - $($_.Exception.Response.StatusCode.value_) Exception: $_"
}

# Extract Archive
try {
    Expand-Archive "$strFolderPath\$strSoftwareName.zip" -DestinationPath $strFolderPath
}
catch {
    throw "[Error] Error Expanding Archive"
}
finally {
    # Delete Archive
    try {
        Remove-Item -Path "$strFolderPath\$strSoftwareName.zip" -Force
    }
    catch {
        throw "[Error] Error Removing Archive"
    }
}
#endregion

#Region Begin Install
# Start the install
Write-Host "[Informational] Initiating install of $strSoftwareName..."
try {
    # Execute the batch file
    Start-Process -FilePath $strDestinationPath -NoNewWindow -Wait
}
catch{
    throw "[Error] Error occured during install"
}

while($True){
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