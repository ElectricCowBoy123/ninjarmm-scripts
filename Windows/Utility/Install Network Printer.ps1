#region Parameter Validation
if ($null -ne $env:driverZipFileName -and $env:driverZipFileName -ne '') { $strDriverZipFileName = $env:driverZipFileName } else { throw "[Error] Please specify a Driver Zip File Name." }
if ($null -ne $env:driverInfFileName -and $env:driverInfFileName -ne '') { $strDriverFileName = $env:driverInfFileName } else { throw "[Error] Please specify a Driver .inf File Name." }
if ($null -ne $env:driverName -and $env:driverName -ne '') { $strDriverName = $env:driverName } else { throw "[Error] Please specify a Driver Name." }
if ($null -ne $env:printerName -and $env:printerName -ne '') { $strPrinterName = $env:printerName } else { throw "[Error] Please specify a Printer Name." }
if ($null -ne $env:printerIpAddress -and $env:printerIpAddress -ne '') { $strPrinterPort = $env:printerIpAddress } else { throw "[Error] Please specify a Printer IP Address." }
if ($null -ne $env:forceRestart -and $env:forceRestart -ne ''){ [Switch]$boolRestart = [System.Convert]::ToBoolean($env:forceRestart) } else { throw "[Error] Please specify a value for the Force Restart parameter." }
if ($null -ne $env:removePrinter -and $env:removePrinter -ne ''){ [Switch]$boolRemove = [System.Convert]::ToBoolean($env:removePrinter) } else { throw "[Error] Please specify a value for the Remove Printer parameter." }
if ($null -ne $env:outputParameterValues -and $env:outputParameterValues -ne ''){ [Switch]$boolOutputParameterValues = [System.Convert]::ToBoolean($env:outputParameterValues) } else { throw "[Error] Please specify a value for the Output Parameter Values parameter." }
#endregion

#region Variable Declarations
# Temporary folder to store downloads
$strWorkingFolder = "$env:TEMP\DIT\Downloads"

# Name of ZIP file you have uploaded which contains the drivers for this printer.
$strDriverZipFileName = "$env:driverZipFileName"

# Main inf Driver file name.
$strDriverFileName = "$env:driverInfFileName"

# Print Driver Name as referenced in the inf file.
$strDriverName = "$env:driverName"

# Name of Print Queue to be added to Windows.
$strPrinterName = "$env:printerName"

# IP address of Printer to be used in the Printer Port.
$strPrinterPort = "$env:printerIpAddress"

# Create the DriverName variable with no spaces.
$strDriverNameNoSpaces = $strDriverName.replace(' ','')

# Printer Driver temp folder location.
$strFolderPath = "$env:TEMP\DIT\Drivers\$strDriverNameNoSpaces"

# Name of Driver to be installed as shown inside the inf file.
$strDriverPath = "$strFolderPath\$strDriverFileName"

# Printer Port name to be used in Windows.
$strPrinterPortName = "TCPPort:$strPrinterPort"

# Url to download drivers from.
$strDownloadUrl = "https://example.net/ninja/drivers/$strDriverZipFileName"

# Temporary file name for downloads
$strOutfilePath = "$strWorkingFolder\$strDriverName.zip"
#endregion

#region Output Parameter Values
# Confirm Script Parameters.
if($boolOutputParameterValues){
    Write-Host "[Informational] List of parameters used in this script:"
    Write-Host "[Informational] Working Folder Path = $strWorkingFolder"
    Write-Host "[Informational] Output Folder Path = $strOutfilePath"
    Write-Host "[Informational] Download Zip File Name = $strDriverZipFileName"
    Write-Host "[Informational] Download URL = $strDownloadUrl"
    Write-Host "[Informational] Driver File Name = $strDriverFileName"
    Write-Host "[Informational] Driver Path = $strDriverPath"
    Write-Host "[Informational] Folder Path = $strFolderPath"
    Write-Host "[Informational] Driver Name = $strDriverName"
    Write-Host "[Informational] Printer Name = $strPrinterName"
    Write-Host "[Informational] Printer Port = $strPrinterPort"
    Write-Host "[Informational] Printer Port Name = $strPrinterPortName"
    Write-Host "[Informational] Driver folder Name = $strDriverNameNoSpaces"
    Write-Host "[Informational] End..."
}
#endregion

