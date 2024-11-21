#region Parameter Declaration & Validation
[string]$strAppDisplayName = $env:appname
# Retrieve the uninstall string for the specified application
$strUninstallString32 = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strAppDisplayName }).UninstallString
$strQuietUninstallString32 = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strAppDisplayName }).QuietUninstallString
$strUninstallString64 = (Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strAppDisplayName }).UninstallString
$strQuietUninstallString64 = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strAppDisplayName }).QuietUninstallString
#endregion

#region Logic
if ($strUninstallString32 -or $strQuietUninstallString32 -or $strUninstallString64 -or $strQuietUninstallString64) {

    if($strQuietUninstallString64){ Write-Output "[Informational] Found x64 quiet uninstall string: $strQuietUninstallString64" }
    if($strQuietUninstallString32){ Write-Output "[Informational] Found x32 quiet uninstall string: $strQuietUninstallString32" }
    if($strUninstallString32){ Write-Output "[Informational] Found x32 uninstall string: $strUninstallString32" }
    if($strUninstallString64){ Write-Output "[Informational] Found x64 uninstall string: $strUninstallString64" }

    # Modify the uninstall string to run silently (typically by adding /quiet or /qn, this may vary depending on the installer type)
    if ($strUninstallString32 -like "*.msi*") {
        if($strQuietUninstallString32) {
            try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strQuietUninstallString32" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strAppDisplayName." }
        }
        else {
            try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strUninstallString32" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strAppDisplayName." }
        }
        Write-Output "[Informational] Successfully uninstalled $strAppDisplayName."
        exit 0
    } 
    if ($strUninstallString32 -like "*.exe*") {
        if($strQuietUninstallString32) {
            try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strQuietUninstallString32" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strAppDisplayName." }
        }
        else {
            try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strUninstallString32" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strAppDisplayName." }
        }
        Write-Output "[Informational] Successfully uninstalled $strAppDisplayName."
        exit 0
    }

    if ($strUninstallString64 -like "*.msi*") {
        if($strQuietUninstallString64){
            try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strQuietUninstallString64" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strAppDisplayName." }
        }
        else{
            try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strUninstallString64" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strAppDisplayName." }
        }
        Write-Output "[Informational] Successfully uninstalled $strAppDisplayName."
        exit 0
    } 
    if ($strUninstallString64 -like "*.exe*") {
        if($strQuietUninstallString64){
            try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strQuietUninstallString64" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strAppDisplayName." }
        }
        else{
            
            try{ Start-Process -FilePath "cmd.exe" -ArgumentList "/c $strUninstallString64" -Wait -NoNewWindow } catch{ throw "[Error] Failed to uninstall $strAppDisplayName." }
        }
        Write-Output "[Informational] Successfully uninstalled $strAppDisplayName."
        exit 0
    }
    else {
        throw "[Error] No valid uninstall string could be found for $strAppDisplayName."
    }
}
else {
    throw "[Error] Application with display name '$strAppDisplayName' not found in the registry."
}
#endregion