
param ( 
    [Parameter(Mandatory=$true)][System.Uri]$SiteUrl,
    [Parameter(Mandatory=$true)][int32]$PageID,

    [ValidateSet("DE","EN","FR","IT","ES")]  
    [Parameter(Mandatory=$true)][string]$TranslationLanguage,

    [ValidateSet("Free","Pro")]  
    [string]$DeepLEdition = "Free",
    [switch]$PublishPage,
    [switch]$SkipTranslationNote

) 

<#
    This script is used to translate a SharePoint page using the DeepL API. 
    It first checks if the page is already available in the target language. If not, it creates a new translation of the page in the target language. 
    Then it sends translation requests for the title, description, and content of the page to the DeepL API. 
    After receiving the translated values, it updates the page with these values. 
    If specified, it also adds a translation note to the page and publishes the page.

    For details read my blog post at https://blog-en.topedia.com/?p=37491 and documentation at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Request-TASPOPageTranslation.md
#>   

function Get-TASPOPageLanguages {
    param ( [Parameter(Mandatory=$true)][int]$PageID ) 

    <#
        .SYNOPSIS
        This command retrieves all language versions of a specific SharePoint Online page.

        .DESCRIPTION
        The Get-TASPOPageLanguages command connects to a SharePoint Online site and retrieves all language versions of a specific page in the Site Pages library. The page is identified by its ID.
        For information read the blog post at https://blog.topedia.com/?p=36061.

        .PARAMETER PageID
        An integer that specifies the ID of the page to retrieve. This is a mandatory parameter.

        .EXAMPLE
        Get-TASPOPageLanguages -PageID 123

        This example retrieves all language versions of the page with ID 123.

        .NOTES
        Before running this command, you must connect to your SharePoint Online site using Connect-PnPOnline. If a connection has not been established, the command will return an error.
        The command returns an array of custom objects, each representing a language version of the page. Each object includes the following properties: ID, IsTranslation, Language, Title, and RelativeUrl.

        Author: Tobias Asböck - https://github.com/TobiasAT/PowerShell 
        Last updated: 31.03.2024

        .Link 
        https://topedia.net/wP40qr
        
    #>

    try { Get-PnPContext | Out-Null }
    catch {
        # If an error occurs (usually because Connect-PnPOnline has not been called), write an error message and return
        Write-Error "Connect-PnPOnline must be called first." ; return
    }        

    # Get the main language of the site    
    $WebMainLanguage = (Get-PnPWeb -Includes Language).Language

    # Get all list items from the Site Pages library
    $SitePageLibrary = Get-PnPList | ?{$_.EntityTypeName -eq "SitePages" }
    $AllListItems = Get-PnPListItem -List $SitePageLibrary -PageSize 1000 

    # Find the list item with the specified page ID
    $ListItem = ($AllListItems | ?{$_.FieldValues.ID -eq $PageID }).FieldValues    

    # If no list item with the specified ID is found, write an error message and return
    if($ListItem.Count -eq 0) { Write-Error "Page with ID $PageID not found." ; return }

    # Initialize an array to hold all pages and retrieve the source item and all translations if the list item has translations or is a translation itself
    $AllPages = @()
    if( $ListItem._SPTranslatedLanguages.Count -gt 0 -or $ListItem._SPIsTranslation -eq $true )
    { 
        # If the list item is not a translation, use its unique ID; otherwise, use the unique ID of the source item
        if( $ListItem._SPTranslationSourceItemId.Guid -eq $null )
        { $ListItemGuid = $ListItem.UniqueId.Guid } else
        {   $ListItem =  $AllListItems.FieldValues | ?{$_.UniqueId.Guid -eq $ListItem._SPTranslationSourceItemId.Guid } 
            $ListItemGuid = $ListItem.UniqueId.Guid         
        }

        $AllPages += $ListItem
        $AllPages += $AllListItems.FieldValues | ?{$_._SPTranslationSourceItemId.Guid -eq $ListItemGuid }   
    } else { 
        # If the list item has no translations and is not a translation, add it to the array
        $AllPages += $ListItem 
    }           

    # Initialize an array to hold the language pages and loop through all pages
    $LanguagePages = @()
    foreach ($Item in $AllPages)
    {   
        # Add a custom object representing the page to the array
        $LanguageItem = [PSCustomObject]@{
                'ID' = $Item.ID
                'IsTranslation' = $null
                'Language' = $null
                'LanguageID' = $null             
                'Title' = $Item.Title
                'RelativeUrl' = $Item.FileRef                     
            } 

        if( $Item._SPTranslationLanguage -ne $null)
        {   $LanguageItem.IsTranslation = $Item._SPIsTranslation
            $LanguageItem.Language = $Item._SPTranslationLanguage
            $LanguageItem.LanguageID = ([System.Globalization.CultureInfo]::GetCultureInfo($Item._SPTranslationLanguage)).LCID 
        } else { 
            
            [int]$LanguageID = $WebMainLanguage       
            $LanguageItem.LanguageID = $LanguageID      
            $LanguageItem.Language = ([System.Globalization.CultureInfo]::GetCultureInfo($LanguageID)).Name.ToLower()            

            if( $Item._SPIsTranslation -ne $null ) { 
                $LanguageItem.IsTranslation = $Item._SPIsTranslation } else 
                { $LanguageItem.IsTranslation = $false }
        }   

        $LanguagePages += $LanguageItem

    }

    return $LanguagePages  
    
}