#region Function Declarations
function funcIsElevated {
    $strID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $objUser = New-Object System.Security.Principal.WindowsPrincipal($strID)
    $objUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function funcInstallDriver {
    param (
        [Parameter(Mandatory=$True)]
        [String]$strDriverFileName,
        [Parameter(Mandatory=$True)]
        [String]$strDriverName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterPortName,
        [Parameter(Mandatory=$True)]
        [String]$strDriverPath,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterPort
    )
    
    # Begin the Install
    if ($null -eq (Get-Printer -name $strPrinterName -ErrorAction SilentlyContinue)) {
        # Check if driver is not already installed
        if ($null -eq (Get-PrinterDriver -name $strDriverName -ErrorAction SilentlyContinue)) {
            # Add the driver to the Windows Driver Store
            pnputil.exe /a "$strDriverPath"
            # Install the driver
            Add-PrinterDriver -Name $strDriverName
        } else {
            Write-Warning "[Informational] Printer driver already installed"
        }

        # Check if printerport doesn't exist
        if ($null -eq (Get-PrinterPort -name $strPrinterPortName)) {
            # Add printerPort
            Add-PrinterPort -Name $strPrinterPortName -PrinterHostAddress $strPrinterPort
        } else {
            Write-Warning "[Informational] Printer port with name $($strPrinterPortName) already exists"
        }

        try {
            # Add the printer
            Add-Printer -Name $strPrinterName -DriverName $strDriverName -PortName $strPrinterPortName -ErrorAction stop
        } catch {
            throw "[Error] $($_.Exception.Message)"
        }

        Write-Host "[Informational] Printer $strPrinterName successfully installed"

        if($boolRestart){
            & shutdown /r /f /t 300
        }

    } else {
        Write-Warning "[Informational] Printer $strPrinterName already installed"
    }
}

function funcDownloadDriver {
    param (
        [Parameter(Mandatory=$True)]
        [String]$strDriverZipFileName,
        [Parameter(Mandatory=$True)]
        [String]$strDriverFileName,
        [Parameter(Mandatory=$True)]
        [String]$strDriverName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterPortName,
        [Parameter(Mandatory=$True)]
        [String]$strDownloadUrl,
        [Parameter(Mandatory=$True)]
        [String]$strFolderPath,
        [Parameter(Mandatory=$True)]
        [String]$strWorkingFolder,
        [Parameter(Mandatory=$True)]
        [String]$strOutfilePath
    )

    Write-Output "[Informational] Adding Printer $strPrinterName, Port $strPrinterPortName and Driver $strDriverName"
    
    # Check if a previous attempt failed, leaving the driver files in the temp directory. If so, remove existing installer and re-download.
    if (Test-Path $strFolderPath) {
        Remove-Item $strFolderPath
        Write-Output "[Informational] Removed $strFolderPath..."
    }

    # Download ZIP file and extract to specified location.
    # Check for required folder path and create if required.
    if (!(test-path -PathType container $strFolderPath)){
        New-Item -ItemType Directory -Path $strFolderPath
    }

    # Check for required working folder path and create if required.
    if(!(test-path -PathType container $strWorkingFolder)){
        New-Item -ItemType Directory -Path $strWorkingFolder
    }

    try {
        Write-Output "[Informational] Beginning download of $strDriverZipFileName to $strWorkingFolder"
        Invoke-WebRequest -OutFile "$strOutfilePath" $strDownloadUrl
    } catch {
        throw "[Error] Error Downloading - $($_.Exception.Response.StatusCode.value_)"
    }

    # Exract ZIP to Drivers folder.
    $strOutfilePath | Expand-Archive -DestinationPath "$strFolderPath" -Force
    # Remove temporary file.
    $strOutfilePath | Remove-Item
}

function funcRemovePrinter {
    param (
        [Parameter(Mandatory=$True)]
        [String]$strDriverName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterPortName
    )
    Write-Output "[Informational] Removing Printer $strPrinterName, Port $strPrinterPortName and Driver $strDriverName"
    try {
        Remove-Printer -Name "$strPrinterName" -Verbose
        Get-PrinterDriver -Name "$strDriverName" | Remove-PrinterDriver -Verbose
        Remove-PrinterPort -Name "$strPrinterPortName"
        Restart-Service -Name Spooler -Force
    }
    catch {
        throw "[Error] Failed to remove network printer $strPrinterName. Exception: $_"
    }
    
}
#endregion

#region Logic
if (-not (funcIsElevated)) {
    throw "[Error] Access Denied. Please run with Administrator privileges."
}

if ($boolRemove){
    funcRemovePrinter -driverName $strDriverName -printerName $strPrinterName -printerPortName $strPrinterPortName
} else {

    try {
        funcDownloadDriver -driverZipFileName $strDriverZipFileName -driverFileName $strDriverFileName -driverName $strDriverName -printerName $strPrinterName -printerPortName $strPrinterPortName -downloadUrl $strDownloadUrl -folderPath $strFolderPath -workingFolder $strWorkingFolder -outfilePath $strOutfilePath
    } catch {
        throw "[Error] Failed to download network printer $strPrinterName. Exception: $_"
    }
    
    try {
        funcInstallDriver -driverFileName $strDriverFileName -driverName $strDriverName -printerName $strPrinterName -printerPortName $strPrinterPortName -driverPath $strDriverPath -printerPort $strPrinterPort
    } catch {
        throw "[Error] Failed to add network printer $strPrinterName. Exception: $_"
    }
}
#endregion