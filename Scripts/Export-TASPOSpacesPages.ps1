
<#
    .SYNOPSIS
    This PowerShell script connects to a SharePoint Online environment, iterates through all site collections, and identifies pages with the "Space" content type.
    SharePoint Spaces will be retired in August 2025. 
    The script is for my post at https://blog-en.topedia.com/?p=46967.     

    .DESCRIPTION
    The script uses the PnP.PowerShell module with Azure app authentication. 
    - The Azure app needs the application permissions SharePoint - Sites.FullControl.All (required to fetch all site collections in the tenant). 
    - Do not forget to replace the placeholders with your own values or to replace the PnP connection method.
    
    The script performs the following steps:
    1. Connects to the SharePoint Online environment.
    2. Retrieves all site collections, excluding those with specific templates (`APPCATALOG#0` and `BLANKINTERNET#0`).
    3. Iterates through each site collection, connects to the site, and retrieves the `SitePages` library.
    4. If the `SitePages` library exists, retrieves all pages within the library.
    5. Filters the pages by the "Space" content type.
    6. Attempts to retrieve the site owners from the associated SharePoint owner group.
    7. Iterates through each page, retrieves the page details, and collects various details about the page (e.g., site collection name, URL, owners, page title, page ID, page URL).
    8. Exports the collected information to a CSV file in the user's `Documents` folder with a filename that includes the current date. 
    
    .EXAMPLE
    .\Export-TASPOSpacesPages.ps1

    .NOTES
        Author: Tobias Asböck - https://www.linkedin.com/in/tobiasasboeck
        Date: 24 February 2025
#>

# Ensure the required module is available
#requires -Module PnP.PowerShell

######################################
# 
# Replace the placeholders with your own values or replace the PnP connection method
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

$AllSpacePages = @()  # Initialize an array to store all Spaces pages
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
        $SpaceCT = Get-PnPContentType | ?{$_.Name -eq "Space" }          
        if($SpaceCT.Count -eq 1 ) {
            $AllSpacesPages = Get-PnPListItem -List $SitePagesLibrary -PageSize 1000 | ?{ $_.FieldValues["ContentTypeId"].StringValue -like "$($SpaceCT.Id.StringValue)*" }         
        } else {
            $AllSpacesPages = @()
        }

        if($AllSpacesPages.Count -gt 0) {           

            try{                 
                # Attempt to retrieve the site owners from the associated owner group                
                $OwnerGroup = Get-PnPGroup -AssociatedOwnerGroup       
            } catch {
                $AllSiteOwners = $null  # If an error occurs, set the site owners to null (e.g. if the owner group is not associated)
            }    
                        
            if($OwnerGroup.Count -eq 1) {               
                
                # First, get the owners from the SharePoint site
                $AllSiteOwners = @()
                $SiteOwners = (Get-PnPGroupMember -Identity $OwnerGroup | ?{$_.LoginName -like "*|membership|*"}).LoginName
                if($SiteOwners.Count -gt 0) {
                    $SiteOwners = $SiteOwners -replace "i:0#.f\|membership\|", ""
                    $AllSiteOwners += $SiteOwners
                } 
                
                # Second, get the owners from the M365 group (for group-connected SharePoint sites)
                $M365Group = (Get-PnPGroupMember -Identity $OwnerGroup | ?{$_.LoginName -like "*|federateddirectoryclaimprovider|*"}).LoginName
                if($M365Group.Count -eq 1) {
                    $M365Group = $M365Group.Substring($M365Group.LastIndexOf("|") + 1)
                    $M365GroupID = $M365Group.Substring(0,$M365Group.IndexOf("_"))
                    
                    $M365GroupOwners = Get-PnPMicrosoft365GroupOwner -Identity $M365GroupID
                    $AllSiteOwners += $M365GroupOwners.UserPrincipalName
                }                
                
                $AllSiteOwners = $AllSiteOwners -join "; "      
                
            } else {
                $AllSiteOwners = $null  # If the owner group is not found, set the site owners to null
            }         

            # Get the current web context for web details
            $SPWeb = Get-PnPWeb  
            
            # Iterate through each page in the SitePages library
            $PageCount = 1 
            foreach($SitePage in $AllSpacesPages)
            {
                Write-Host "  Page $PageCount of $($AllSpacesPages.Count) - $($SitePage.FieldValues.FileLeafRef)"  
                
                try{ 
                    # Attempt to retrieve the page details
                    $PnPPage = Get-PnPPage -Identity $SitePage.FieldValues.FileLeafRef 
                } catch { 
                    $PnPPage = @()  # If an error occurs, initialize an empty array for the page (if the page is not found, e.g. for multilingual pages)
                }
                
                if($PnPPage.Count -eq 1) {                     

                    # Construct the full URL of the page
                    $PageFullUrl = $SitePage.FieldValues.FileRef.Replace($SPWeb.ServerRelativeUrl,"")
                    $PageFullUrl = ($SPWeb.Url + $PageFullUrl)

                    # Create a new object to store the page details
                    $SpacePage = New-Object -TypeName PSObject
                    $SpacePage | Add-Member -MemberType NoteProperty -Name SiteCollectionName -Value $SPWeb.Title
                    $SpacePage | Add-Member -MemberType NoteProperty -Name SiteCollectionUrl -Value $SPWeb.Url 
                    $SpacePage | Add-Member -MemberType NoteProperty -Name SiteCollectionOwners -Value $AllSiteOwners  
                    $SpacePage | Add-Member -MemberType NoteProperty -Name PageTitle -Value $PnPPage.PageTitle
                    $SpacePage | Add-Member -MemberType NoteProperty -Name PageID -Value $PnPPage.PageId
                    $SpacePage | Add-Member -MemberType NoteProperty -Name PageUrl -Value $PnPPage.Name
                    $SpacePage | Add-Member -MemberType NoteProperty -Name PageFullUrl -Value $PageFullUrl                         
                    $AllSpacePages += $SpacePage  
                     
                }
                $PageCount++  
            }
        }

    }
    $SiteCount++  
}

# Export the collected information to a CSV file and output the path
$ExportPath = ([Environment]::GetFolderPath('MyDocuments') + "\SPOSpacesPages-$Date.csv")    
$AllSpacePages | Export-Csv -Path $ExportPath -NoTypeInformation -Force
Write-Host "ExportPath: $ExportPath"  

