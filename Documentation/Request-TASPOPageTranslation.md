| Script                                                      | Author       | 
| ------------------------------------------------------------ | ------------ | 
| **[Request-TASPOPageTranslation.ps1](/Scripts/Request-TASPOPageTranslation.ps1)** | [Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/)
# Request-TASPOPageTranslation

## SYNOPSIS
This PowerShell script is designed to automate the translation of SharePoint Online pages using the DeepL API.  
For details and additional notes read my blog post at https://blog-en.topedia.com/?p=37491.

## DESCRIPTION
The script begins by checking if a connection to SharePoint Online has been established using the Connect-PnPOnline cmdlet. If not, it throws an error and exits.  
It then retrieves a secret from Azure Key Vault, which is used as the authorization key for the DeepL API.

The script identifies the SharePoint Online Site Pages library and retrieves the main language of the SharePoint site. It also constructs the URL of the page to be translated.
Depending on the edition of DeepL being used (Free or Pro), it sets the appropriate API URL.

The script then checks if the page is already in the target language. If it is, it skips the translation. If not, it creates a new page in the target language if one doesn't already exist.
The script then retrieves the source and target pages and constructs the request bodies for the DeepL API calls to translate the title, description, and content of the page.

The translated text is then used to update the target page. If the PublishPage variable is set to true, the script publishes the page.

Finally, the script outputs the URL of the translated page.   

## REQUIREMENTS
- [DeepL API Key](https://www.deepl.com/en/pro-api) (Free, Pro or Business)
- PowerShell 7.4 or later
- PowerShell modules 
  - [PnP.PowerShell](https://www.powershellgallery.com/packages/PnP.PowerShell) (at least version 2.4)
  - [Az.KeyVault](https://www.powershellgallery.com/packages/Az.KeyVault) (at least version 5.x)
  - [Az.Accounts](https://www.powershellgallery.com/packages/Az.Accounts) (at least version 2.13)
- Azure KeyVault configuration (optional), as described in this [YouTube Video](https://www.tekkigurus.com/stop-using-credentials-powershell-scripts-with-key-vault/) 


## SYNTAX

```powershell
Request-TASPOPageTranslation [-SiteUrl] [-PageID] [-TranslationLanguage] [-DeepLEdition] [-SkipTranslationNote] [-PublishPage] 
```

## COMPATIBILITY
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   Not compatible    |

## EXAMPLE
```powershell
Request-TASPOPageTranslation -PageID 3 -TranslationLanguage DE -SiteUrl <SharePointSiteUrl>
```  
Requests a translation for PageID 3 into German. Translation note is added to the translated page and page is not published.     
___

```powershell
Request-TASPOPageTranslation -PageID 3 -TranslationLanguage DE -SkipTranslationNote -SiteUrl <SharePointSiteUrl>
```  
Requests a translation for PageID 3 into German. Translation note is not added to the translated page and page is not published.   
___

```powershell
Request-TASPOPageTranslation -PageID 3 -TranslationLanguage DE -DeepLEdition "Pro" -SiteUrl <SharePointSiteUrl>
```  
Requests a translation for PageID 3 into German via the DeepL Pro API. Translation note is added to the translated page and page is not published.  

## PARAMETERS

### -SiteUrl
Represents the URL of the SharePoint Online site collection with the page that you want to translate.

```yaml
Type: System.Uri
Required: True
Position: Named
Default value: None
```
### -PageID
Represents the ID of the SharePoint Online page that you want to translate.

```yaml
Type: Int32
Required: True
Position: Named
Default value: None
```
### -TranslationLanguage
Represents the language to which you want to translate the page.   
The ValidateSet attribute restricts the possible values of this parameter to "DE", "EN", "FR", "IT", and "ES", which represent German, English, French, Italian, and Spanish, respectively. 

```yaml
Type: String
Required: True
Position: Named
Default value: None
```
### -DeepLEdition
Represents the edition of DeepL that you're using.    
The ValidateSet attribute restricts the possible values of this parameter to "Free" and "Pro", which represent the Free and Pro / Business editions of DeepL, respectively.

```yaml
Type: String
Required: False
Position: Named
Default value: Free
```
### -SkipTranslationNote
If this parameter is provided, the script will not add a translation note to the translated page.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: None
```
### -PublishPage
If this parameter is provided, the script will publish the translated page.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: None
```

## RELATED LINKS

[Translate SharePoint pages with DeepL API | Topedia Blog](https://blog-en.topedia.com/?p=37491)   
[Create multilingual SharePoint sites, pages, and news | Microsoft Support](https://support.microsoft.com/en-gb/office/create-multilingual-sharepoint-sites-pages-and-news-2bb7d610-5453-41c6-a0e8-6f40b3ed750c)