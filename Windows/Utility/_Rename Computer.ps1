#region Function Declarations
function funcMain {
    param (
        [Parameter (Mandatory = $True)]
        [bool]$boolIsSystem,
        [Parameter (Mandatory = $True)]
        [Object]$objUsr
    )

    [bool]$boolIsDomainJoined = $(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
    if($boolIsDomainJoined -eq $False){
        $dsregcmdOutput = dsregcmd /status
        if ($dsregcmdOutput -match "AzureAdJoined *: YES") {
            $boolIsDomainJoined = $True
        }
    }
    
    # System or Local Admin (Not Domain Joined)
    if(($boolIsDomainJoined -eq $False -and $boolIsSystem -eq $False) -or $boolIsSystem -eq $True){
        try{
            Rename-Computer -ComputerName $env:COMPUTERNAME -NewName $env:newComputerName -PassThru -Force | Out-Null
            Write-Host "[Informational] Computer Renamed to: $($env:newComputerName)"
            funcScheduleReboot
            return
        }
        catch {
            throw "[Error] Failed renaming non AD joined machine to $env:newComputerName Exception: $($_.Exception)"
        }
    }

    # Domain Joined Administrator
    if($boolIsDomainJoined -eq $True){
        ###throw "Machine is domain joined, hostname must be changed in the AD management console instead!"
        if(($null -ne $env:domainAdminUsername -or $env:domainAdminUsername -ne "") -and ($null -ne $env:domainAdminPassword -or $env:domainAdminPassword -ne "")){
            $strDomainPw = $DomainPassword | ConvertTo-SecureString -AsPlainText -Force
            $objCredential = New-Object System.Management.Automation.PsCredential("$DomainUser", $($strDomainPw | ConvertTo-SecureString -AsPlainText -Force))  
        }
        else {
            throw "[Error] Please provide a value for the Domain User and Domain Password parameters! Exception: $($_.Exception)"
        }

        try {
            Rename-Computer -DomainCredential $objCredential -ComputerName $env:COMPUTERNAME -NewName $env:newComputerName -PassThru -Force | Out-Null
            funcScheduleReboot
            Write-Host "[Informational] Computer Renamed to: $($env:newComputerName)"
            return
        }
        catch {
            throw "[Error] Renaming domain joined computer to $env:newComputerName Exception: $($_.Exception)"
        }
    }

    <#
    Write-Host "`n[Debug] # DEBUG BEGIN #"
    Write-Host "[Debug]: COMPUTERNAME: $env:COMPUTERNAME"
    Write-Host "[Debug]: isInGroup: $boolIsDomainJoined"
    Write-Host "[Debug]: USERDOMAIN: $env:USERDOMAIN"
    Write-Host "[Debug]: objUsr.AuthenticationType: $($objUsr.AuthenticationType)"
    Write-Host "[Debug]: isSystem: $($boolIsSystem)"
    Write-Host "`n[Debug] # DEBUG END #"
    #>
}

function funcScheduleReboot {
    if ($env:reboot -eq '1') {
        Write-Host "[Informational] Reboot specified, scheduling reboot for $((Get-Date).AddMinutes(5))..."
        Start-Process "shutdown.exe" -ArgumentList "/r /t 300" -NoNewWindow -Wait
    }
    else {
        Write-Host "[Informational] Changes will take affect after the next reboot."
    }
}

#endregion

#region Validation Steps
if ($env:newComputerName -eq $env:computername) {
    throw "[Error] New hostname is the same as the current hostname!"
}

# Warn end-users if theyre giving the computer too long of a name.
if ($env:newComputerName.Length -gt 15) {
    throw "[Error] Hostname $env:newComputerName is over 15 characters, please provide a shorter one!"
}

if($(Get-WmiObject -Class Win32_OperatingSystem).ProductType -eq '2'){
    throw "[Error] Machine is a domain controller!"
}

if($env:reboot -ne '1' -and $env:reboot -ne '0'){
    throw "[Error] Please provide a binary value for Reboot!"
}
#endregion

#region Logic

$obj = [System.Security.Principal.WindowsIdentity]::GetCurrent()

if($($obj.Name -like "NT AUTHORITY*") -eq $True){
    Write-Host "[Informational] Running in SYSTEM mode"
    funcMain -boolIsSystem $True -objUsr $obj
    Write-Host "[Informational] Successful!"
}
elseif($obj.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -eq $True -and $($obj.Name -like "NT AUTHORITY*") -eq $False){
    Write-Host "[Informational] Running in administrator mode"
    funcMain -boolIsSystem $False -objUsr $obj
    Write-Host "[Informational] Successful!"
}
else {
    throw "[Error] Script is not running in an elevated environment! Exception: $($_.Exception)"
}
#endregion