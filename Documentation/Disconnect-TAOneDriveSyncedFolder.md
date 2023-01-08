| Command                                                      | Author       | Module                                                |
| ------------------------------------------------------------ | ------------ | ----------------------------------------------------- |
| **[Disconnect-TAOneDriveSyncedFolder](/Commands/Disconnect-TAOneDriveSyncedFolder.ps1)** | [Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/) |  |
# Disconnect-TAOneDriveSyncedFolder

## SYNOPSIS
Instead to force a OneDrive Sync reset [Disconnect-TAOneDriveSyncedFolder](/Commands/Disconnect-TAOneDriveSyncedFolder.ps1) disconnects a single folder from your OneDrive Sync Client, or removes orphaned configurations to reconnect the synchronized folder again. 

## SYNTAX

```powershell
Disconnect-TAOneDriveSyncedFolder [-Foldername <string>]   
```

## COMPATIBILITY
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   X    |

## EXAMPLE
```powershell
Disconnect-TAOneDriveSyncedFolder -Foldername "TAM365 Demo - AlexW Private Channel - AlexW Private Channel" 
```
## PARAMETERS

### -Foldername
The synchronized folder name, based on the folder list in your Windows Explorer.

```yaml
Type: string
Required: True
Position: Named
Default value: None
```
## RELATED LINKS

[Synchronisierten SharePoint Ordner über PowerShell trennen (in German) | TAM365 Blog](https://blog.topedia.com/?p=20750) 
