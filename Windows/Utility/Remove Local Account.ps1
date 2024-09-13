if ($env:removeUserDirectory -eq '1') {
    try {
        cmd.exe /c "NET USER "$env:usr" /DELETE"
    }
    catch {
        throw "[Error] Error deleting user $env:usr - $($_.Exception.Message)"
    }

    try {
        $strDirectory = "C:\Users\$env:usr"
        if (Test-Path $strDirectory) {
            Remove-Item -Path $strDirectory -Recurse -Force
            Write-Host "[Informational] Directory $strDirectory deleted successfully!"
        }
        else {
            Write-Host "[Informational] Directory $strDirectory doesn't exist!"
        }
    }
    catch {
        throw "[Error] Error deleting directory $strDirectory - $($_.Exception.Message)"
    }
}
elseif ($env:removeUserDirectory -eq '0') {
    try {
        cmd.exe /c "NET USER "$env:usr" /DELETE"
    }
    catch {
        throw "[Error] Error deleting user $env:usr - $($_.Exception.Message)"
    }
}
else {
    throw "[Error] Invalid value for 'removeUserDirectory'. Please enter '1' or '0'."
}