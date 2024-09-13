#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "MSPEasyTools"
# Uninstaller Display Name.
$strRegDisplayName = "MSPEasyTools"
# Download URL.
$strDownloadURL = ""
# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\DIT"
# Installer MSI file name.
$strInstallerFileName = "MSPETLaunchersetup.exe"
# Installer MSI file location.
$strDestinationPath = "$strFolderPath\$strInstallerFileName"
#endregion

function Uninstall-Application(){
    param (
        [Parameter(Mandatory)]
        [string]$strRegDisplayName
    )

    # Retrieve the uninstall string for the specified application
    $strUninstallString32 = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strRegDisplayName }).UninstallString
    $strQuietUninstallString32 = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strRegDisplayName }).QuietUninstallString
    $strUninstallString64 = (Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strRegDisplayName }).UninstallString
    $strQuietUninstallString64 = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strRegDisplayName }).QuietUninstallString

    if ($strUninstallString32 -or $strQuietUninstallString32 -or $strUninstallString64 -or $strQuietUninstallString64) {
        if($strQuietUninstallString64){ Write-Output "[Informational] Found x64 quiet uninstall string: $strQuietUninstallString64" }
        if($strQuietUninstallString32){ Write-Output "[Informational] Found x32 quiet uninstall string: $strQuietUninstallString32" }
        if($strUninstallString32){ Write-Output "[Informational] Found x32 uninstall string: $strUninstallString32" }
        if($strUninstallString64){ Write-Output "[Informational] Found x64 uninstall string: $strUninstallString64" }

        # Modify the uninstall string to run silently (typically by adding /quiet or /qn, this may vary depending on the installer type)
        if ($strUninstallString32 -like "*.msi*") {
            if($strQuietUninstallString32) {
                try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strQuietUninstallString32" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strRegDisplayName." }
            }
            else {
                try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strUninstallString32" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strRegDisplayName." }
            }
            Write-Output "[Informational] Successfully uninstalled $strRegDisplayName."
            exit 0
        } 
        if ($strUninstallString32 -like "*.exe*") {
            if($strQuietUninstallString32) {
                try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strQuietUninstallString32" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strRegDisplayName." }
            }
            else {
                try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strUninstallString32" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strRegDisplayName." }
            }
            Write-Output "[Informational] Successfully uninstalled $strRegDisplayName."
            exit 0
        }

        if ($strUninstallString64 -like "*.msi*") {
            if($strQuietUninstallString64){
                try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strQuietUninstallString64" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strRegDisplayName." }
            }
            else{
                try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strUninstallString64" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strRegDisplayName." }
            }
            Write-Output "[Informational] Successfully uninstalled $strRegDisplayName."
            exit 0
        } 
        if ($strUninstallString64 -like "*.exe*") {
            if($strQuietUninstallString64){
                try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strQuietUninstallString64" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strRegDisplayName." }
            }
            else{
                
                try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strUninstallString64" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strRegDisplayName." }
            }
            Write-Output "[Informational] Successfully uninstalled $strRegDisplayName."
            exit 0
        }
        else {
            throw "[Error] No valid uninstall string could be found for $strRegDisplayName."
        }
    }
    else {
        throw "[Error] Application with display name '$strRegDisplayName' not found in the registry."
    }
}

function Delete-Desktop-Icon(){
    foreach($user in (Get-ChildItem -Path "C:\Users\").Name) {
        foreach($dir in (Get-ChildItem -Path "C:\Users\$user" -Attributes H,S,D).Name){
            if($dir -eq 'Desktop'){
                foreach($file in (Get-ChildItem -Path "C:\Users\$user\$dir").Name){
                    if($file -eq "MSPETLauncher.lnk"){
                        Write-Host "$file Exists in 'C:\Users\$user\$dir' deleting!"
                        Remove-Item "C:\Users\$user\$dir\$file" -Force
                    }
                }
            }
            if($dir -like 'OneDrive -*'){
                foreach($file in (Get-ChildItem -Path "C:\Users\$user\$dir").Name){
                    if($file -eq "MSPETLauncher.lnk"){
                        Write-Host "$file Exists in 'C:\Users\$user\$dir' deleting!"
                        Remove-Item "C:\Users\$user\$dir\$file" -Force
                    }
                }
            }
            
        }
    }
}

Write-Host $env:uninstallFlag
if($env:uninstallFlag -ne "1" -and $env:uninstallFlag -ne "0"){
    throw "Invalid value given for UninstallFlag!"
}

if($env:uninstallFlag -eq "1"){
    try {
        Uninstall-Application
    }
    catch {
        throw "Failed to uninstall application! $strRegDisplayName"
    }
    
}

#region Check If Already Installed
foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")){
    if($objRegKey.DisplayName -eq $strRegDisplayName){
        Delete-Desktop-Icon
        Write-Host "[Informational] $strSoftwareName x32 already installed. Exiting."
        Exit 0
    }
}

foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")){
    if($objRegKey.DisplayName -eq $strRegDisplayName){
        Delete-Desktop-Icon
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
    Start-Process $strDestinationPath -ArgumentList '/s' -Wait
} catch {
    throw "[Error] Error installing $strSoftwareName Exception: $($_.Exception)"
}
while($True) {
    Start-Sleep -Seconds 30

    foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")){
        if($objRegKey.DisplayName -eq $strRegDisplayName){
            Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Delete-Desktop-Icon
            Write-Host "[Informational] Removed $strFolderPath..."
            Write-Host "[Informational] $strSoftwareName x32 already installed. Exiting."
            Exit 0
        }
    }
    
    foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")){
        if($objRegKey.DisplayName -eq $strRegDisplayName){
            Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Delete-Desktop-Icon
            Write-Host "[Informational] Removed $strFolderPath..."
            Write-Host "[Informational] $strSoftwareName x64 already installed. Exiting."
            Exit 0
        }
    }
}
#endregion