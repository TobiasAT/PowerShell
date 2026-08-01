
# This script is a sample for migrating Microsoft Whiteboard data. It retrieves non-migrated whiteboards from different geographies (Europe, Worldwide, and Australia), 
# resolves the owners of these whiteboards using Microsoft Graph, and exports the results to a CSV file for further analysis.
# The WhiteboardAdmin module is required for this script: https://www.powershellgallery.com/packages/WhiteboardAdmin
# For my blog post at https://blog-en.topedia.com/?p=70934.

#require -Module WhiteboardAdmin

# Prepare the environment for the Whiteboard migration report
$TenantId = "<Your Tenant ID>" 
$ClientId = "<Your Client ID>" 
$CertThumbprint = "<Your Certificate Thumbprint>" 
$LocalFolderPath = "C:\Temp\WhiteboardMigration" # Change this to your preferred local folder path for storing whiteboard migration data.

$NonMigratedWhiteboardsFilePath_EU = "$LocalFolderPath\Whiteboards-NonMigrated-EU.txt"
$NonMigratedRunName_EU = [IO.Path]::GetFileNameWithoutExtension($NonMigratedWhiteboardsFilePath_EU) -replace '^Whiteboards-'

$NonMigratedWhiteboardsFilePath_WW = "$LocalFolderPath\Whiteboards-NonMigrated-WW.txt"
$NonMigratedRunName_WW = [IO.Path]::GetFileNameWithoutExtension($NonMigratedWhiteboardsFilePath_WW) -replace '^Whiteboards-'

$NonMigratedWhiteboardsFilePath_AU = "$LocalFolderPath\Whiteboards-NonMigrated-AU.txt"
$NonMigratedRunName_AU = [IO.Path]::GetFileNameWithoutExtension($NonMigratedWhiteboardsFilePath_AU) -replace '^Whiteboards-'

# Get the list of non-migrated whiteboards for all geographies. Force an authentication prompt for the first request.
# The account needs at least the SharePoint Administrator role to access the whiteboard data.

Import-Module WhiteboardAdmin
if (-not (Test-Path -Path $LocalFolderPath)) {
    New-Item -Path $LocalFolderPath -ItemType Directory | Out-Null
}
Set-Location -Path $LocalFolderPath
Get-WhiteboardsForTenant -Geography Europe -IncrementalRunName $NonMigratedRunName_EU -ForceAuthPrompt

Get-WhiteboardsForTenant -Geography Worldwide -IncrementalRunName $NonMigratedRunName_WW 
Get-WhiteboardsForTenant -Geography Australia -IncrementalRunName $NonMigratedRunName_AU 

# Combine the non-migrated whiteboard data from all geographies into a single collection for further processing.
$FileContentNonMigrated_All = Get-Content -Path $NonMigratedWhiteboardsFilePath_EU, $NonMigratedWhiteboardsFilePath_WW, $NonMigratedWhiteboardsFilePath_AU | ForEach-Object {
    $_ | ConvertFrom-Json
}

if (@($FileContentNonMigrated_All).Count -eq 0) {
    Write-Host "No non-migrated Whiteboards found." -foregroundcolor Green
} else {
    $FileContentNonMigrated_All 
}

# Connect to Microsoft Graph using the provided client ID, certificate thumbprint, and tenant ID for authentication.
Connect-MgGraph -ClientId $ClientId -CertificateThumbprint $CertThumbprint -TenantId $TenantId -NoWelcome

# Resolve owner IDs to a readable identity via Microsoft Graph, caching lookups since many boards share the same owner.
# Also flags owners who no longer exist in Entra (orphaned whiteboards) and whether their account is enabled.
$OwnerAccountInfo = @{}
function Resolve-WhiteboardOwner {
    param([string]$OwnerId)

    # If the owner ID is null or empty, return a custom object indicating that the whiteboard is orphaned.
    if (-not $OwnerId) {
        return [PSCustomObject]@{
            DisplayName       = $null
            UserPrincipalName = $null
            AccountEnabled    = $null
            Status            = "No owner (orphaned Whiteboard)"
        }
    }
    if (-not $OwnerAccountInfo.ContainsKey($OwnerId)) {
        try {
            # Attempt to retrieve the user information from Microsoft Graph using the provided owner ID.
            $user = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$OwnerId`?`$select=displayName,userPrincipalName,accountEnabled" -ErrorAction Stop
            $OwnerAccountInfo[$OwnerId] = [PSCustomObject]@{
                DisplayName       = $user.displayName
                UserPrincipalName = $user.userPrincipalName
                AccountEnabled    = $user.accountEnabled
                Status            = "Found in Entra ID"
            }
        } catch {
            # If the user is not found, cache the result as "Not found in Entra ID" with null values for display name and UPN.
            $OwnerAccountInfo[$OwnerId] = [PSCustomObject]@{
                DisplayName       = $null
                UserPrincipalName = $null
                AccountEnabled    = $null
                Status            = "Not found in Entra ID"
            }
        }
    }
    return $OwnerAccountInfo[$OwnerId]
}

# Report the whiteboards from Azure, with the owner resolved to a readable identity
$Count = 1
$AzureWhiteboardResults = foreach ($Board in $FileContentNonMigrated_All) {
    
    $boardTitle = if ([string]::IsNullOrWhiteSpace($Board.title)) { "No title" } else { $Board.title }
    Write-host ("Board $Count of $($FileContentNonMigrated_All.Count) - $($Board.id) ($boardTitle)")    
    $owner = Resolve-WhiteboardOwner -OwnerId $Board.ownerId

    [PSCustomObject]@{
        WhiteboardId         = $Board.id
        Title                = $Board.title
        Created              = $Board.createdTime        
        isShared             = $Board.isShared
        GlobalLastViewedTime = $Board.globalLastViewedTime
        APIEndpoint          = $Board.baseApi
        OwnerId              = $Board.ownerId
        OwnerUPN             = $owner.UserPrincipalName
        OwnerDisplayName     = $owner.DisplayName       
        OwnerAccountEnabled  = $owner.AccountEnabled
        OwnerStatus          = $owner.Status
    }
    $Count++
}

# Export the whiteboard results to a CSV file
$Date = Get-Date -Format "dd-MM-yyyy"
$ExportPath = "$LocalFolderPath\WhiteboardMigrationStatus-$Date.csv"
$AzureWhiteboardResults | Sort-Object Created | Export-Csv -Path $ExportPath -NoTypeInformation -Force
Write-Host "ExportPath: $ExportPath"