function Build-TALanguageTable 
{
    <#
        .SYNOPSIS
        The Build-TALanguageTable command creates a table with language information.

        .DESCRIPTION
        This command builds a table that contains information about different languages. 
        Each entry in the table is a hashtable that includes the following properties:
        - Language: The two-letter language code.
        - Language_DisplayName: The full name of the language.
        - LanguageId_SP: The language ID used by SharePoint.
        - LanguageCode_SP: The language code used by SharePoint.
        - LanguageCode_DeepL_Source: The language code used by the DeepL API for source text.
        - LanguageCode_DeepL_Target: The language code used by the DeepL API for target text.

        .EXAMPLE
        Build-TALanguageTable        

        .NOTES
        The language codes and IDs are based on the following references:
        - SharePoint: https://pkbullock.com/resources/reference-sharepoint-online-languages-ids/
        - DeepL: https://developers.deepl.com/docs/resources/supported-languages
        
        Author: Tobias Asboeck - https://github.com/TobiasAT/PowerShell 
        Last updated: 31.03.2024 

        .LINK
        https://topedia.net/yqUqIh
    #>    

    $LanguageData = @(
        @{
            Language = 'EN' 
            Language_DisplayName = 'English' 
            LanguageId_SP = 1033 
            LanguageCode_SP = 'en-US'
            LanguageCode_DeepL_Source = 'EN'
            LanguageCode_DeepL_Target = 'EN-US'
        },
        @{
            Language = 'DE' 
            Language_DisplayName = 'German'
            LanguageId_SP = 1031 
            LanguageCode_SP = 'de-DE'
            LanguageCode_DeepL_Source = 'DE'
            LanguageCode_DeepL_Target = 'DE'
        },
        @{
            Language = 'FR' 
            Language_DisplayName = 'French'
            LanguageId_SP = 1036 
            LanguageCode_SP = 'fr-FR'
            LanguageCode_DeepL_Source = 'FR'
            LanguageCode_DeepL_Target = 'FR'
        },
        @{
            Language = 'IT' 
            Language_DisplayName = 'Italian'
            LanguageId_SP = 1040 
            LanguageCode_SP = 'it-IT'
            LanguageCode_DeepL_Source = 'IT'
            LanguageCode_DeepL_Target = 'IT'
        },
        @{
            Language = 'ES' 
            Language_DisplayName = 'Spanish'
            LanguageId_SP = 3082 
            LanguageCode_SP = 'es-ES'
            LanguageCode_DeepL_Source = 'ES'
            LanguageCode_DeepL_Target = 'ES'
        }
    )

    # Build the table
    $LanguageTable = $LanguageData | ForEach-Object { [PSCustomObject]$_ }
    $LanguageTable 
}

# Tested with these versions
#requires -Version 7.4
#requires -Modules @{ModuleName="PnP.PowerShell"; ModuleVersion="2.4.0"}, @{ModuleName="Az.KeyVault"; ModuleVersion="5.0.0"}, @{ModuleName="Az.Accounts"; ModuleVersion="2.13.0"}

Read-Host "Press Enter to proceed with authentication for $SiteUrl"
Connect-PnPOnline -Url $SiteUrl -Interactive

try { Get-PnPContext | Out-Null }
catch {
    # If an error occurs (usually because Connect-PnPOnline has not been called), write an error message and return
    Write-Error "PnP connection is missing." ; return
}    

