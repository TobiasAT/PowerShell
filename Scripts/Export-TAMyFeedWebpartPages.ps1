
<#
    .SYNOPSIS
    This PowerShell script connects to a SharePoint Online environment, iterates through all site collections, and identifies pages containing the "My Feed" web part.
    The My Feed web part will be retired in April 2025. 
    The script is for my post at https://blog-en.topedia.com/?p=46810.     

    .DESCRIPTION
    The script wants to use the PnP.PowerShell module with an Azure app authentication. 
    - The Azure app needs application permissions SharePoint - Sites.FullControl.All (required to fetch all site collections in the tenant). 
    - Do not forget to replace the placeholders with your own values or to replace the PnP connection method.
    
    The script performs the following steps:
    1. Connects to the SharePoint Online environment.
    2. Retrieves all site collections, excluding those with specific templates (`APPCATALOG#0` and `BLANKINTERNET#0`).
    3. Iterates through each site collection, connects to the site, and retrieves the `SitePages` library.
    4. If the `SitePages` library exists, retrieves all pages within the library.
    5. Attempts to retrieve the site owners from the associated SharePoint owner group.
    6. Iterates through each page, retrieves the page details, and checks for the presence of a specific web part (`WebPartId: 2f3b693c-1054-419c-af04-fee2782b414f` = the My Feed web part).
    7. Collects various details about the page (e.g., site collection name, URL, owners, page title, page ID, page URL, and web part count) if the web part is found. 
       The web part count should indicate the number of My Feed web parts on the page.
    8. Exports the collected information to a CSV file in the user's `Documents` folder with a filename that includes the current date. 
    
    .EXAMPLE
    .\Export-TAMyFeedWebpartPages.ps1

    .NOTES
        Author: Tobias Asböck - https://www.linkedin.com/in/tobiasasboeck
        Date: 19 February 2025
#>

# Ensure the required module is available
#requires -Module PnP.PowerShell

######################################
# 
# Replace the placeholders with your own values or replace the PnP connection method with your own
    $SPOAdminUrl = "https://<Tenant>-admin.sharepoint.com/" # e.g. https://yourtenant-admin.sharepoint.com
    $ClientID = "<AzureAppID>"
    $CertThumbprint = "<CertThumbprint>"
    $TenantID = "<TenantID>"
#
######################################

Import-Module PnP.PowerShell
Connect-PnPOnline -Url $SPOAdminUrl -ClientId $ClientID -Thumbprint $CertThumbprint  -Tenant $TenantID 

Write-Host "Retrieving all site collections..." -f Yellow
$AllSPOSites = Get-PnPTenantSite  | ?{$_.Template -ne "APPCATALOG#0" -and $_.Template -ne "BLANKINTERNET#0" }

$AllMyFeedWebPartPages = @()  # Initialize an array to store pages with the My Feed web part
$Date = Get-Date -Format "dd-MM-yyyy"  
$SiteCount = 1 

# Iterate through each site collection
foreach($SPOSite in $AllSPOSites)
{ 
    Write-Host "Site $SiteCount of $($AllSPOSites.Count) - $($SPOSite.Url)" -f Yellow  

    # Connect to the current site collection
    Connect-PnPOnline -Url $SPOSite.Url -ClientId $ClientID -Thumbprint $CertThumbprint  -Tenant $TenantID 
    
    # Retrieve the SitePages library
    $SitePagesLibrary = Get-PnPList | ?{$_.EntityTypeName -eq "SitePages"}

    if($SitePagesLibrary.Count -eq 1) {
        
        # Retrieve all pages in the SitePages library
        $AllSitePages = Get-PnPListItem -List $SitePagesLibrary -PageSize 1000      
        

        try{ 
            
            # Attempt to retrieve the site owners from the associated owner group
            $OwnerGroup = Get-PnPGroup -AssociatedOwnerGroup
            $SiteOwners = Get-PnPGroupMember -Identity $OwnerGroup | ?{$_.LoginName -like "*|membership|*"} 
        } catch {
            $SiteOwners = @()  # If an error occurs, initialize an empty array for site owners (e.g. if the owner group is not associated)
        }       

        if($SiteOwners.Count -gt 0) {
            $SiteOwners = $SiteOwners.LoginName -join "; "  # Join the site owners' login names into a single string
        } else {
            $SiteOwners = $null  # Set site owners to null if none are found
        }   

        # Get the current web context for web details
        $SPWeb = Get-PnPWeb  
         
        # Iterate through each page in the SitePages library
        $PageCount = 1 
        foreach($SitePage in $AllSitePages)
        {
            Write-Host "  Page $PageCount of $($AllSitePages.Count) - $($SitePage.FieldValues.FileLeafRef)"  
            
            try{ 
                # Attempt to retrieve the page details
                $PnPPage = Get-PnPPage -Identity $SitePage.FieldValues.FileLeafRef 
            } catch { 
                $PnPPage = @()  # If an error occurs, initialize an empty array for the page (if the page is not found, e.g. for multilingual pages)
            }
            
            if($PnPPage.Count -eq 1) {
                
                # Check for the presence of the My Feed web part on the page
                $MyFeedWebPart = Get-PnPPageComponent -Page $PnPPage | Where-Object { $_.WebPartId -eq "2f3b693c-1054-419c-af04-fee2782b414f" }

                if($MyFeedWebPart.Count -gt 0) {
                    
                    # Construct the full URL of the page
                    $PageFullUrl = $SitePage.FieldValues.FileRef.Replace($SPWeb.ServerRelativeUrl,"")
                    $PageFullUrl = ($SPWeb.Url + $PageFullUrl)

                    # Create a new object to store the page details
                    $MyFeedWebPartPage = New-Object -TypeName PSObject
                    $MyFeedWebPartPage | Add-Member -MemberType NoteProperty -Name SiteCollectionName -Value $SPWeb.Title
                    $MyFeedWebPartPage | Add-Member -MemberType NoteProperty -Name SiteCollectionUrl -Value $SPWeb.Url 
                    $MyFeedWebPartPage | Add-Member -MemberType NoteProperty -Name SiteCollectionOwners -Value $SiteOwners  
                    $MyFeedWebPartPage | Add-Member -MemberType NoteProperty -Name PageTitle -Value $PnPPage.PageTitle
                    $MyFeedWebPartPage | Add-Member -MemberType NoteProperty -Name PageID -Value $PnPPage.PageId
                    $MyFeedWebPartPage | Add-Member -MemberType NoteProperty -Name PegeUrl -Value $PnPPage.Name
                    $MyFeedWebPartPage | Add-Member -MemberType NoteProperty -Name PageFullUrl -Value $PageFullUrl 
                    $MyFeedWebPartPage | Add-Member -MemberType NoteProperty -Name WebpartCount -Value $MyFeedWebPart.Count
                    $AllMyFeedWebPartPages += $MyFeedWebPartPage  
                }  
            }
            $PageCount++  
        }
    }
    $SiteCount++  
}

# Export the collected information to a CSV file and output the path
$ExportPath = ([Environment]::GetFolderPath('MyDocuments') + "\SPOMyFeedPages-$Date.csv")    
$AllMyFeedWebPartPages | Export-Csv -Path $ExportPath -NoTypeInformation -Force
Write-Host "ExportPath: $ExportPath"  

