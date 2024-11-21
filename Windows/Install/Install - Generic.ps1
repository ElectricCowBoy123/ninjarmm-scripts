#region Function Delarations
function Get-Property ($Object, $PropertyName, [object[]]$ArgumentList) {
    return $Object.GetType().InvokeMember($PropertyName, 'Public, Instance, GetProperty', $null, $Object, $ArgumentList)
}

function Invoke-Method ($Object, $MethodName, $ArgumentList) {
    return $Object.GetType().InvokeMember($MethodName, 'Public, Instance, InvokeMethod', $null, $Object, $ArgumentList)
}

function funcGetRegistryKeyName{
    param(
        [String]$msipath
    )
    #Write-Host "[Informational] Calling Get Registry Key Name Function with Value $strDestinationPath"
    try { 
        $msiOpenDatabaseModeReadOnly = 0
        $Installer = New-Object -com WindowsInstaller.Installer 
        $Database = Invoke-Method $installer OpenDatabase @($msipath, $msiOpenDatabaseModeReadOnly)
        $View = Invoke-Method $Database OpenView @("SELECT Value FROM Property WHERE Property = 'ProductName'")
        Invoke-Method $view Execute
        $Record = Invoke-Method $View Fetch
    
        if (-not([string]::IsNullOrEmpty($Record))) {
            $displayName = Get-Property $Record StringData @([object[]]@(1))
            Invoke-Method $View Close @()
            return $displayName
        }
    } 
    catch { 
        throw "[Error] Failed to get MSI File Information Exception: $($_.Exception)"
    }
}
#endregion

#region Variable Declarations
# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\DIT"

if($([System.IO.Path]::GetFileName($env:downloadUrl)) -notlike '*.msi*'){
    throw "[Error] Please Provide a Link to a Valid MSI File! Exception: $($_.Exception)"
}

# Installer MSI file location.
$strDestinationPath = "$strFolderPath\$([System.IO.Path]::GetFileName($env:downloadUrl))"
#endregion

#region Logic & Validation

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
    Invoke-WebRequest -Uri $env:downloadUrl -OutFile $strDestinationPath
} catch {
    throw "[Error] Error Downloading - $_.Exception.Response.StatusCode.value_"
}

try {
    # Pull Registry Key Name from MSI
    [String]$strSoftwareName = funcGetRegistryKeyName -msipath $strDestinationPath

    # Trim Whitespace and Linebreaks
    [String]$strSoftwareName = $strSoftwareName.Trim()
}
catch {
    throw "[Error] Failed to Pull Registry Key Name from MSI Exception $($_.Exception)"
}

# Check if it's already installed.
$boolIsInstalled32 = $False
$boolIsInstalled64 = $False

foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
    if($objRegKey.DisplayName -like "*$strSoftwareName*") {
        $boolIsInstalled32 = $True
    }
}

foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
    if($objRegKey.DisplayName -like "*$strSoftwareName*") {
        $boolIsInstalled64 = $True
    }
}

# If it's already installed, just do nothing.
if ($boolIsInstalled32) {
    Write-Host "[Informational] $strSoftwareName already installed. Exiting."
    Exit 0
}
if ($boolIsInstalled64) {
    Write-Host "[Informational] $strSoftwareName already installed. Exiting."
    Exit 0
}

# Start the install
Write-Host "[Informational] Initiating install of $strSoftwareName..."
try {
    Start-Process msiexec "/i $strDestinationPath /qn /norestart" -wait
}
catch {
    Write-Host "[Error] Failed to install $strSoftwareName."
    Write-Host "[Error] HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$strSoftwareName"
    Write-Host "[Error] HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$strSoftwareName"
    Write-Host "[Error] If not present the installation has failed. Check the log file below for more detials"
    Write-Host "[Error] $strInstallerLogFile"
    Exit 1
}

while($True) {
    Start-Sleep -Seconds 30

    foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
        if($objRegKey.DisplayName -like "*$strSoftwareName*") {
            $boolIsInstalled32 = $True
        }
    }
    
    foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
        if($objRegKey.DisplayName -like "*$strSoftwareName*") {
            $boolIsInstalled64 = $True
        }
    }

    if ($boolIsInstalled64) {
        Write-Host "[Informational] $strSoftwareName successfully installed."
        Remove-Item $strFolderPath -Force -Recurse
        Write-Host "[Informational] Removed installer from $strDestinationPath..."
        Exit 0
    }
    if ($boolIsInstalled32) {
        Write-Host "[Informational] $strSoftwareName successfully installed."
        Remove-Item $strFolderPath -Force -Recurse
        Write-Host "[Informational] Removed installer from $strDestinationPath..."
        Exit 0
    }
}
#endregion