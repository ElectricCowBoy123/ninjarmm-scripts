if ((Get-LocalUser -Name "Administrator").Enabled -eq $False) {
    try {
        $strUsername = "Administrator"
        Set-LocalUser -Name $strUsername -PasswordNeverExpires $True -Password (ConvertTo-SecureString -String $("DIT-" + ((Get-WmiObject -Query 'select * from SoftwareLicensingService').OA3xOriginalProductKey -Split '-')[0]) -AsPlainText -Force)
    }
    catch {
        throw "[Error] Exception occurred changing local administrator password: $($_.Exception.Message)"
    }
}