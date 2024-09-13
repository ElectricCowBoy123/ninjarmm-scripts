param (
    [string]$strUsername = $env:usernamefield,
    [string]$strPassword = $env:password, # Ninja RMM doesn't support secure strings as parameters
    [string]$strFullName = $env:fullname,
    [string]$strDescription = $env:description
)

# Ensure arguments are of the correct type
foreach($arg in $args){
    if($arg.GetType().Name -ne 'String'){
        throw "[Error] Please enter a valid for $arg parameter 0 = False, 1 = True"    
    }
}

# Create a secure string for the password
$SecurePassword = ConvertTo-SecureString $strPassword -AsPlainText -Force

# Create the new local user
New-LocalUser -Name $strUsername -Password $SecurePassword -FullName $strFullName -Description $strDescription -PasswordNeverExpires -AccountNeverExpires

try {
    # Add the new user to the Administrators group
    Add-LocalGroupMember -Group "Administrators" -Member $strUsername
}
catch {
    throw "[Error] Failed to add user $strUsername to administrators group!"
}