# Reading a .env file and converting the contents into a hashtable. The .env file contains key-value pairs of environment variables.
try { $EnvVar = Get-Content ".\Env\SPOPageTranslation.env" -ErrorAction Stop | ConvertFrom-StringData }
catch { Write-Error "Environment file not found." ; return  }

Connect-AzAccount -ServicePrincipal  -ApplicationId $EnvVar.AZ_ApplicationID  -CertificateThumbprint $EnvVar.AZ_CertThumbprint  -Tenant $EnvVar.AZ_TenantID  -Subscription $EnvVar.AZ_SubscriptionID  | Out-Null

try { $KeyVaultItem = Get-AzKeyVaultSecret -VaultName $EnvVar.AZ_KeyVault  -Name $EnvVar.AZ_KeyFaultItemName -AsPlainText -ErrorAction Stop }
catch { Write-Error "Key Vault not found." ; return  }

# Check if KeyVaultItem is empty, if so, write an error and return
if( $KeyVaultItem.Count -eq 0 ) { Write-Error "Key Vault item not found." ; return }

# Create an authorization header for DeepL API
$DeeplAuthHeader = @{"Authorization" = "DeepL-Auth-Key $KeyVaultItem"}

# Get the SharePoint list named "SitePages" and check if SitePages library is found, if not, write an error and return
$SitePageLibrary = Get-PnPList | ?{$_.EntityTypeName -eq "SitePages" }
if( $SitePageLibrary.Count -ne 1 ) { Write-Error "Site Pages library not found." ; return }

# Get the URL of the SharePoint web
$RootUri = New-Object System.Uri((Get-PnPWeb).Url)

# Get the SharePoint list item with the specified ID from the SitePages library
$Page = Get-PnPListItem -List $SitePageLibrary -Id $PageID
$PageUrl_Source = $RootUri.Scheme + "://" + $RootUri.Host + $Page.FieldValues.FileRef

Write-Host "Page Title: $($Page.FieldValues.Title)"
Write-Host "Page URL: $PageUrl_Source"

# Set the DeepL API URL based on the edition
if( $DeepLEdition -eq "Free" )
{   $DeepLAPIUrl = "https://api-free.deepl.com/v2/translate" } else
{   $DeepLAPIUrl = "https://api.deepl.com/v2/translate" }

# Build the language table
$LanguageTable = Build-TALanguageTable

# Get all languages of the page
$AllPageLanguages = Get-TASPOPageLanguages -PageId $PageID

# Get the source language of the page
$SourcePageInfo = $AllPageLanguages | ?{$_.IsTranslation -eq $false }

# Get the source and target language info from the language table
$LanguageTableInfo_Source = $LanguageTable | ?{$_.LanguageCode_SP -eq $SourcePageInfo.Language }
$LanguageTableInfo_Target = $LanguageTable | ?{$_.Language -eq $TranslationLanguage }

