Add-Type -AssemblyName System.Windows.Forms

function funcGetDesktopResolution {
    $objScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    return "{0}x{1}" -f $objScreen.Bounds.Width, $objScreen.Bounds.Height
}

# Example usage
$strCurrentResolution = funcGetDesktopResolution
Write-Host "[Informational] Current desktop resolution: $strCurrentResolution"

# Adjust desktop icon position script implement these resolutions
#1920x1080 
#1280x1024 <- This is what I already have
#1440x900