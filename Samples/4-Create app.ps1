$Global:ClientId = ""
$Global:ClientSecret = ""
$Global:TenantId = ""

Connect-MSIntuneGraph -TenantID "" -ClientID "" -ClientSecret ""# Get MSI meta data from .intunewin file


$env:TEMP = "/tmp"
# Load all public and private functions
$ModuleRoot = "/Users/innio/Documents/IntuneWin32App"  # change this to your path

# Load Private functions (e.g. Invoke-IntuneGraphRequest)
Get-ChildItem -Path "$ModuleRoot/Private" -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

# Load Public functions (e.g. Add-IntuneWin32App)
Get-ChildItem -Path "$ModuleRoot/Public" -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}


$IntuneAppName = "Pandora_test"
$IntuneWinFile = "./Pandora_1_7_2.intunewin"

# Test-Path $IntuneWinFile
Write-Host "Looking for file at: $IntuneWinFile"
$IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile
$IntuneWinMetaData.ApplicationInfo | Format-List  

#Get the Win32 app ID if it exists (old app)
$Win32AppID = Get-IntuneWin32App -DisplayName $IntuneAppName  -Verbose | Select-Object -ExpandProperty "id"

if ($Win32AppID) {
    Write-Host "Found existing Win32 app with ID: $Win32AppID"
} else {
    Write-Host "No existing Win32 app found, creating a new one."
}

# Update the Win32 app if it exists
if ($Win32AppID) {
    Write-Host "Updating name of the existing Win32 app with ID: $Win32AppID"
    $Win32AppFileCommitBody = [ordered]@{
        "@odata.type" = "#microsoft.graph.win32LobApp"
        "displayName" = "(RETIRED) Test_pandora"
        "description" = "This app has been replaced by a new version. Please use the latest version."
    }
    Write-Host "Removing existing Win32 app assignment for ID: $Win32AppID"
    # Remove existing assignment before updating the app
    # This is necessary to avoid conflicts when updating the app
    Remove-IntuneWin32AppAssignment -ID $Win32AppID -Verbose
    $Win32AppFileCommitBodyRequest = Invoke-IntuneGraphRequest -APIVersion "Beta" -Resource "mobileApps/$($Win32AppID)" -Method "PATCH" -Body ($Win32AppFileCommitBody | ConvertTo-Json)
    Write-Host "Win32 app with ID: $Win32AppID updated successfully."
}

# Create custom display name like 'Name' and 'Version'
# $DisplayName = $IntuneWinMetaData.ApplicationInfo.Name + " " + "1.7.2"


$DetectionRule = New-IntuneWin32AppDetectionRuleRegistry -StringComparison -KeyPath "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Pandora_is1" -ValueName "DisplayVersion" -StringComparisonOperator "equal" -StringComparisonValue "1.7.2"
$DetectionRule | Format-List


# Create operative system requirement rule
$RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "x64" -MinimumSupportedOperatingSystem "W10_20H2"


# Create custom return code
# $ReturnCode = New-IntuneWin32AppReturnCode -ReturnCode 1618 -Type retry
# $ReturnCode | Format-List

$ImageFile = "pandora-app.png"
$Icon = New-IntuneWin32AppIcon -FilePath $ImageFile

# Construct a table of default parameters for the Win32 app
$Win32AppArgs = @{
    "FilePath" = $IntuneWinFile
    "DisplayName" = $IntuneAppName
    "Description" = "Uploaded via GitHub Actions"
    "Publisher" = "INNIO"
    "AppVersion" = "1.7.2"
    "InstallExperience" = "system"
    "RestartBehavior" = "suppress"
    "DetectionRule" = $DetectionRule
    "RequirementRule" = $RequirementRule
    # "ReturnCode" = $ReturnCode
    "Verbose" = $true
    "InstallCommandLine" = "Deploy-Application.exe -DeploymentType Install -DeployMode Silent"
    "UninstallCommandLine" = "Deploy-Application.exe -DeploymentType Uninstall -DeployMode Silent"
    "Owner" = "robert.unterrainer@innio.com"
    "Icon" = $Icon
    "Category" = "Productivity"
    "AllowAvailableUninstall" = $true
}

Add-IntuneWin32App @Win32AppArgs
Start-Sleep -Seconds 10
$Win32AppID = Get-IntuneWin32App -DisplayName $IntuneAppName  -Verbose | Select-Object -ExpandProperty "id"

# Remove-IntuneWin32AppAssignment -ID $Win32AppID -Verbose
Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32AppID -GroupID "4f9de69f-6808-4e19-b1ae-59244ca8bfec" -Intent "available" -Notification "showAll" -Verbose

# Remove-IntuneWin32AppAssignment -ID $Win32AppID -Verbose

