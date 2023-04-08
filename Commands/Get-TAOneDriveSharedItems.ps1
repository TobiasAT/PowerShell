
<#  
    .SYNOPSIS  
    Get an overview of all shared files and folders for an OneDrive for Business account. The following information are included in the report.

    .DESCRIPTION
    Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Get-TAOneDriveSharedItems.md.

#> 

function Get-TAOneDriveSharedItems
{  param( 
        [Parameter(Mandatory=$true)]$UPN,
        [switch]$Export,
        [switch]$ShowExternalEmail   
    ) 

    if( (Get-MgContext).ClientId -eq $null )
    { Write-Host "Please connect to Microsoft Graph: Connect-MgGraph" -f Red; break }

    if((Get-Module PnP.PowerShell -ListAvailable).Count -eq 0)
    { Write-Host "Please install the PnP.PowerShell module." -f Red; break }

    # Due to a recent bug of PnP.PowerShell and PowerShell 5, read https://learn.microsoft.com/en-us/answers/questions/1196279/import-module-could-not-load-file-or-assembly-syst
    if(($host).Version.Major -eq 5)
    {  if( (Get-Module PnP.PowerShell -ListAvailable | ?{$_.Version.Major -eq 1 -and $_.Version.Minor -ge 12} ).Count -eq 0)
       { Write-Host "With PowerShell 5 PnP.PowerShell version 1.12.0 is required." -f Red; break }
    }

    $MSGraphUrl = "https://graph.microsoft.com/v1.0"
    $RestUrl = "$MSGraphUrl/domains"
    $CompanyDomains = Invoke-MgGraphRequest -Uri $RestUrl -Method get
    $CompanyDomains = ($CompanyDomains.value | ?{$_.AuthenticationType -eq "Managed" }).id

    $RestUrl = "$MSGraphUrl/users/$UPN/drive"
    $OneDriveResult = Invoke-MgGraphRequest -Uri $RestUrl -Method get

    $Hostname =  $OneDriveResult.webUrl.Replace("https://","")
    $TenantUrl = ("https://" + $Hostname.Substring(0,$Hostname.IndexOf("/"))) 

    $OneDriveUrl = $OneDriveResult.webUrl.Substring(0,$OneDriveResult.webUrl.LastIndexOf("/"))
    $OneDriveSitePath = $OneDriveResult.webUrl.Replace($TenantUrl,"") + "/"

    Write-Host "OneDriveURL: $OneDriveUrl" -f Yellow

     # Due to a recent bug of PnP.PowerShell and PowerShell 5, read https://learn.microsoft.com/en-us/answers/questions/1196279/import-module-could-not-load-file-or-assembly-syst
    if(($host).Version.Major -ge 7 )
    { Import-Module PnP.PowerShell }
    else 
    { Import-Module PnP.PowerShell -RequiredVersion "1.12.0" }

    Connect-PnPOnline -Url $OneDriveUrl -ClientId (Get-MgContext).ClientId -Thumbprint (Get-MgContext).CertificateThumbprint -Tenant (Get-MgContext).TenantId
    $APIUrl = "$OneDriveUrl/_api/web/OneDriveSharedItems" 
    $AllSharedItems = Invoke-PnPSPRestMethod -Method Get -Url $APIUrl -ContentType "application/json;charset=utf-8"
    Disconnect-PnPOnline

    $SpecialCharacters = '[#]'	
    $SPOSharingData = @()
    $SharedItemCount = 1
    foreach( $Item in $AllSharedItems.value  )
    {  Write-Host ("SharedItem $SharedItemCount of " + $AllSharedItems.value.count )

        $FullFilePath = $TenantUrl + $Item.UrlPath
        $FilePath = $Item.UrlPath.Replace($OneDriveSitePath,"")        
                                    
        if( $FilePath -match $SpecialCharacters )
        { $FilePath = [System.Web.HTTPUtility]::UrlEncode($FilePath) } # Encoding for file/folder names with defined special characters
                
        $RestUrl = "$MSGraphUrl/users/$UPN/drive/root:/$FilePath"
        $DriveItemResult = Invoke-MgGraphRequest -Uri $RestUrl -Method get  -ContentType "application/json;charset=utf-8"  

        $OneDriveItemID = $DriveItemResult.id

        $RestUrl = "$MSGraphUrl/users/$UPN/drive/items/$OneDriveItemID/permissions"        
        $SPOItemPermissions = Invoke-MgGraphRequest -Uri $RestUrl -Method get  -ContentType "application/json;charset=utf-8"
        $AllSharingLinks = @($SPOItemPermissions.value | ?{$_.Roles -ne "Owner" }) 

        foreach( $SharingItem in $AllSharingLinks )
        {

            if( $SharingItem.link.webUrl -ne $null )
            {  $SharingItem_SharingLink = $SharingItem.link.webUrl  } else 
            {   $SharingItem_SharingLink = "Not registered (legacy sharing mode)"  } 
                                
            $SPOSharingInformation = @{}
            $SPOSharingInformation.Add("OneDriveUrl",$OneDriveUrl)
            $SPOSharingInformation.Add("FilePath",$FullFilePath)
            $SPOSharingInformation.Add("FileID",$OneDriveItemID)
            $SPOSharingInformation.Add("SharingPermission",$SharingItem.roles[0])
            $SPOSharingInformation.Add("SharingID",$SharingItem.shareId )
            $SPOSharingInformation.Add("SharingLink",$SharingItem_SharingLink )        

            if( $SharingItem.link.scope -eq "anonymous" )
            {
                
                if( $SharingItem.expirationDateTime -ne $null )
                { $SharingExpirationDate = Get-date $SharingItem.expirationDateTime -Format g  } 
                else 
                { $SharingExpirationDate = "N/A" }   
        
                if( $SharingItem.grantedToIdentitiesV2.user.Count -gt 0 )
                {   $SharingItem_SharedWith = @()     

                    foreach( $User in $SharingItem.grantedToIdentitiesV2.user )
                    {    $UserMailDomain = $User.email.substring($User.email.lastindexof("@") + 1)
                        
                        if( $CompanyDomains -contains $UserMailDomain )
                        { $SharingItem_UserScope = "Internal" } else 
                        { $SharingItem_UserScope = "External" }  
                        
                    
                        
                        if($SharingItem_UserScope -eq "External" -and $ShowExternalEmail -eq $false )
                        {   $UserMailAlias = $User.email.substring(0,$User.email.indexof("@") + 1)
                        
                            $UserMailAddress = $User.email.replace($UserMailAlias,"[HiddenforPrivacy]@")										 
                        } else 
                        { $UserMailAddress = $User.email  }              
                        

                        $SharingItem_SharedWith += $UserMailAddress.ToLower()  

                    }

                    $SharingItem_SharedWith = $SharingItem_SharedWith -join ","
                    
                } else 
                { $SharingItem_SharedWith = "No users"  }

                $SPOSharingInformationExt = @{}
                $SPOSharingInformationExt.Add("SharingScope", "Anonymous" ) 
                $SPOSharingInformationExt.Add("ExpirationDate", $SharingExpirationDate ) 
                $SPOSharingInformationExt.Add("PasswordProtected", $SharingItem.hasPassword )         
                $SPOSharingInformationExt.Add("SharedTo", "Anyone with the link"  )        
                $SPOSharingInformationExt.Add("UserScope", "Internal & External" ) 
                $SPOSharingInformationExt.Add("PreventDownload", $SharingItem.link.preventsDownload )
                $SPOSharingInformationExt.Add("LinkTyp",$SharingItem.link.type) 
                $SPOSharingInformationExt.Add("SharedWith", $SharingItem_SharedWith ) 
                $SPOSharingData +=  $SPOSharingInformation + $SPOSharingInformationExt
            }

            if( $SharingItem.link.scope -eq "organization" )
            {
                
                if( $SharingItem.grantedToIdentitiesV2.user.Count -gt 0 )
                {   $SharingItem_SharedWith = @() 

                    foreach( $User in $SharingItem.grantedToIdentitiesV2.user )
                    { $SharingItem_SharedWith += $User.email.ToLower() }

                    $SharingItem_SharedWith = $SharingItem_SharedWith -join "," 
                
                } else 
                { $SharingItem_SharedWith =  "No users" }

                $SPOSharingInformationExt = @{}
                $SPOSharingInformationExt.Add("SharingScope", "Organization" ) 
                $SPOSharingInformationExt.Add("ExpirationDate", "N/A" ) 
                $SPOSharingInformationExt.Add("PasswordProtected", $SharingItem.hasPassword )         
                $SPOSharingInformationExt.Add("SharedTo", "People in Organization with the link"  )        
                $SPOSharingInformationExt.Add("UserScope", "Internal" ) 
                $SPOSharingInformationExt.Add("PreventDownload", $SharingItem.link.preventsDownload )
                $SPOSharingInformationExt.Add("LinkTyp",$SharingItem.link.type) 
                $SPOSharingInformationExt.Add("SharedWith", $SharingItem_SharedWith ) 
                $SPOSharingData += $SPOSharingInformation + $SPOSharingInformationExt                 

            }


            if( $SharingItem.link.scope -ne "anonymous" -and $SharingItem.link.scope -ne "organization" )
            { 
                foreach( $User in $SharingItem.grantedToIdentitiesV2.user )
                {    $UserMailDomain = $User.email.substring($User.email.lastindexof("@") + 1)
                    
                    if( $CompanyDomains -contains $UserMailDomain )
                    { $SharingItem_UserScope = "Internal" } else 
                    { $SharingItem_UserScope = "External" }                 
                
                    if($SharingItem_UserScope -eq "External" -and $ShowExternalEmail -eq $false )
                    {   $UserMailAlias = $User.email.substring(0,$User.email.indexof("@") + 1)                    
                        $UserMailAddress = $User.email.replace($UserMailAlias,"[HiddenforPrivacy]@")									 
                    } else 
                    { $UserMailAddress = $User.email.ToLower()  }          

                    $SPOSharingInformationExt = @{}
                    $SPOSharingInformationExt.Add("SharingScope", "Users" ) 
                    $SPOSharingInformationExt.Add("ExpirationDate", "N/A" ) 
                    $SPOSharingInformationExt.Add("PasswordProtected", $SharingItem.hasPassword )       
                    $SPOSharingInformationExt.Add("SharedTo", "Specific people"  )    
                    $SPOSharingInformationExt.Add("UserScope", $SharingItem_UserScope )
                    $SPOSharingInformationExt.Add("PreventDownload", $SharingItem.link.preventsDownload ) 
                    $SPOSharingInformationExt.Add("LinkTyp",$SharingItem.link.type) 
                    $SPOSharingInformationExt.Add("SharedWith", $UserMailAddress)                     
                    $SPOSharingData +=  $SPOSharingInformation + $SPOSharingInformationExt         
               
                }
            } 
            
        }
        $SharedItemCount++
    }

    if($Export -eq $false )
    { $SPOSharingData }
    else 
    {
        $Date = get-date -format "dd-MM-yyyy"
        $ExportPath = ([Environment]::GetFolderPath("MyDocuments") +  "\OneDriveSharingReport-$UPN-$Date.csv")
        $SPOSharingData | select OneDriveUrl,FilePath,SharingLink,SharedTo,SharingScope,UserScope,SharedWith,LinkTyp,SharingPermission,PasswordProtected,PreventDownload,ExpirationDate,FileID,SharingID | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding unicode -Force
        $ExportPath
    }   

}


