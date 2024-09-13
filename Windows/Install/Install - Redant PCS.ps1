$strAppDisplayName="Redant PCS"

function Get-MSOLEDDB-Version {
    $regKey="HKLM:\SOFTWARE\Microsoft\MSOLEDBSQL"
    if ((Test-Path $regKey)) {
        return (Get-ItemProperty -Path $regKey -Name 'InstalledVersion').InstalledVersion
    }
    else {
        return "N/A"
    }
}

function Test-Share-FileStructure {
    param (
        [parameter(Mandatory=$True)]
        [String]$sharePath
    )

    if(-not (Test-Path -Path $sharePath)){
        throw "Share '$sharePath' Not Accessible, Try using IP instead!"
    }

    if(-not (Test-Path -Path "$sharePath\Install")){
        throw "Share '$sharePath\Install' Doesn't Exist!"
    }

    if(-not (Test-Path -Path "$sharePath\Install\ClientSetup")){
        throw "Share '$sharePath\Install\ClientSetup' Doesn't Exist!"
    }

    if(-not (Test-Path -Path "$sharePath\Install\SQL2022")){
        throw "Share '$sharePath\Install\SQL2022' Doesn't Exist!"
    }

    Write-Host "File Structure OK."
}

Write-Host "Adding Credential to Store..."
if($(cmdkey /list) -like "*$env:shareServer*"){
    Write-Host "Credential Already Stored, Removing."
    & cmdkey /delete:$env:shareServer
}
else {
    try {
        & cmdkey /add:$env:shareServer /user:%$env:shareServer%\$env:shareUser /pass:$env:sharePass # TEMPORARY
    }
    catch {
        throw "[Error]: Failed to add Credential to Store! Details: $($_.Exception)"
    }
}

Write-Host "Checking Share Directory Structure..."
try {
    Test-Share-FileStructure -sharePath "\\$env:shareServer\$env:shareName"
}
catch {
    throw "[Error]: Failed to Verify Filestructure! Details: $($_.Exception)"
}

$objDirsInC= Get-ChildItem -Path "C:\" -Directory

if (-not ($objDirsInC | Where-Object { $_.Name -eq "RedantPCS" })) {
    Write-Host "Executing RedantSetup.exe..."
    
    try {
        $redAntSetupPath="\\$env:shareServer\$env:shareName\Install\ClientSetup\RedantSetup.exe"
        Start-Process -FilePath "$redAntSetupPath" -ArgumentList "/s" -Wait -NoNewWindow
    } 
    catch {
        throw "[Error]: Failed to Execute '$redAntSetupPath' Details: $($_.Exception)"
    }

    $boolIsInstalled=$False

    while($boolIsInstalled -eq $False){
        Start-Sleep -Seconds 8
        $objDirsInC= Get-ChildItem -Path "C:\" -Directory
        if (($objDirsInC | Where-Object { $_.Name -eq "RedantPCS" })) {
            $boolIsInstalled=$True
            $strMSOLEDBVersion = Get-MSOLEDDB-Version
            # TODO: integrate version checking here
            if($strMSOLEDBVersion -eq "N/A"){
                Write-Host "Installing MSOLEDBSQL Driver..."

                try {
                    Start-Process -FilePath "\\$env:shareServer\$env:shareName\Install\SQL2022\msoledbsql.msi" -ArgumentList "/quiet" -Wait -NoNewWindow
                } 
                catch {
                    throw "[Error]: Failed to Install msoledbsql Driver for '$strAppDisplayName' Details: $($_.Exception)"
                }
            }
            else {
                Write-Host "MSOLEDB Is already installed, skipping..."
            }

            Write-Host "Copying RedAntPCS.txt to C:\RedantPCS..."
            try{
                Copy-Item -Path "\\$env:shareServer\$env:shareName\Install\RedAntPCS.txt" -Destination "C:\RedantPCS\RedAntPCS.txt" -Force
            }
            catch {
                throw "[Error]: Failed to copy configuration file from \\$env:shareServer\$env:shareName\Install\RedAntPCS.txt to C:\RedantPCS\RedAntPCS.txt Details: $($_.Exception)"
            }

            Write-Host "Creating Shortcut on Desktop..."

            try {
                # Ensure the WScript.Shell COM object can be created
                $objWScriptShell = New-Object -ComObject WScript.Shell

                # Define shortcut paths
                $desktopPath = "C:\Users\Public\Desktop"
                $wpcsShortcutPath = "$desktopPath\WPCS.lnk"
                $dataCollectionShortcutPath = "$desktopPath\DataCollection.lnk"
                $targetPath = "\\$env:shareServer\$env:shareName\Install"

                # Create the WPCS shortcut
                $shortcut = $objWScriptShell.CreateShortcut($wpcsShortcutPath)
                $shortcut.TargetPath = "$targetPath\WPCS.exe"
                $shortcut.Arguments = ""
                $shortcut.WorkingDirectory = $targetPath
                $shortcut.IconLocation = "$targetPath\WPCS.exe"
                $shortcut.Save()
                Write-Host "Shortcut WPCS.lnk created successfully."

                # Create the DataCollection shortcut
                $shortcut = $objWScriptShell.CreateShortcut($dataCollectionShortcutPath)
                $shortcut.TargetPath = "$targetPath\DataCollection.exe"
                $shortcut.Arguments = ""
                $shortcut.WorkingDirectory = $targetPath
                $shortcut.IconLocation = "$targetPath\DataCollection.exe"
                $shortcut.Save()
                Write-Host "Shortcut DataCollection.lnk created successfully."
            }
            catch {
                Write-Host "[Error]: Failed to Create Shortcuts. Details: $($_.Exception.Message)"
            }

            Write-Host "Registering DLLs..."
            try{& regsvr32 /s 'C:\RedantPCS\c1sizerppg.dll'}catch{throw "Failed to register c1sizerppg.dll"}
            try{& regsvr32 /s 'C:\RedantPCS\c1Sizer.ocx'}catch{throw "Failed to register c1Sizer.ocx"}
            try{& regsvr32 /s 'C:\RedantPCS\Codejock.SkinFramework.v15.3.1.ocx'}catch{throw "Failed to register Codejock.SkinFramework.v15.3.1.ocx"}
            try{& regsvr32 /s 'C:\RedantPCS\emsmtp.dll'}catch{throw "Failed to register emsmtp.dll"}
            try{& regsvr32 /s 'C:\RedantPCS\emssl.dll'}catch{throw "Failed to register emssl.dll"}
            try{& regsvr32 /s 'C:\RedantPCS\ImageViewer2.ocx'}catch{throw "Failed to register ImageViewer2.ocx"}
            try{& regsvr32 /s 'C:\RedantPCS\ScPro.ocx'}catch{throw "Failed to register ScPro.ocx"}
            try{& regsvr32 /s 'C:\RedantPCS\viscomgifenc.dll'}catch{throw "Failed to register viscomgifenc.dll"}

            Write-Host "Install Completed!"
        }
    }
}
else {
    Write-Host "RedantPCS is Already Installed!"
    exit 0
}