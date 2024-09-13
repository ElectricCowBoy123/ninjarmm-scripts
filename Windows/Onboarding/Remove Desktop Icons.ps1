#region Declaration & Validation
# Execute the query and retrieve the active user session
$activeUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName

# Get the SID (Security Identifier) of the active user
$userSID = (New-Object System.Security.Principal.NTAccount($activeUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
[String]$homeFolder = "C:\Users\" + $($activeUser -replace '.*\\')

Start-Sleep -Seconds 2
if (-not (Test-Path "Registry::HKEY_USERS\$userSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT")) {
  New-Item -Path "Registry::HKEY_USERS\$userSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Force
}

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
# Grab run flag registry keys
try {
  [string]$strRDIVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$userSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'RDI').RDI
} catch {
  $strRDIVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference
#endregion
$WSShell = New-Object -ComObject Wscript.Shell
#region Logic
if($strRDIVal -ne '1'){
  try {
    # Delete all shortcuts in users Desktop folder
    if(Test-Path -Path "$homeFolder\Desktop\"){
      #Write-Host "C:\Users\$env:USERNAME\Desktop\"
      $objFiles = Get-ChildItem -Path "$homeFolder\Desktop\" -Filter "*.lnk"
      foreach($objFile in $objFiles){
        if($objFile.FullName -ne "$homeFolder\Desktop\"){
          & del $objFile.FullName
        }
      }
    }
    Start-Sleep -Seconds 3 # Sleep to ensure second part gets correctly ran

    # Delete all shortcuts in public Desktop folder
    if(Test-Path -Path 'C:\Users\Public\Desktop\'){
      $objFiles = Get-ChildItem -Path 'C:\Users\Public\Desktop\' -Filter "*.lnk"
      foreach($objFile in $objFiles){
        & del $objFile.FullName
      }
    }

    if ((Get-LocalUser | Where-Object { $_.Enabled -eq $True }).Count -gt 1) {
      $objWMAProcs = Get-Process | Where-Object { $_.ProcessName -eq 'WWAHost' } -ErrorAction SilentlyContinue
      if($null -ne $objWMAProcs){
          foreach ($objWMAProc in $objWMAProcs) {
              & taskkill /pid $objWMAProc.Id /f
          }
      }
    }
  } catch {
    throw "[Error] Failed to delete desktop icons $($_.Exception)"
  }
   # Set regkey run flag to 1 
   New-ItemProperty -Path "Registry::HKEY_USERS\$userSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'RDI' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
  exit 0
}
if($strRDIVal -eq '1') {
  Write-Host "[Informational] Remove Desktop Icons Script Already Ran!"
  exit 0
}
#endregion