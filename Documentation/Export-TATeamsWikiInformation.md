| Command                                                      | Author       | Module                                                |
| ------------------------------------------------------------ | ------------ | ----------------------------------------------------- |
| **[Export-TATeamsWikiInformation](/Commands/Export-TATeamsWikiInformation.ps1)** | [Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/) | Not ready |
# Export-TATeamsWikiInformation

## SYNOPSIS
The command evaluates all wikis in Teams via Microsoft Graph and summarizes it in a CSV file. You can prepare the file and send it to the owners of the teams.   
For details read https://support.microsoft.com/en-us/office/export-a-wiki-to-a-onenote-notebook-8cd8ab0c-2314-42b0-a1d0-5c6c4c5e1547.   

The following information are included in the report.   

- All Teams channels with at least one wiki tab. There can be multiple wikis in a channel. The summary includes all wikis in the channel.
- Channel name in which the wiki is located
- Which team 
- The owners of the team
- Channel type (Standard or Private Channel).   
Theoretically, shared channels are also included, but shared channels do not support wikis at the moment.
- Name of the wiki tab
- Creation date of the wiki, only for recently created wikis. Teams did not record the creation date of a wiki in the past.
- Whether the wiki is populated with content. In the past, Teams inserted a wiki by default for every new channel. If the wiki has never been edited, it is empty. Teams does not show any option for migration for such wikis. 
- Whether the wiki has already been migrated. If a migration took place, Teams will put the wiki in a read-only mode. An owner could delete the wiki tab.  

## REQUIREMENTS
- An account with Global Admin role 
- PowerShell module [Microsoft.Graph.Authentication](https://www.powershellgallery.com/packages/Microsoft.Graph.Authentication) 
- The command [Export-TATeamsWikiInformation](/Commands/Export-TATeamsWikiInformation.ps1) requests the following Graph permissions....  
  - Team.ReadBasic.All > for the evaluation of all teams
  - Channel.ReadBasic.All > for the evaluation of all channels per team
  - TeamsTab.Read.All > for the evaluation of all tabs per channel
  - TeamMember.Read.All > for evaluation of owners per team


## SYNTAX

```powershell
Export-TATeamsWikiInformation [-ExcludeMigratedWikis] [-ExcludeWikisWithNoContent]  
```

## COMPATIBILITY
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   X    |

## EXAMPLE
```powershell
Export-TATeamsWikiInformation
```  
Exports all Teams channels with at least one wiki tab.   
___

```powershell
Export-TATeamsWikiInformation -ExcludeMigratedWikis -ExcludeWikisWithNoContent
```  
Exports all Teams channels with at least one wiki tab, with pre-filtering for Wikis with no content or already migrated Wikis.

## PARAMETERS

### -ExcludeMigratedWikis
Exclude already migrated Wikis in the export (pre-filtering).

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: None
```
### -ExcludeWikisWithNoContent
Exclude Wikis with no content (pre-filtering).

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: None
```

## RELATED LINKS

[Informationen über Teams Wikis exportieren | TAM365 Blog](https://blog.topedia.com/?p=23159)   
[Export a wiki to a OneNote notebook | Microsoft Support](https://support.microsoft.com/en-us/office/export-a-wiki-to-a-onenote-notebook-8cd8ab0c-2314-42b0-a1d0-5c6c4c5e1547)