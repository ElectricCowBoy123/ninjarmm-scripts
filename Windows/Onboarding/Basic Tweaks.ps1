#region Declaration and Validation
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
    [string]$strBTVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'BT').BT
} catch {
    $strBTVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference
#endregion

#region Logic
if($strBTVal -ne '1'){

    # Don't hide 'known' filetypes
    Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0 -Type DWord -Force

    # Launch Explorer on This PC 
    Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name LaunchTo -Value 1 -Type DWord -Force

    # Enable Windows updates [Not-needed]
    # Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'AUOptions' -Value 4

    # Enable restart reminders [Not-needed]
    # Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'RebootRequired' -Value 1

    if ((Get-LocalUser | Where-Object { $_.Enabled -eq $True }).Count -gt 1) {
        $objWMAProcs = Get-Process | Where-Object { $_.ProcessName -eq 'WWAHost' } -ErrorAction SilentlyContinue
        if($null -ne $objWMAProcs){
            foreach ($objWMAProc in $objWMAProcs) {
                & taskkill /pid $objWMAProc.Id /f
            }
        }
    }
    New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'BT' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}
if($strBTVal -eq '1'){
     Write-Host "[Informational] Basic tweaks Script Already Ran!"
     exit 0
}
#endregion