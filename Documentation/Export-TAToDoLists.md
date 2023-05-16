| Command                                                      | Author       | Module                                                |
| ------------------------------------------------------------ | ------------ | ----------------------------------------------------- |
| **[Export-TAToDoLists](/Commands/Export-TAToDoLists.ps1)** | [Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/) | Not ready |
# Export-TAToDoLists

## SYNOPSIS
The command creates a summary about Microsoft To-Do lists for all accounts in the tenant with a To-Do service plan.  
By default, the command evaluates for all user accounts with To-Do service plan whether they use shared lists and if they are the owners of the list. Alternatively, the evaluation of all lists is possible. The results will be exported to your local documents folder. 

## General information and limitations
- The command checks to which user accounts a Microsoft To-Do service plan is assigned and evaluates all shared lists per account. If an account has no shared lists it will be skipped.
- If an account has never opened/used Microsoft To-Do, Graph cannot query lists and returns an error. The account will be skipped.
- Compared to the old Outlook API, the Graph API for Microsoft To-Do is missing some information, e.g. for shared lists the share link and with whom the lists are shared. The old Outlook API is no longer supported. In my command I only use the Graph API.
- The Graph API for Microsoft To-Do is currently only designed for a list count around 100 (per account). For a test I created 130+ lists. Graph never returns all lists. An [issue](https://github.com/microsoftgraph/microsoft-graph-docs/issues/15112) is already open for a long time. There is no official information from Microsoft how many lists To-Do supports.

## What content is included?
- Username, the respective account has already used Microsoft To-Do and created affected lists.
- List name
- List type, in total there are three types.
  - **System lists**, lists predefined by Microsoft (e.g. Default lists and a list for marked e-mails).
  - **Personal lists**, manually created, not shared, the creator is the owner of the list. 
  - **Shared lists**, lists are distinguished between shared by oneself (the person is the owner of the list) or shared by someone else (the person is not the owner of the list). In the latter case, internal lists and lists shared via Microsoft personal accounts are included.
- Whether the account is the owner of the list. 
- Whether the list is shared. 
- Whether the account has created 100+ lists. In that case Graph could not return all the list, see the mentioned issue above.




## REQUIREMENTS
- The PowerShell module [Microsoft.Graph.Authentication](https://www.powershellgallery.com/packages/Microsoft.Graph.Authentication)   
- Azure App registration with the folloring permissions
  - Microsoft Graph > Application > User.Read.All (for querying all user accounts with To-Do service plan)
  - Microsoft Graph > Application > Tasks.Read.All (for the query of To-Do lists per account)

## SYNTAX

```powershell
Export-TAToDoLists [-IncludePersonalLists] [-IncludeSystemLists]  [-UPN <string>]  
```

## COMPATIBILITY
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   X    |

## EXAMPLES
```powershell
Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -ClientID <AzureAppID> -TenantId <TenandID> -CertificateThumbprint <CertificateThumbprint>  

Export-TAToDoLists -IncludeSystemLists -IncludePersonalLists
```  
Exports shared lists, system lists and personal lists for all accounts with a To-Do service plan.    
___

```powershell
Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -ClientID <AzureAppID> -TenantId <TenandID> -CertificateThumbprint <CertificateThumbprint> 

Export-TAToDoLists -IncludeSystemLists -UPN <UserPrincipalName>
```  
Exports shared lists and system lists for a specific account. Personal lists are excluded. 

## PARAMETERS

### -IncludeSystemLists
Include system lists like the default lists and list for marked emails.  

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: None
```
### -IncludePersonalLists
Include manually created lists, not shared, the creator is the owner of the list.  

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: None
```

### -UPN
A specific UserPrincipalName for the export. 

```yaml
Type: string
Required: False
Position: Named
Default value: None
```

## RELATED LINKS

[Microsoft To-Do Listen exportieren | TAM365 Blog](https://blog.topedia.com/?p=23758) 