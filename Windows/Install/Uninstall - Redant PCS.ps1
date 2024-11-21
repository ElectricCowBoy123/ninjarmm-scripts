if($($env:uninstallOledbDriver).ToLower() -ne 'false' -and $($env:uninstallOledbDriver).ToLower() -ne 'true'){
    throw "[Error]: Invalid value supplied for Uninstall OLEDB Driver!"
}

if($($env:removeCredentialFromStore).ToLower() -ne "true" -and $($env:removeCredentialFromStore).ToLower() -ne "false"){
    throw "[Error]: Please provide a valid value for Remove Credential From Store!"
}

if($($env:shareServer).Length -gt 0 -and $($env:removeCredentialFromStore).ToLower() -ne "true"){
    throw "[Error]: Please supply a value for Remove Credential From Store!"
}

$libs=@(
    'C:\RedantPCS\c1sizerppg.dll',
    'C:\RedantPCS\c1Sizer.ocx',
    'C:\RedantPCS\Codejock.SkinFramework.v15.3.1.ocx',
    'C:\RedantPCS\emsmtp.dll',
    'C:\RedantPCS\emssl.dll',
    'C:\RedantPCS\ImageViewer2.ocx',
    'C:\RedantPCS\ScPro.ocx',
    'C:\RedantPCS\viscomgifenc.dll'
)

if($($env:removeCredentialFromStore).ToLower() -eq "true"){
    Write-Host "Removing Credential from Store..."
    if($(cmdkey /list) -like "*$env:shareServer*"){
        & cmdkey /delete:$env:shareServer
    }
}

if(Test-Path -Path "C:\RedantPCS\"){
    #Unregister DLLS
    Write-Host "Unregistering DLLs..."

    foreach($lib in $libs){
        Get-Process | Where-Object { $_.Modules -match [System.IO.Path]::GetFileName($lib) } | Stop-Process -Force
        try{& regsvr32 /s /u "$lib"}catch{throw "[Error]: Failed to un-register '$lib'"}
    }

    #Delete folder from C:\
    Write-Host "Deleting RedantPCS Folder..."
    try {
        Remove-Item -Path "C:\RedantPCS\" -Recurse -Force
    }
    catch {
        throw "[Error]: Failed to Delete 'C:\RedantPCS\' Details: $($_.Exception)"
    }
}
else {
    Write-Host "RedantPCS is Not Installed!"
    exit 0
}

#Remove Icons from Desktop
Write-Host "Removing Icons from Desktop..."
foreach($user in $(Get-ChildItem -Directory 'C:\Users') ){
    if($($user.Name) -eq 'Public'){
        if(Test-Path -Path "C:\Users\$($user.Name)\Public Desktop\DataCollection.lnk") {
            try{
                Remove-Item -Path "C:\Users\$($user.Name)\Public Desktop\DataCollection.lnk" -Recurse -Force
            }
            catch {
                throw "[Error]: Failed to Delete 'C:\Users\$($user.Name)\Public Desktop\DataCollection.lnk' Details: $($_.Exception)"
            }
        }
        if(Test-Path -Path "C:\Users\$($user.Name)\Public Desktop\WPCS.lnk"){
            try {
                Remove-Item -Path "C:\Users\$($user.Name)\Public Desktop\WPCS.lnk" -Recurse -Force
            }
            catch {
                throw "[Error]: Failed to Delete 'C:\Users\$($user.Name)\Public Desktop\WPCS.lnk' Details: $($_.Exception)"
            }
        }
    }
    else {
        if(Test-Path -Path "C:\Users\$($user.Name)\Desktop\DataCollection.lnk") {
            try {
                Remove-Item -Path "C:\Users\$($user.Name)\Desktop\DataCollection.lnk" -Recurse -Force
            }
            catch {
                throw "[Error]: Failed to Delete 'C:\Users\$($user.Name)\Desktop\DataCollection.lnk' Details: $($_.Exception)"
            }
        }
        if(Test-Path -Path "C:\Users\$($user.Name)\Desktop\WPCS.lnk"){
            try {
                Remove-Item -Path "C:\Users\$($user.Name)\Desktop\WPCS.lnk" -Recurse -Force
            }
            catch {
                throw "[Error]: Failed to Delete 'C:\Users\$($user.Name)\Desktop\WPCS.lnk' Details: $($_.Exception)"
            }
        }
    }
}

#Uninstall OLEDB Driver
if($($env:uninstallOledbDriver).ToLower() -eq 'true'){
    Write-Host "Uninstalling Microsoft SQL OLE DB Driver"
    try{
        $OLEDB=Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Microsoft OLE DB Driver for SQL Server" }
    }
    catch {
        throw "Failed to Retrieve Information about Currently Installed Microsoft SQL OLE DB Driver Version!"
    }

    if($OLEDB){
        try {
            $OLEDB.Uninstall()
        }
        catch {
            throw "[Error]: Failed to Uninstall Microsoft SQL OLEDB Driver $($_.Exception))"
        }
    }
    else {
        throw "[Error]: Cannot find Microsoft SQL OLEDB Driver! $($_.Exception)"
    }
}