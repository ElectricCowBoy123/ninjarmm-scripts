#region Parameter Declaration and Validation
$boolUseDeviceType = $True
$strMSI = "ClientSetup.msi"
$strDestinationFolder = $env:TEMP
if($env:useNinjaOrganizationName -eq '1'){ [bool]$boolUseOrgName = $True } 
if($env:useNinjaOrganizationName -eq '0'){ [bool]$boolUseOrgName = $False } 
if($env:useNinjaOrganizationName -ne '1' -and $env:useNinjaOrganizationName -ne '0'){ throw "[Error] No value or invalid value supplied for useNinjaOrganizationName!" }

if($env:useNinjaLocationName -eq '1'){ [bool]$boolUseLocation = $True }     
if($env:useNinjaLocationName -eq '0'){ [bool]$boolUseLocation = $False }
if($env:useNinjaLocationName -ne '1' -and $env:useNinjaLocationName -ne '0'){ throw "[Error] No value or invalid value supplied for useNinjaLocationName!" }

if($env:skipSleep -eq '1'){ [bool]$boolSkipSleep = $True } 
if($env:skipSleep -eq '0'){ [bool]$boolSkipSleep = $False } 
if($env:skipSleep -ne '1' -and $env:skipSleep -ne '0'){ throw "[Error] No value or invalid value supplied for skipSleep!" }
#endregion

<#
if ($env:screenconnectDomainName -match "^http(s)?://") {
    Write-Warning "http(s):// is not part of the domain name. Removing http(s):// from your input...."
    $env:screenconnectDomainName = $env:screenconnectDomainName -replace "^http(s)?://"
    Write-Warning "New Domain Name $env:screenconnectDomainName."
}

if ($env:screenconnectDomainName -match "^C:/") {
    Write-Error "It looks like you entered in a file path by mistake. We actually need the domain name used to reach your ScreenConnect website for example 'companyname.screenconnect.com'"
    exit 1
}
#>

#### Helper functions used throughout the script ####

#region Function Declarations
function funcIsElevated {
    $strID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $objUser = New-Object System.Security.Principal.WindowsPrincipal($strID)
    $objUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    return $objUser
}

# Extract the ProductName from the msi
function funcGetControlPanelName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [string]$strMSIPath
    )
    $objWindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
    $objDatabase = $objWindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $objWindowsInstaller, @($strMSIPath, 0))
    $strQuery = "SELECT `Value` FROM `Property` WHERE `Property` = 'ProductName'"

    $objView = $objDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $objDatabase, $strQuery)
    $objView.GetType().InvokeMember("Execute", "InvokeMethod", $null, $objView, $null)

    $objRecord = $objView.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $objView, $null)

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($objWindowsInstaller) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($objView) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($objDatabase) | Out-Null
    [System.GC]::Collect()

    if ($objRecord) {
        return $objRecord.GetType().InvokeMember("StringData", "GetProperty", $null, $objRecord, 1)
    }
}

# Is it a Server or Desktop OS?
function funcGetProductType {
    if ($objUserSVersionTable.PSVersion.Major -ge 5) {
        $intOS = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object ProductType -ExpandProperty ProductType
    }
    else {
        $intOS = Get-WmiObject -Class Win32_OperatingSystem | Select-Object ProductType -ExpandProperty ProductType
    }
    
    return $intOS
}

# Check the Chassis type to find out if it's a laptop or not.
function funcIsLaptop {
    if ($objUserSVersionTable.PSVersion.Major -ge 5) {
        $intChassis = Get-CimInstance -ClassName win32_systemenclosure | Select-Object ChassisTypes -ExpandProperty ChassisTypes
    }
    else {
        $intChassis = Get-WmiObject -Class win32_systemenclosure | Select-Object ChassisTypes -ExpandProperty ChassisTypes
    }

    switch ($intChassis) {
        9 { return $True }
        10 { return $True }
        14 { return $True }
        default { return $False }
    }
}

# Check's the two uninstall registry keys to see if the app is installed. Needs the name as it would appear in Control Panel.
function funcFindUninstallKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [String]$DisplayName
    )
    
    $objUninstallList = New-Object System.Collections.Generic.List[Object]

    $strResult = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
    if ($strResult) { $objUninstallList.Add($strResult) }

    $strResult = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
    if ($strResult) { $objUninstallList.Add($strResult) }
    
    return $objUninstallList
}

# Handy download function
function funcInvokeDownload {
    param(
        [Parameter(Mandatory = $True)]
        [String]$strURL,

        [Parameter(Mandatory = $True)]
        [String]$strPath,

        [Parameter(Mandatory = $False)]
        [bool]$boolSkipSleep
    )
    Write-Host "[Informational] URL given; downloading the file..."

    $i = 1
    While ($i -lt 4) {
        if (!$boolSkipSleep) {
            $SleepTime = Get-Random -Minimum 3 -Maximum 30
            Start-Sleep -Seconds $SleepTime
        }

        Write-Host "[Informational] Download Attempt $i"

        try {
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($strURL, $strPath)
            $File = Test-Path -Path $strPath -ErrorAction SilentlyContinue
        }
        catch {
            throw "[Error] An error has occurred while downloading! $($_.Exception.Message)" 
        }

        if ($File) {
            $i = 4
        }
        else {
            $i++
        }
    }

    if (-not (Test-Path $strPath)) {
        throw "[Error] Failed to download file!"
    }
}

