#region Declaration & Validation
# Execute the query and retrieve the active user session
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName

# Get the SID (Security Identifier) of the active user
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

# Check if registry flag key exists
if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT")) {
    New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Force
}
  
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try {
    [string]$strDPSVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'DPS').DPS
} catch {
    $strDPSVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference
#endregion

#region Logic
if($strDPSVal -ne '1'){
    try {
        # Disable NIC power saving on all interfaces
        $objAdapters = Get-NetAdapter -Physical | Get-NetAdapterPowerManagement
        foreach ($objAdapter in $objAdapters){
            $objAdapter.AllowComputerToTurnOffDevice = 'Disabled'
            $objAdapter | Set-NetAdapterPowerManagement
        }
    }
    catch {
        throw "[Error] Exception occured trying to enable NIC power saving $($_.Exception)"
    }
    
    try {
        # Disable generic power saving, set high performance powerplan
        $objP = Get-CimInstance -Name root\cimv2\power -Class win32_PowerPlan -Filter "ElementName = 'High Performance'"      
        & powercfg /setactive ([string]$objP.InstanceID).Replace("Microsoft:PowerPlan\{","").Replace("}","")
    }
    catch {
        throw "[Error] Exception occured trying to enable generic power saving $($_.Exception)"
    }
    
    try {
        # Disable fast boot
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled -Value 0
    }
    catch {
        throw "[Error] Exception occured trying to disable fast boot $($_.Exception)"
    }

    New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'DPS' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}
if($strDPSVal -eq '1'){
    Write-Host "[Informational] Disable Power Saving & Fast Boot Script already ran!"
    exit 0
}
#endregion