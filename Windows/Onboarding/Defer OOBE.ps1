#region Declaration & Validation 
# Should only run this if the number of accounts on the system is greater than 1
# Execute the query and retrieve the active user session
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName

# Get the SID (Security Identifier) of the active user
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT")) {
    New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Force
}

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try {
    [string]$strDOVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'DO').DO
} catch {
    $strDOVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference
#endregion

#region Logic
if($strDOVal -ne '1'){
    if ((Get-LocalUser | Where-Object { $_.Enabled -eq $True }).Count -gt 1) {
        $objWMAProcs = Get-Process | Where-Object { $_.ProcessName -eq 'WWAHost' } -ErrorAction SilentlyContinue
        if($null -ne $objWMAProcs){
            foreach ($objWMAProc in $objWMAProcs) {
                & taskkill /pid $objWMAProc.Id /f
            }
        }
    }
    New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'DO' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}

if($strDOVal -eq '1'){
    Write-Host "[Informational] Defer OOBE script already ran"
    exit 0
}

# If there is only one enabled user account, exit the script
if ((Get-LocalUser | Where-Object { $_.Enabled -eq $True }).Count -eq 1) {
    exit 0
}
#endregion