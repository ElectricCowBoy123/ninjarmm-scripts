#Name = CBGW VPN
#L2TP Server Address = doncaster.concordebgw.com
#L2TP PSK = Q279Lmd9WWyRwXQqD09TqzPKEyTkoQfdI8lWTdSY
#DNS Suffix: cbgw.local

try {
    Set-ItemProperty -Path 'HKLM:SYSTEM\CurrentControlSet\Services\PolicyAgent' -Name 'AssumeUDPEncapsulationContextOnSendRule' -Type DWORD -Value 2
}
catch {
    throw "[Error] Error whitelisting L2TP connections $($_.Exception)"
}
try {
    Remove-VpnConnection -Name $env:companyCode, "$env:companyCode-VPN", $env:companyCode, "$env:companyCode VPN - L2TP" -Force -PassThru
    Add-VpnConnection -Name "$env:companyCode VPN - L2TP" -ServerAddress $env:serverAddress -TunnelType 'L2TP' -DNSSuffix $env:DNSSuffix -L2tpPsk $env:PSK -EncryptionLevel 'Optional' -Force -PassThru -SplitTunneling -RememberCredential -AllUserConnection
}
catch {
    throw "[Error] Error adding VPN connection for $env:serverAddress $($_.Exception)"
}