| Command                                                      | Author       | Module                                                |
| ------------------------------------------------------------ | ------------ | ----------------------------------------------------- |
| **[Get-TAOneDriveSharedItems](/Commands/Get-TAOneDriveSharedItems.ps1)** | [Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/) | Not ready |
# Get-TAOneDriveSharedItems

## SYNOPSIS
Get an overview of all shared files and folders for an OneDrive for Business account.  
The following information are included in the report.  

- OneDrive path to the shared file.
- Shared link to the file (a recipient can access the shared file via this link).
- Sharing scope of the shared file. There are three possible scopes:
  - Anyone
  - People in Organization with the link
  - Specific people
- File is shared to internal, external, or internal and external.
- With whom the file is or was shared.
  - Is shared means someone has shared a file with "People in Organization with the link" and a person in the organization has opened the link/file. 
  - Was shared is for "Specific people". The file was shared with internal or external people (the mail address).
- If available, to which mail address the file was shared. For external people, the summary anonymizes the mail address.
- With what permissions a file is shared (read or write permissions).
- Whether the download was blocked.
- Whether a password was set (only for Sharing Scope Anyone).
- Whether the shared file has an expiration date and which one (only for Sharing Scope Anyone).
- FileID, for further queries via Microsoft Graph.
- SharingID, for further queries via Microsoft Graph.

## REQUIREMENTS
- The following PowerShell modules
  - [Microsoft.Graph.Authentication](https://www.powershellgallery.com/packages/Microsoft.Graph.Authentication) 
  - [PnP.PowerShell](https://www.powershellgallery.com/packages/PnP.PowerShell)    
- *Temporarily PowerShell 7, or PnP.PowerShell version 1.12.0 (due to a [recent bug](https://learn.microsoft.com/en-us/answers/questions/1196279/import-module-could-not-load-file-or-assembly-syst) with PnP.PowerShell and PowerShell 5)*
- Azure App registration with the folloring permissions
  - Microsoft Graph > Delegated > User.Read
  - Microsoft Graph > Application > Sites.Read.All (for information about files and folders)
  - Microsoft Graph > Application > Domain.Read.All (for the evaluation internal or external person)
  - SharePoint > Application > Sites.FullControl.All (to get results from OneDrive via the REST API OneDriveSharedItems)

## SYNTAX

```powershell
Get-TAOneDriveSharedItems [-UPN <string>] [-Export] [-ShowExternalEmail]  
```

## COMPATIBILITY
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   X    |

## EXAMPLE
```powershell
Get-TAOneDriveSharedItems -UPN "max@example.com" -Export 
```
## PARAMETERS

### -UPN
The UserPrincipalName of the OneDrive for Business account. 

```yaml
Type: string
Required: True
Position: Named
Default value: None
```
### -Export
Export the result into your local documents folder.  

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: None
```
### -ShowExternalEmail
By default an external mail address is anonymized. With this parameter the report includes the full mail address. 

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: None
```

## RELATED LINKS

[Informationen über geteilte OneDrive Dateien exportieren | TAM365 Blog](https://blog.topedia.com/?p=22798) 