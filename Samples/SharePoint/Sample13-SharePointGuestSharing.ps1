<#
.SYNOPSIS
    Shares a specific SharePoint list item with an external guest user via Microsoft Graph.
    Sample for my post at https://blog-en.topedia.com/?p=64460. 

.DESCRIPTION
    This script shares a SharePoint list item (e.g. a document) with an external user by:
      1. Checking whether the guest already exists as a B2B user in Entra ID using their
         external UPN (email_domain#EXT#@tenant.onmicrosoft.com). If not found, a B2B
         invitation is sent via the Microsoft Graph Invitations API to register the guest
         in the tenant before sharing.
      2. Resolving the driveItem for the target list item via the Graph Sites API to obtain
         the Drive ID and Drive Item ID.
      3. Sharing the driveItem with the guest's email address via the Graph Drive Invite API,
         granting read access and sending a sharing notification email.

.NOTES
    Required Graph scopes (for delegated access): User.Read, User.Invite.All, Files.ReadWrite
    
    .Author: Tobias Asboeck - https://www.linkedin.com/in/tobiasasboeck/
    .Date: 2026-03-22    
#>

# Insert the missing information
$GuestEmail  = "<GuestEmailAddress>"
$SiteUrl     = "<SharePointSiteURL>"
$SiteListID  = "<SharePointListID>"
$ListItemID  = <SharePointListItemID>

Connect-MgGraph -Scopes "User.Read, User.Invite.All, Files.ReadWrite"

$SiteUri      = [System.Uri]$SiteUrl
$Hostname     = $SiteUri.Host
$SitePath     = $SiteUri.AbsolutePath

# Step 0: Check if the guest already exists in Entra ID. If not, invite the guest to Entra ID before sharing the item.
# The guest UPN format is email_domain#EXT#@tenantdomain.onmicrosoft.com, encoding is required for the # and @ characters when used in the Graph API URL.

# Splitting the email to get the domain part for constructing the guest UPN, which is required for checking if the guest already exists in Entra ID.
$TenantDomain  = $Hostname.Split('.')[0]
$GuestUPN      = ($GuestEmail -replace '@', '_') + "#EXT#@$TenantDomain.onmicrosoft.com"
$GuestUPNEncoded = [Uri]::EscapeDataString($GuestUPN)   # encodes # as %23

try {
    $ExistingGuestAccount = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/users/$GuestUPNEncoded`?`$select=id,mail,userType"
   
} catch {   
    
    Write-Host "Guest not found in Entra, creating B2B invitation"
    $B2BInvite = @{
        InvitedUserEmailAddress = $GuestEmail
        InviteRedirectUrl       = $SiteUrl # This is a mandatory property, but since we are not sending an invitation message, you can just put the site URL here or any other URL.        
        SendInvitationMessage   = $false # Invitation message to the guest is not required, as the guest will get an email from SharePoint about the shared document.
    } | ConvertTo-Json

    $InviteResult = Invoke-MgGraphRequest -Method Post `
        -Uri "https://graph.microsoft.com/v1.0/invitations" `
        -Body $B2BInvite `
        -ContentType "application/json"

    Write-Host "Guest user ID has been invited: $($InviteResult.invitedUser.id)"
}

# Step 1: Resolve the driveItem to get the drive ID and item ID
$DriveItem   = Invoke-MgGraphRequest -Method Get -Uri "https://graph.microsoft.com/v1.0/sites/$($Hostname):$($SitePath):/lists/$($SiteListID)/items/$($ListItemID)/driveItem"
$DriveId     = $DriveItem.parentReference.driveId
$DriveItemId = $DriveItem.id

# Step 2: Share the item with the external user via Graph — roles: "read" or "write"
$InviteBody = @{
    requireSignIn  = $true
    sendInvitation = $true
    roles          = @("read")
    recipients     = @(
        @{ email = $GuestEmail }
    )
    message        = "I would like to share this item with you."
} | ConvertTo-Json -Depth 4

$Response = Invoke-MgGraphRequest -Method Post `
    -Uri "https://graph.microsoft.com/v1.0/drives/$DriveId/items/$DriveItemId/invite" `
    -Body $InviteBody 

$Response.value | ConvertTo-Json
