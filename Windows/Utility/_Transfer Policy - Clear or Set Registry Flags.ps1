New-Variable -Name 'gBoolHasRun' -Value $False -Scope Global
$global:flag = $False

#region Function Declarations
function funcSetRegistryFlags(){
    param(
        [Parameter(Mandatory = $True)]
        [String]$strPath
    )

    if(-not (Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue)){
        Write-Host "[Informational] $strPath is not an actual Windows user, skipping..."
        Set-Variable -Name 'gBoolHasRun' -Value $False -Scope Global
        return # Hive is not an actual Windows user
    }
    if (Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue) {
        if (-not (Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -ErrorAction SilentlyContinue)) {
            New-Item -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Force
        }
    }

    if($strARegistryFlags['DO'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "DO" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    } 
    if($strARegistryFlags['DO'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "DO" -ErrorAction SilentlyContinue
    } 
    

    if($strARegistryFlags['CT'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "CT" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    } 
    if($strARegistryFlags['CT'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "CT" -ErrorAction SilentlyContinue
    }
    

    if($strARegistryFlags['BT'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "BT" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    }
    if($strARegistryFlags['BT'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "BT" -ErrorAction SilentlyContinue
    }
    

    if($strARegistryFlags['CL'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "CL" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    }
    if($strARegistryFlags['CL'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "CL" -ErrorAction SilentlyContinue
    }
    

    if($strARegistryFlags['TI'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "TI" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    }
    if($strARegistryFlags['TI'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "TI" -ErrorAction SilentlyContinue
    }
    

    if($strARegistryFlags['CVL'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "CVL" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    }
    if($strARegistryFlags['CVL'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "CVL" -ErrorAction SilentlyContinue
    }
    

    if($strARegistryFlags['END'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "END" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    }
    if($strARegistryFlags['END'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "END" -ErrorAction SilentlyContinue
    }
    

    if($strARegistryFlags['DPS'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "DPS" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    }
    if($strARegistryFlags['DPS'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "DPS" -ErrorAction SilentlyContinue
    }
    

    if($strARegistryFlags['RDI'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "RDI" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    }
    if($strARegistryFlags['RDI'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "RDI" -ErrorAction SilentlyContinue
    }


    if($strARegistryFlags['SDI'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "SDI" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    }
    if($strARegistryFlags['SDI'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "SDI" -ErrorAction SilentlyContinue
    }
    

    if($strARegistryFlags['CDBG'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "CDBG" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    }
    if($strARegistryFlags['CDBG'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "CDBG" -ErrorAction SilentlyContinue
    }
    

    if($strARegistryFlags['SBE'] -eq '1'){
        Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "SBE" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force   
    }
    if($strARegistryFlags['SBE'] -eq '0'){
        Remove-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name "SBE" -ErrorAction SilentlyContinue
    }

    Set-Variable -Name 'gBoolHasRun' -Value $True -Scope Global
}

function funcRemoveRegistryFlags(){
    param(
        [Parameter(Mandatory = $True)]
        [String]$strPath
    )

    if (Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue) {
        if ((Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -ErrorAction SilentlyContinue)) {
            Remove-Item -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Force -Recurse
            Set-Variable -Name 'gBoolHasRun' -Value $True -Scope Global
        }
    }
}
#endregion

#region Validate Parameters
<# Verify registry specific parameters #>
$strARegistryFlags = @{
    BT = $env:BT
    DO = $env:DO 
    CT = $env:CT 
    CL = $env:CL 
    TI = $env:TI 
    CVL = $env:CVL 
    END = $env:END
    DPS = $env:DPS 
    RDI = $env:RDI 
    SDI = $env:SDI 
    CDBG = $env:CDBG 
    SBE = $env:SBE 
}

# Ensure correct values are set
$strARegistryFlags.Values | ForEach-Object { if ($_ -ne '0' -and $_ -ne '1') { throw "[Error] Invalid value '$_' found in registryFlags. Expected '0' or '1'." } } | Out-Null

if ($env:setAllRegistryFlagsOverride -eq '1') {
    $keys = $strARegistryFlags.Keys | ForEach-Object { $_ }  # Create a list of keys
    foreach ($key in $keys) {
        $strARegistryFlags[$key] = '1'  # Update the value for each key
    }
}

<# Verify global parameters #>
if(($null -eq $env:applyToCurrentUser -or $env:applyToCurrentUser -eq '') -and ($null -eq $env:applyToAllUsers -or $env:applyToAllUsers -eq '')){
    throw "[Error] Please provide a parameter for Apply To Current User or Apply To All Users"
}

if($null -ne $env:applyToCurrentUser -and $null -ne $env:applyToAllUsers){
    if(($env:applyToCurrentUser.Length -ge 1) -and ($env:applyToAllUsers.Length -ge 1)){
        throw "[Error] Only one parameter must be set at any given time for Remove User Registry Flags and Remove All Registry Flags"
    }
}

if ($env:applyToAllUsers -ne '0' -and $env:applyToAllUsers -ne '1' -and $null -ne $env:applyToAllUsers -and $env:applyToAllUsers -ne ''){
    throw "[Error] Invalid value for Apply To All Users, provided:$env:applyToAllUsers Expected '0' or '1'."
}

if ($env:applyToCurrentUser -ne '0' -and $env:applyToCurrentUser -ne '1' -and $null -ne $env:applyToCurrentUser -and $env:applyToCurrentUser -ne ''){
    throw "[Error] Invalid value for Apply To Current User, provided:$env:applyToCurrentUser Expected '0' or '1'."
}

if($env:setAllRegistryFlagsOverride -ne '0' -and $env:setAllRegistryFlagsOverride -ne '1' -and $null -ne $env:setAllRegistryFlagsOverride -and $env:setAllRegistryFlagsOverride -ne ''){
    throw "[Error] Invalid value for registry flag override $env:setAllRegistryFlagsOverride. Expected '0' or '1'."
}
#endregion

#region Logic
if($env:applyToCurrentUser -eq '1'){
    try{
        # Execute the query and retrieve the active user session
        $objActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
        # Get the SID (Security Identifier) of the active user
        $userSID = (New-Object System.Security.Principal.NTAccount($objActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    }
    catch {
        throw "[Error] Error getting the userSID or querying for the current user! $($_.Exception)"
    }

    if($env:setAllRegistryFlagsOverride -eq '0'){
        funcRemoveRegistryFlags("Registry::HKEY_USERS\$userSID")
    }

    if($env:setAllRegistryFlagsOverride -eq '1' -or $null -eq $env:setAllRegistryFlagsOverride -or $env:setAllRegistryFlagsOverride -eq ''){
        funcSetRegistryFlags("Registry::HKEY_USERS\$userSID")
    }
}

if($env:applyToAllUsers -eq '1'){
    if($env:setAllRegistryFlagsOverride -eq '0'){
        foreach ($objSubKey in $(Get-ChildItem -Path "Registry::HKEY_USERS")) {
            if ($objSubKey.Name -like "*S-1*" -and $objSubKey.Name -notlike "*Classes*") {
                funcRemoveRegistryFlags("Registry::$($objSubKey.Name)")
            }
        }
    }

    if($env:setAllRegistryFlagsOverride -eq '1' -or $null -eq $env:setAllRegistryFlagsOverride -or $env:setAllRegistryFlagsOverride -eq ''){
        foreach ($objSubKey in $(Get-ChildItem -Path "Registry::HKEY_USERS")) {
            if ($objSubKey.Name -like "*S-1*" -and $objSubKey.Name -notlike "*Classes*") {
                funcSetRegistryFlags("Registry::$($objSubKey.Name)")
                if($global:gBoolHasRun){
                    Write-Host "[Informational] Successful: $($objSubKey.Name)"
                    $global:flag = $True
                }
            }
        }
        if(!$global:flag){
            throw "[Error] Script didn't run for any users!"
        }
    }
}
#endregion