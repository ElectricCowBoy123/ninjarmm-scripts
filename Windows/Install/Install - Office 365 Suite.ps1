#region Variable Declarations
$strOfficeInstallDownloadPath = 'C:\DIT\Office365Install'
$strConfigurationXMLFile = "$strOfficeInstallDownloadPath\OfficeInstall.xml"
$boolIsOfficeAlreadyInstalled = $False
$strARegLocations = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')

$strOfficeXML = [XML]@"
<Configuration ID="76b3b530-54a8-44d8-9689-278ec2547592">
  <Info Description="Example O365 install" />
  <Add OfficeClientEdition="64" Channel="MonthlyEnterprise" MigrateArch="TRUE">
    <Product ID="O365BusinessRetail">
      <Language ID="MatchOS" />
      <Language ID="MatchPreviousMSI" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="Publisher" />
    </Product>
  </Add>
  <Property Name="SharedComputerLicensing" Value="0" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Property Name="DeviceBasedLicensing" Value="0" />
  <Property Name="SCLCacheOverride" Value="0" />
  <Updates Enabled="TRUE" />
  <RemoveMSI />
  <AppSettings>
    <Setup Name="Company" Value="$env:companyName" />
    <User Key="software\microsoft\office\16.0\excel\options" Name="defaultformat" Value="51" Type="REG_DWORD" App="excel16" Id="L_SaveExcelfilesas" />
    <User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas" />
    <User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas" />
  </AppSettings>
  <Display Level="None" AcceptEULA="TRUE" />
  <Setting Id="SETUP_REBOOT" Value="Never" /> 
  <Setting Id="REBOOT" Value="ReallySuppress"/>
</Configuration>
"@
#endregion

#region Function Declarations
function funcGetODTURL {
    $objMSWebPage = Invoke-RestMethod 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117'
    $objMSWebPage | ForEach-Object {
        if ($_ -match 'url=(https://.*officedeploymenttool.*\.exe)') {
            $matches[1]
        }
    }
}
#endregion

#region Logic
foreach ($objKey in (Get-ChildItem $strARegLocations) ) {
    if ($objKey.GetValue('DisplayName') -like '*Microsoft 365 Apps for business - en-us*') {
        $strOfficeVersionInstalled = $objKey.GetValue('DisplayName')
        $boolIsOfficeAlreadyInstalled = $True
    }
}

if(!$boolIsOfficeAlreadyInstalled){
    $boolIsOfficeInstalled = $False
    Write-Host "[Informational] Starting Office Install..."

    if (-Not(Test-Path $strOfficeInstallDownloadPath )) {
        New-Item -Path $strOfficeInstallDownloadPath -ItemType Directory | Out-Null
    }

    $strOfficeXML.Save($strConfigurationXMLFile)

    [String]$strODTInstallLink = funcGetODTURL

    #Download the Office Deployment Tool
    Write-Host '[Informational] Downloading the Office Deployment Tool...'

    try {
        Invoke-WebRequest -Uri $strODTInstallLink -OutFile "$strOfficeInstallDownloadPath\ODTSetup.exe"
    }
    catch {
        throw " `n
        [Informational] There was an error downloading the Office Deployment Tool. `n
        [Informational] Please verify the below link is valid `n
        [Informational] $strODTInstallLink Exception: $($_.Exception)"
    }

    #Run the Office Deployment Tool setup
    try {
        Write-Host '[Informational] Running the Office Deployment Tool...'
        Start-Process "$strOfficeInstallDownloadPath\ODTSetup.exe" -ArgumentList "/quiet /extract:$strOfficeInstallDownloadPath" -Wait
    }
    catch {
        throw "[Error] Error running the Office Deployment Tool. Exception $($_.Exception)"
    }

    #Run the O365 install
    try {
        Write-Host '[Informational] Downloading and installing Microsoft 365'
        Start-Process "$strOfficeInstallDownloadPath\Setup.exe" -ArgumentList "/configure $strConfigurationXMLFile" -Wait -PassThru
    }
    catch {
        throw "[Error] Error running the Office install. Exception: $($_.Exception)"
    }

    #Check if Office 365 suite was installed correctly.
    $strARegLocations = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')

    foreach ($objKey in (Get-ChildItem $strARegLocations) ) {
        if ($objKey.GetValue('DisplayName') -like '*Microsoft 365 Apps for business - en-us*') {
            $strOfficeVersionInstalled = $objKey.GetValue('DisplayName')
            $boolIsOfficeInstalled = $True
        }
    }

    if ($boolIsOfficeInstalled) {
        Write-Host "[Informational] $($strOfficeVersionInstalled) installed successfully restarting!"
        Remove-Item -Path $strOfficeInstallDownloadPath -Force -Recurse
        shutdown.exe -r -t 60
    }
    else {
        throw "[Error] Microsoft 365 was not detected after the installer ran"
    }
}
#endregion