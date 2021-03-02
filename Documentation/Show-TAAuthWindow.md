| Command                                                      | Author       | Module                                                |
| ------------------------------------------------------------ | ------------ | ----------------------------------------------------- |
| **[Show-TAAuthWindow](/Commands/Authentication/Show-TAAuthWindow.ps1)** | Co-authoring | [TAMPowerShell](/Documentation/Module/TAMPowerShell.md) |
# Show-TAAuthWindow

## SYNOPSIS
Build and show an (oauth) authentication window (e.g. for an API authentication with Delegated permissions).

## SYNTAX

```powershell
Show-TAAuthWindow [-Url <Uri>]  
```

## COMPATIBILITY
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   X    |

## EXAMPLE
```powershell
Show-TAAuthWindow -Url "https://login.microsoftonline.com/contoso.onmicrosoft.com/oauth2/authorize..." 
```
## PARAMETERS

### -Url
The url for the (oauth) authentication request.

```yaml
Type: Uri
Required: True
Position: Named
Default value: None
```
## RELATED LINKS

[Authentication and authorization basics for Microsoft Graph | Microsoft](https://docs.microsoft.com/en-us/graph/auth/auth-concepts) 