# Check if the source language is the same as the target language
if( $LanguageTableInfo_Source.Language -eq $TranslationLanguage)
{   
    # If so, skip the translation
    Write-Host ("Source language of PageID $PageID is already " + $LanguageTableInfo_Source.Language_DisplayName + ". Translation skipped.") -f Yellow 
} else 
{
    # If not, start the translation process
    # Get the language ID of the target language from the language table
    $LanguageID = ($LanguageTable | ?{ $_.Language -eq $TranslationLanguage }).LanguageID_SP

    # Check if the page is already available in the target language
    if( ($AllPageLanguages | ?{$_.LanguageID -eq $LanguageID  }).Count -eq 0 )
    {   
        # If not, create a new translation of the page in the target language
        Write-Host "Page is not yet available in $($LanguageTableInfo_Target.Language_DisplayName). Creating..."         
        Set-PnPPage -Identity $Page.FieldValues.FileLeafRef -Translate -TranslationLanguageCodes $LanguageID | out-null
        Start-Sleep -Seconds 3
        $AllPageLanguages = Get-TASPOPageLanguages -PageId $PageID
    }

    # Get the language info of the target language from the language table
    $LanguageInfo = $LanguageTable | ?{ $_.Language -eq $TranslationLanguage }

    Write-Host "Translating page to $($LanguageTableInfo_Target.Language_DisplayName)..."    

    # Get the source and target page
    $SourcePage = Get-PnPListItem -List $SitePageLibrary -Id $SourcePageInfo.ID 
    $DeepL_SourceLang = ($LanguageTable | ?{ $_.LanguageId_SP -eq $SourcePageInfo.LanguageID }).LanguageCode_DeepL_Source

    $TargetPageInfo = $AllPageLanguages | ?{$_.LanguageID -eq $LanguageInfo.LanguageId_SP }
    $TargetPage = Get-PnPListItem -List $SitePageLibrary -Id $TargetPageInfo.ID  
    $DeepL_TargetLang = ($LanguageTable | ?{ $_.LanguageId_SP -eq $TargetPageInfo.LanguageID }).LanguageCode_DeepL_Source

    # Create the translation request for the title, description, and content of the page
    $Page_Title = @{
        text =  @($SourcePage.FieldValues.Title)
        source_lang = "$DeepL_SourceLang"
        target_lang = "$DeepL_TargetLang"        
    }

    $Page_Description = @{
        text =  @($SourcePage.FieldValues.Description)
        source_lang = "$DeepL_SourceLang"
        target_lang = "$DeepL_TargetLang"        
    }

    $Page_Content = @{
        text =  @($SourcePage.FieldValues.CanvasContent1)
        source_lang = "$DeepL_SourceLang"
        target_lang = "$DeepL_TargetLang"
        tag_handling = "html"
    }

    # Send the translation requests to the DeepL API
    $Translation_Title = Invoke-RestMethod -Method Post -Uri $DeepLAPIUrl -Body ($Page_Title | ConvertTo-Json) -Headers $DeeplAuthHeader -ContentType "application/json;charset=utf-8"
    $Translation_Description = Invoke-RestMethod -Method Post -Uri $DeepLAPIUrl -Body ($Page_Description | ConvertTo-Json) -Headers $DeeplAuthHeader -ContentType "application/json;charset=utf-8"
    $Translation_Content = Invoke-RestMethod -Method Post -Uri $DeepLAPIUrl -Body ($Page_Content | ConvertTo-Json -Depth 10) -Headers $DeeplAuthHeader -ContentType "application/json;charset=utf-8"

    # Get the translated content
    $PageContent_Translated = $Translation_Content.translations.text

    # Check if a translation note should be added
    if( $SkipTranslationNote -eq $false )
    {
        # If so, create and send the translation request for the translation note
        if( $PageContent_Translated.contains('<div data-sp-rte="">') )
        {    
            Write-Host "Adding DeepL translation note..." 
            $DeepL_TranslationNote = @{
                text =  @("<p style='text-align&#58;center;'><span class='fontSizeMedium'><i>Page was automatically translated by DeepL API</i></span><br></p>")
                source_lang = "EN"
                target_lang = "$DeepL_TargetLang"
                tag_handling = "html"
            }      
            
            $Translation_DeepLNote = Invoke-RestMethod -Method Post -Uri $DeepLAPIUrl -Body ($DeepL_TranslationNote | ConvertTo-Json -Depth 2) -Headers $DeeplAuthHeader -ContentType "application/json;charset=utf-8"

            # Add the translation note to the translated content
            $CanvasContent_Div = $PageContent_Translated.Substring(0, $PageContent_Translated.IndexOf('<div data-sp-rte="">')) 
            $CanvasContent_New = $CanvasContent_Div + $Translation_DeepLNote.translations.text
            $PageContent_Translated = $PageContent_Translated.Replace($CanvasContent_Div, $CanvasContent_New)

        } else {
           Write-Host "No translation note added. Page content does not contain the requirement element." -f red }

    } 

    # Create the updated values for the page
    $PageValue = @{
        'Title' = $Translation_Title.translations.text
        'Description' = $Translation_Description.translations.text
        'CanvasContent1' = $PageContent_Translated
    }

    # Update the page with the translated values
    Write-Host "Updating page with translation..."
    Set-PnPListItem -List $SitePageLibrary -Identity $TargetPage.id -Values $PageValue | Out-Null

    # Check if the page should be published
    if( $PublishPage ) { 
        # If so, publish the page
        Write-Host "Publishing the page..."
        $PnPContext = Get-PnPContext        
        $TargetPage.File.Publish("Published")
        $PnPContext.ExecuteQuery()        
    }

    # Construct the URL of the translated page
    $PageUrl_Target = $RootUri.Scheme + "://" + $RootUri.Host + $TargetPage.FieldValues.FileRef
    Write-Host "Page has been translated to $($LanguageTableInfo_Target.Language_DisplayName) and can be viewed at $PageUrl_Target"  
}

Disconnect-PnPOnline
Disconnect-AzAccount

