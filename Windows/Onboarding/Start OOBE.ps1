#region Declaration & Validation
# Check if registry flag key exists
if (-not (Test-Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Force
  }
  
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try {
    [string]$strSBEVal = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT' -Name 'SBE').SBE
} catch {
    $strSBEVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference

# Define the batch file content
$strBatContent = @"
@echo off
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 /nobreak > nul
start explorer.exe
"@
#endregion

#region Logic
if($strSBEVal -ne '1'){
    # Specify the path where you want to save the batch file
    $strBatFilePath = "$env:Temp\res.bat"

    # Create the batch file using Out-File
    $strBatContent | Out-File -FilePath $strBatFilePath -Encoding ASCII

    # Execute the batch file
    $objProcess = Start-Process -FilePath $strBatFilePath -NoNewWindow -PassThru
    $objProcess.WaitForExit()
    
    if (Test-Path $strBatFilePath) {
        Remove-Item $strBatFilePath -Force -ErrorAction SilentlyContinue
    }

    # Kill any remaining settings windows
    $objProcess = Get-Process | Where-Object { $_.ProcessName -eq "SystemSettings" }

    # If process is found, terminate it
    if ($objProcess) {
        Stop-Process -Name "SystemSettings" -Force -ErrorAction SilentlyContinue
    }
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT' -Name 'SBE' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}
if($strSBEVal -eq '1') {
    Write-Host "[Informational] Start OOBE Script Already Ran!"
    exit 0
}
#endregion