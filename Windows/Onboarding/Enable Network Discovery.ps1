#region Declaration & Validation
# Execute the query and retrieve the active user session
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName

# Get the SID (Security Identifier) of the active user
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

# Check if the registry run flag path exsts
if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT")) {
    New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Force
}

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
# Check if registry runflag exists
try {
    $strENDVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'END').END
} catch {
    $strENDVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference
#endregion

#region Logic
if ($strENDVal -ne '1') {

    # Get current network interface
    try {
        if((Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).Name -like '*Ethernet*'){
            # Get IP addresses for primary Ethernet adapter
            $objIPv4 = Get-NetIPAddress | Where-Object { $_.InterfaceAlias -like "Ethernet*" -and $_.AddressState -eq 'Preferred' -and $_.AddressFamily -eq 'IPv4' }
            # Get IP addresses for primary Ethernet adapter
            $objIPv6 = Get-NetIPAddress | Where-Object { $_.InterfaceAlias -like "Ethernet*" -and $_.AddressState -eq 'Preferred' -and $_.AddressFamily -eq 'IPv6' }
        }
        else {
            # Get IP addresses for primary WiFI adapter
            $objIPv4 = Get-NetIPAddress | Where-Object { $_.InterfaceAlias -like "WiFi*" -and $_.AddressState -eq 'Preferred' -and $_.AddressFamily -eq 'IPv4' -and $_.Status -eq 'Up' }
            # Get IP addresses for primary WiFI adapter
            $objIPv6 = Get-NetIPAddress | Where-Object { $_.InterfaceAlias -like "WiFi*" -and $_.AddressState -eq 'Preferred' -and $_.AddressFamily -eq 'IPv6' -and $_.Status -eq 'Up' }
        }
    }
    catch {
        Write-Host "[Error] Failed to get network interface index numbers`n $($_.Exception)"
    }

    # Enable SMB2
    try {
        if((Get-SmbServerConfiguration | Select-Object EnableSMB1Protocol) -ne 'True'){
            Set-SmbServerConfiguration -EnableSMB1Protocol $False -Force -ErrorAction SilentlyContinue
            Set-SmbServerConfiguration -EnableSMB2Protocol $True -Force -ErrorAction SilentlyContinue
        }
        Set-SmbServerConfiguration -EnableLeasing $True -Force
        Set-SmbServerConfiguration -EnableStrictNameChecking $False -Force
    } 
    catch {
        throw "[Error] Failed to enable SMB2: $($_.Exception)"
    }

    # Ensure that the necessary services are running
    try {
        $strAServices = @("fdphost", "upnphost", "fdrespub", "ssdpsrv")
        foreach ($strService in $strAServices) {
            Set-Service -Name $strService -StartupType Automatic
            Start-Service -Name $strService
        }
    }
    catch {
        throw "[Error] Failed to start network services`n $($_.Exception)"
    }

    # Foreach adapter being used that isn't domain set those profiles to 'Private' for security purposes
    try {
        Get-NetConnectionProfile |
        Where-Object { $_.InterfaceIndex -eq $objIPv6.InterfaceIndex -or $_.InterfaceIndex -eq $objIPv4.InterfaceIndex } |
        Where-Object { $_.NetworkCategory -ne 'Domain' } |
        ForEach-Object {
            $_ | Set-NetConnectionProfile -NetworkCategory 'Private'
        }
    }
    catch {
        throw "[Error] Failed to set non domain network adapters to private`n $($_.Exception)"
    }

    # Force category type if it is not already set in the registry for some reason and enable network level authentication for private networks
    try {
        $objPrivateProfileGUIDs = Get-ChildItem -Path $strPrivateProfilePath | Where-Object { (Get-ItemProperty $_.PSPath).Category -eq 1}

        if ($objPrivateProfileGUIDs.Length -gt 1) {
            foreach ($objGUID in $objPrivateProfileGUIDs) {
                $strGuidName = $objGUID.PSChildName
                Set-ItemProperty -Path "$strPrivateProfilePath\$strGuidName" -Name "CategoryType" -Value 0 -Force
                Set-ItemProperty -Path "$strPrivateProfilePath\$strGuidName" -Name "Nla" -Value 1 -Force
            }
        } 
    }
    catch {
        throw "[Error] Failed to force network profile settings for private profiles in the registry`n $($_.Exception)"
    }

    try {
        # Set and enable firewall rules for network discovery and file and printer sharing for private profiles
        Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled True -Profile Private
        Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True -Profile Private

        # Set and enable firewall rules for network discovery and file and printer sharing for domain profiles
        Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled True -Profile Domain
        Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True -Profile Domain
        
        Set-NetFirewallProfile -Profile Private -Enabled True
        Set-NetFirewallProfile -Profile Domain -Enabled True
    }
    catch {
        throw "[Error] Failed to set firewall rules for private profiles`n $($_.Exception)"
    }

    try {
        # Refresh the network profile settings
        Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq 'Private' } | Set-NetConnectionProfile -NetworkCategory Private
    }
    catch {
        throw "[Error] Failed to refresh network profile settings`n $($_.Exception)"
    }

    New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'END' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}
if($strENDVal -eq '1') {
    Write-Host "[Informational] Network discovery already enabled`n"
    exit 0
}
#endregion