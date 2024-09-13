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
    [string]$strCVLVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'CVL').CVL
} catch {
    $strCVLVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference
#endregion

#region Logic
if($strCVLVal -ne '1'){
  try {
    Set-Volume -DriveLetter C -NewFileSystemLabel $env:COMPUTERNAME
    New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'CVL' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
  }
  catch {
    throw "[Error] Error attempting to change volume C:\ label`n $($_.Exception)"
  }
}
if($strCVLVal -eq '1') {
  Write-Host "[Informational] Change Volume Label Script Already Ran!"
  exit 0
}
#endregion