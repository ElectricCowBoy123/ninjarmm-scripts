#region Declaration & Validation
# Check if registry flag key exists
if (-not (Test-Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Force
}
  
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try {
    [string]$strTIVal = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT' -Name 'TI').TI
} catch {
    $strTIVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference
#endregion

#region Logic
if($strTIVal -ne '1'){
    Start-Sleep -Seconds 2

    if (-not (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Force
    }
    if (-not (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force
    }

    # Hide search widget
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name SearchBoxTaskbarMode -Value 0 -Type DWord -Force

    # Hide taskview widget
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowTaskViewButton -Value 0 -Type DWord -Force

    # Hide Co-pilot widget
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowCopilotButton -Value 0 -Type DWord -Force

    # Hide widgets widget
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarDa -Value 0 -Type DWord -Force

    # Hide chat widget
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarMn -Value 0 -Type DWord -Force
    
    # Get all processes with visible main windows
    $objWindows = Get-Process | Where-Object { $_.MainWindowTitle -ne "" }

    # Close each window
    foreach ($objWindow in $objWindows) {
        $objWindow.CloseMainWindow()
        Start-Sleep -Seconds 1
    }

    # Access the taskbar items
    $objTaskbarItems = (New-Object -ComObject Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items()

    foreach ($objItem in $objTaskbarItems) {
        # Check if the item has the "Unpin from taskbar" verb
        $objUnpinVerb = $objItem.Verbs() | Where-Object { $_.Name.replace('&', '') -match 'Unpin from taskbar' }
        Start-Sleep -Seconds 1
        # If the item has the unpin verb and is not excluded, unpin it
        if ($objUnpinVerb -and $arrExclusions -notcontains $objItem.Name) {
            $objUnpinVerb | ForEach-Object { $_.DoIt() }
        }
    }
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Name 'TI' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}
if($strTIVal -eq '1') {
    Write-Host "[Informational] Remove taskbar icons Script Already Ran!"
    exit 0
}
#endregion