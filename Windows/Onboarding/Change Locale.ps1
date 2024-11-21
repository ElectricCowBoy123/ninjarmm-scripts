#region Declaration and Validation
# Check if registry flag key exists
if (-not (Test-Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT" -Force
}
  
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try {
    [string]$strCLVal = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT' -Name 'CL').CL
} catch {
    $strCLVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference

Import-Module International
#endregion

#region Logic
if($strCLVal -ne '1'){
    $strLocale = 'en-GB'

    $objLangList = New-WinUserLanguageList $strLocale
    
    # Set UK English as the default display language for the current user
    Set-WinUserLanguageList -LanguageList $objLangList -Force
    Set-WinUILanguageOverride -Language $strLocale

    # Remove all other language packs for the current user
    Get-WinUserLanguageList | Where-Object { $_.LanguageTag -ne $strLocale } | ForEach-Object {
        Set-WinUserLanguageList -LanguageList $_.LanguageTag -Remove
    }

    # Remove all other display languages for the current user
    if ((Get-WinUILanguageOverride).LanguageTag -ne $strLocale) {
        Set-WinUILanguageOverride -Language $strLocale
    }

    # Set system locale and regional format to en-GB
    Set-WinSystemLocale -SystemLocale $strLocale
    Set-Culture -CultureInfo $strLocale

    # Set default system locale
    Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'Locale' -Value 00000809

    # Set default system locale
    Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'LocaleName' -Value $strLocale

    # Set default user locale
    Set-ItemProperty -Path 'HKCU:\Control Panel\International\User Profile' -Name 'Locale' -Value $strLocale

    # Set default user language list
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'PreferredUILanguages' -Value $strLocale

    # Check if the cmdlet Copy-UserInternationalSettingsToSystem is available
    if (Get-Command -Name Copy-UserInternationalSettingsToSystem -ErrorAction SilentlyContinue) {
        # Available, execute the command
        Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
    }
    # Only required for Windows 11
    #Computer\HKEY_CURRENT_USER\Control Panel\International\User Profile Languages en-GB

    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\DIT' -Name 'CL' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}
if($strCLVal -eq '1') {
    Write-Host "[Informational] Change locale Script Already Ran!"
    exit 0
}
#endregion