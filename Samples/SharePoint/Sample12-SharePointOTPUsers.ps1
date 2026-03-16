
<#
.SYNOPSIS
    Retrieves all OTP (email authentication guest) users across all SharePoint and OneDrive site collections in a tenant.
    Sample for my post at https://blog-en.topedia.com/?p=64003. 

.DESCRIPTION
    Connects to the SharePoint admin center using an Azure App with application permissions and iterates over every site collection,
    including OneDrive sites. For each site, it queries the siteusers endpoint for users authenticated via email OTP (IsEmailAuthenticationGuestUser).
    Additional details such as the account creation date are enriched from the User Information List.

.NOTES
    .Author: Tobias Asboeck - https://www.linkedin.com/in/tobiasasboeck/
    .Date: 2026-03-16

#>

# Connect with an Azure App amd Application Permissions AllSites.FullControl to get all SharePoint and OneDrive site collections
Connect-PnPOnline -Url "https://<Tenant>-admin.sharepoint.com" -ClientId <AzureAppID> -Thumbprint <Thumbprint> -Tenant <TenantID> 

$AllSites = Get-PnPTenantSite -IncludeOneDriveSites

$AllSPOOTPUsers = @()
$Count = 1
foreach ($Site in $AllSites ) {
    Write-Host "$Count of $($AllSites.Count) - $($Site.Url)"
    
    # Get all site users with email authentication guest users (OTP) 
    $AllOTPUsers = @()
    $NextUrl = "$($Site.Url)/_api/web/siteusers?`$filter=IsEmailAuthenticationGuestUser eq true&`$select=Id,Title,Email,LoginName,IsShareByEmailGuestUser,IsEmailAuthenticationGuestUser&`$top=1000"

    # In some cases, sites are no longer accessible (e.g. legacy sites such as SharePoint Public Site) and the REST call can fail, so I  wrap it in a try-catch to avoid the script breaking.
    try {
        do {
            $SiteUsers = Invoke-PnPSPRestMethod -Method Get -Url $NextUrl
            $AllOTPUsers += $SiteUsers.value
            $NextUrl = $SiteUsers.'@odata.nextLink'
        } while ($NextUrl)

    }
    catch {
        Write-Warning "Skipping $($Site.Url) - failed to get site users: $_"
        continue
    }

    if($AllOTPUsers.Count -gt 0) {    

        # Get the User Information List for the site to retrieve additional user details (like created date) since the siteusers endpoint does not provide that information.
        $Url = "$($Site.Url)/_api/web/lists?`$filter=ListItemEntityTypeFullName eq 'SP.Data.UserInfoItem'&`$select=Id,Title"
        $UserInfoList = Invoke-PnPSPRestMethod -Method Get -Url $Url 

        # Get all users from the User Information List with a non-null and non-empty EMail field (to exclude system groups or other objects) and retrieve their created date.
        $NextUrl = "$($Site.Url)/_api/web/lists(guid'$($UserInfoList.value.id)')/items?`$filter=EMail ne null and EMail ne ''&`$select=Id,EMail,Created&`$top=1000"
        $UserInfoListUsers = @()
        do {
            $data = Invoke-PnPSPRestMethod -Method Get -Url $NextUrl
            $UserInfoListUsers += $data.value
            $NextUrl = $data.'@odata.nextLink'
        } while ($NextUrl)

        foreach ($User in $AllOTPUsers) {        
            $SPOOTPUser = New-Object -TypeName PSObject
            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name SiteURL -Value  $Site.Url   
            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name SiteID -Value $Site.SiteId.Guid
            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name SiteTitle -Value $Site.Title

            if($Site.Url -like "*my.sharepoint.com/personal*") {
                $SPOOTPUser | Add-Member -MemberType NoteProperty -Name SiteType -Value "OneDrive"
            } else {
                $SPOOTPUser | Add-Member -MemberType NoteProperty -Name SiteType -Value "SharePoint"
            }

            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name SiteUserID -Value $User.Id 

            $UserCreatedinUIL = $UserInfoListUsers | ?{ $_.Id -eq $User.Id }
            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name SiteUserCreated -Value $UserCreatedinUIL.Created
            $UserLoginName = [System.Uri]::UnescapeDataString($User.LoginName)
            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name UserLoginName -Value $UserLoginName
            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name UserEmail -Value $User.Email
            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name UserEmailDomain -Value ($User.Email -split '@')[1]
            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name UserDisplayName -Value $User.Title        
            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name UserIsShareByEmailGuestUser -Value $User.IsShareByEmailGuestUser
            $SPOOTPUser | Add-Member -MemberType NoteProperty -Name UserIsEmailAuthenticationGuestUser -Value $User.IsEmailAuthenticationGuestUser        
            
            # Check if the user has an Entra ID account (if the user profile can be retrieved via PnP PowerShell)
            try{  Get-PnPUserProfileProperty -Account $User.Email | Out-Null
                $SPOOTPUser | Add-Member -MemberType NoteProperty -Name IsEntraAccount -Value  $true
            }
            catch { $SPOOTPUser | Add-Member -MemberType NoteProperty -Name IsEntraAccount -Value  $false }

            # Get the last OTP login time for the user in the last 180 days from the Audit Log Query results
            $LastOTPTime = ($AuditLogNewQueryResultRecords | ? { $_.userPrincipalName -eq ($UserLoginName -split '\|')[-1] } | sort createdDateTime -Descending | select -First 1 ).createdDateTime   
            if($LastOTPTime -ne $null) {
                $SPOOTPUser | Add-Member -MemberType NoteProperty -Name LastSPOOTPLogin180Days -Value (Get-Date $LastOTPTime).ToString("yyyy-MM-ddTHH:mm:ssZ")
            } else {
                $SPOOTPUser | Add-Member -MemberType NoteProperty -Name LastSPOOTPLogin180Days -Value $null
            }
            $AllSPOOTPUsers += $SPOOTPUser
        }
    }     
    $Count++

}

# Export the results to a CSV file
$Date = Get-Date -Format "dd-MM-yyyy"
$ExportPath = ([Environment]::GetFolderPath('MyDocuments') + "\SPOOTPGuestUsers-$Date.csv")    
$AllSPOOTPUsers | Export-Csv -Path $ExportPath -NoTypeInformation -Force
Write-Host "ExportPath: $ExportPath"

Disconnect-PnPOnline
