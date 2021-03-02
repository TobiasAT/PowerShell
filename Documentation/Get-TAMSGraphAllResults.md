| Command                                                      | Author                                                      | Module                                                |
| ------------------------------------------------------------ | ------------------------ | ------------------------ |
|**[Get-TAMSGraphAllResults](/Commands/Get-TAMSGraphAllResults.ps1)**  |[Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/) |[TAMPowerShell](/Documentation/Module/TAMPowerShell.md) |

# Get-TAMSGraphAllResults

## SYNOPSIS
Receives all results from a Microsoft Graph REST request (paging). 

## SYNTAX

```powershell
Get-TAMSGraphAllResults [-Results] [-AuthHeader] 
```

## COMPATIBILITY
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   X    |

## EXAMPLE

```powershell
Get-TAMSGraphAllResults -Results $Results -AuthHeader $AuthHeader
```
## PARAMETERS

### -Results
The first result block from a REST request. 

```yaml
Type: Undefined
Required: True
Position: Named
Default value: None
```

### -AuthHeader
A current access token from the REST request.

```yaml
Type: Undefined
Required: True
Position: Named
Default value: None
```


## RELATED LINKS

[Paging Microsoft Graph data in your app | Microsoft](https://docs.microsoft.com/en-us/graph/paging) 