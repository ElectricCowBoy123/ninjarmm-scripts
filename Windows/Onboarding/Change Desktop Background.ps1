<#
    There is a limitation in this script in that it may not correctly detect a domain administrator is actually a domain
    administrator and thusly not set the background to grey, this is because there is no way to check for this without
    querying the domain which is a future improvement point. Currently the script checks if the user is a domain user
    and a local administrator and sets the background to grey accordingly, if the user is a domain administrator but
    not a local administrator this won't happen. It could be set to grey for all domain users but that is not the 
    purpose of this implementation. 
#>

#region Declaration and Validation
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO

# Grab run flag registry keys
if (-not (Test-Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Force
}

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'

try {
    [string]$strCDBGVal = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT' -Name 'CDBG').CDBG
} catch {
    $strCDBGVal = $null
}

$ErrorActionPreference = $oldErrorActionPreference
#endregion

#region Function Declarations
function funcChangeDesktopBG {
    param (
        [parameter(Mandatory=$True)]
        [int]$intR,
        [int]$intG,
        [int]$intB
    )

    try {
        New-Item -Path "$env:APPDATA" -Name "DIT" -ItemType "Directory" -ErrorAction SilentlyContinue | Out-Null
    }
    catch{
        Write-Host "[Error] Failed to create directory $($_.Exception)"
    }

    # Set path to save bitmap
    $strImage = "$env:APPDATA\DIT\tempbg.bmp"

    # Create a new 1x1 pixel bitmap image object
    $objBmp = New-Object System.Drawing.Bitmap(1, 1)

    # Create a color object with the specified RGB values
    $objColor = [System.Drawing.Color]::FromArgb($intR, $intG, $intB)

    # Set the pixel color
    $objBmp.SetPixel(0, 0, $objColor)

    # Save the bitmap to the specified path
    $objBmp.Save($strImage, [System.Drawing.Imaging.ImageFormat]::Bmp)

    # Dispose the bitmap object
    $objBmp.Dispose()

    # Set wallpaper using SystemParametersInfo
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
    $fWinIni = $UpdateIniFile -bor $SendChangeEvent

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Params
{ 
    [DllImport("User32.dll", CharSet = CharSet.Unicode)] 
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

    [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $strImage, $fWinIni) | Out-Null
}
#endregion

#region Logic
if ($strCDBGVal -ne '1') {
    $objUsr = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    [bool]$boolIsInGroup = $(Invoke-Expression "net localgroup administrators") -contains $(([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name)
    if($([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name -like "*$env:COMPUTERNAME*"){
        [bool]$boolIsInGroup = $(Invoke-Expression "net localgroup administrators") -contains $((([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name) -replace '.*\\', '')
    }
    # AD/Entra
    if(($objUsr.AuthenticationType -eq 'CloudAP' -and $boolIsInGroup -and $env:COMPUTERNAME -ne $env:USERDOMAIN) -or ($objUsr.AuthenticationType -eq 'NTLM' -and $boolIsInGroup -and $env:COMPUTERNAME -ne $env:USERDOMAIN) -or ($objUsr.AuthenticationType -eq 'Kerberos' -and $boolIsInGroup -and $env:COMPUTERNAME -ne $env:USERDOMAIN)){
        funcChangeDesktopBG -intR 128 -intG 128 -intB 128

        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name Hidden -Value 1 -Type DWord -Force
        if ((Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings")) {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Name TaskbarEndTask -Type DWord -Value 1
        }
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -Value 0
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0
    }

    # Local 
    if($boolIsInGroup -and $env:COMPUTERNAME -eq $env:USERDOMAIN){
        funcChangeDesktopBG -intR 255 -intG 165 -intB 0

        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name Hidden -Value 1 -Type DWord -Force
        if ((Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings")) {
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Name TaskbarEndTask -Type DWord -Value 1
        }
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -Value 0
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0
    }

    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT' -Name 'CDBG' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}
if($strCDBGVal -eq '1') {
    Write-Host "[Informational] Change Desktop Background Script Already Ran!"
    exit 0
}
#endregion