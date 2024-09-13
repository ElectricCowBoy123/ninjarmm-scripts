function funcRemoveUWPApp() {
    <# Removes UWP apps used by funcRemoveBloatware#>

    param (
        [Parameter(Mandatory)]
        [String[]] $strAAppxPackages
    )

    $Script:TweakType = "App"
    
    ForEach ($strAppxPackage in $strAAppxPackages) {
        If (!((Get-AppxPackage -AllUsers -Name "$strAppxPackage") -or (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "$strAppxPackage"))) {
            Continue
        }

        Get-AppxPackage -AllUsers -Name "$strAppxPackage" | Remove-AppxPackage
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "$strAppxPackage" | Remove-AppxProvisionedPackage -Online -AllUsers
    }
}

$strHTApps = @(
    # Microsoft Apps
    "Microsoft.3DBuilder"                    
    "Microsoft.549981C3F5F10"               
    "Microsoft.Appconnector"
    "Microsoft.BingFinance"                 
    "Microsoft.BingFoodAndDrink"          
    "Microsoft.BingHealthAndFitness"        
    "Microsoft.BingNews"                   
    "Microsoft.BingSports"                  
    "Microsoft.BingTranslator"              
    "Microsoft.BingTravel"                  
    "Microsoft.BingWeather"                 
    "Microsoft.CommsPhone"
    "Microsoft.ConnectivityStore"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftSolitaireCollection" 
    "Microsoft.MixedReality.Portal"
    "Microsoft.NetworkSpeedTest"            
    "Microsoft.Office.Sway"
    "Microsoft.OneConnect"              
    "Microsoft.People"                             
    "Microsoft.Print3D"                     
    "Microsoft.SkypeApp"                     
    "Microsoft.Todos"                       
    "Microsoft.Wallet"
    "Microsoft.Whiteboard"                  
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"          
    "Microsoft.WindowsMaps"                  
    "Microsoft.WindowsPhone"
    "Microsoft.WindowsReadingList"
    "Microsoft.WindowsSoundRecorder"         
    "Microsoft.XboxApp"                     
    "Microsoft.YourPhone"                    
    "Microsoft.ZuneMusic"                   
    "Microsoft.ZuneVideo"                   
    "Microsoft.Advertising.Xaml"
    "Clipchamp.Clipchamp"				     
    "MicrosoftWindows.Client.WebExperience"  
    "MicrosoftTeams" 
    # Other Apps

    #Sponsored Windows 10 AppX Apps
    #Add sponsored/featured apps to remove in the "*AppName*" format
    "*EclipseManager*"
    "*ActiproSoftwareLLC*"
    "*AdobeSystemsIncorporated.AdobePhotoshopExpress*"
    "*Duolingo-LearnLanguagesforFree*"
    "*PandoraMediaInc*"
    "*CandyCrush*"
    "*BubbleWitch3Saga*"
    "*Wunderlist*"
    "*Flipboard*"
    "*Twitter*"
    "*Facebook*"
    "*Spotify*"
    "*Minecraft*"
    "*Royal Revolt*"
    "*Sway*"
    "*Speed Test*"
    "*Dolby*"
)

# Get-AppxPackage -AllUsers | Select Name

funcRemoveUWPApp -strAAppxPackages $strHTApps