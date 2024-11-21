if ((Get-LocalUser -Name "Administrator").Enabled -eq $False) {
    try {
        $strUsername = "Administrator"
        # Enable the local "Administrator" account
        Enable-LocalUser -Name $strUsername

        # ((Get-WmiObject -Query "SELECT * FROM SoftwareLicensingService").OA3xOriginalProductKey)[-5..-1] -join ""

        # Set the user's password to never expire and enable changing password
        Set-LocalUser -Name $strUsername -PasswordNeverExpires $True -Password (ConvertTo-SecureString -String $("DIT-" + ((Get-WmiObject -Query 'select * from SoftwareLicensingService').OA3xOriginalProductKey -Split '-')[0]) -AsPlainText -Force)

        # Force password change at next login using cmd commands
        $strCmd1 = "wmic UserAccount where name='$strUsername' set Passwordexpires=true"
        $strCmd2 = "net user $strUsername /logonpasswordchg:yes /passwordreq:yes"
        
        & cmd /c $strCmd1
        & cmd /c $strCmd2
    }
    catch {
        throw "[Error] Exception occurred enabling local administrator account: $($_.Exception.Message)"
    }
} else {
    Write-Host "[Informational] Administrator Account Already Enabled!"
}