# This will build our screenconnect download url if only given a domain name or if modification is needed to include the device type, location, org name etc.
function funcNewURL {
    param(
        [Parameter(Mandatory = $True)]
        [String]$Domain
    )

    Write-Host "[Informational] Attempting to build from domain..."
    $strURL = "$Domain/Bin/$env:NINJA_COMPANY_NAME.ClientSetup.msi?e=Access&y=Guest"

    if ($boolUseOrgName) { $strURL = $strURL + "&c=$env:NINJA_ORGANIZATION_NAME" }else { $strURL = $strURL + "&c=" }
    if ($boolUseLocation) { $strURL = $strURL + "&c=$env:NINJA_LOCATION_NAME" }else { $strURL = $strURL + "&c=" }
    if ($env:department) { $strURL = $strURL + "&c=$env:department" }else { $strURL = $strURL + "&c=" }
    if ($boolUseDeviceType) {
        switch (funcGetProductType) {
            1 { if (funcIsLaptop) { $strURL = $strURL + "&c=Laptop&c=&c=&c=&c=" }else { $strURL = $strURL + "&c=Workstation&c=&c=&c=&c=" } }
            2 { $strURL = $strURL + "&c=Domain Controller&c=&c=&c=&c=" }
            3 { $strURL = $strURL + "&c=Server&c=&c=&c=&c=" }
        }
    }
    else {
        $strURL = $strURL + "&c=&c=&c=&c=&c="
    }

    Write-Host "[Informational] URL Built: $strURL"

    return $strURL
}
#endregion

#region Validate Parameters
if (-not (funcIsElevated)) {
    throw "[Error] Access Denied. Please run with Administrator privileges."
}

if (-not (Test-Path $strDestinationFolder -ErrorAction SilentlyContinue)) {
    Write-Host "[Informational] Destination Folder does not exist! Creating directory..."
    New-Item $strDestinationFolder -ItemType Directory
}

# Some means of installing the file is required.
if (-not ($env:screenconnectDomainName)) { 
    throw "[Error] A domain is required to install control."
}
#endregion

#region Logic
#Set the log file as a temporary file, it will be created in the temp folder of the context the script runs in (c:\windows\temp or c:\users\username\appdata\temp)
$InstallerLogFile = [IO.Path]::GetTempFileName()
Write-Host "[Informational] Installer Log File location will be: $InstallerLogFile"

# Build the arguments needed to create the url
$strAArgumentList = @{ Domain = $env:screenconnectDomainName }

# Arguments required to download the file
$strADownloadArgs = @{ strPath = "$strDestinationFolder\$strMSI" }
if ($boolSkipSleep) { $strADownloadArgs["boolSkipSleep"] = $True }

# Build the URL and get it ready for download
$strADownloadArgs["strURL"] = funcNewURL @strAArgumentList

# Download the installer
funcInvokeDownload @strADownloadArgs

# Grab the installer file
$strInstallerFile = Join-Path -Path $strDestinationFolder -ChildPath $strMSI -Resolve

# Define the name of the software we are searching for and look for it in both the 64 bit and 32 bit registry nodes
$objUserroductName = "$(funcGetControlPanelName -strMSIPath $strInstallerFile)".Trim()
if (-not $objUserroductName) { 
    throw "[Error] Failed to fetch the product name from the MSI at path '$strInstallerFile'. Ensure the MSI path is correct and the MSI contains the necessary product information."
}

# If already installed, exit.
$boolIsInstalled = funcFindUninstallKey -DisplayName $objUserroductName
if ($boolIsInstalled) {
    Write-Host "[Informational] $objUserroductName is already installed; exiting..."
    exit 0
}

# ScreenConnect install arguments
$Arguments = "/c msiexec /i ""$strInstallerFile"" /qn /norestart /l ""$InstallerLogFile"" REBOOT=REALLYSUPPRESS"

# Install and let the user know the exit code
$objUserrocess = Start-Process -Wait cmd -ArgumentList $Arguments -PassThru
Write-Host "[Informational] Exit Code: $($objUserrocess.ExitCode)";

# Interpret the exit code
switch ($objUserrocess.ExitCode) {
    0 { Write-Host "[Informational] Success" }
    3010 { Write-Host "[Informational] Success. Reboot required to complete installation" }
    1641 { Write-Host "[Informational] Success. Installer has initiated a reboot" }
    default {
        Write-Error "[Error] Exit code does not indicate success"
        Get-Content $InstallerLogFile -ErrorAction SilentlyContinue | Select-Object -Last 50 | Write-Host
    }
}

exit $objUserrocess.ExitCode
#endregion