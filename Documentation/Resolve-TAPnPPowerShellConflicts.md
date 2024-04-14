| Script                                                      | Author       | 
| ------------------------------------------------------------ | ------------ | 
| **[Resolve-TAPnPPowerShellConflicts.ps1](/Scripts/Resolve-TAPnPPowerShellConflicts.ps1)** | [Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/)
# Resolve-TAPnPPowerShellConflicts

## SYNOPSIS
This script resolves known conflicts between the PnP.PowerShell and Microsoft.Graph.Authentication PowerShell modules.   
More details in my blog post at https://blog-en.topedia.com/?p=37829. 

## DESCRIPTION
The Resolve-TAPnPPowerShellConflicts script checks the installed versions of the PnP.PowerShell and Microsoft.Graph.Authentication modules. 
If the modules are installed and their versions are 2.* or higher, the script proceeds to check the versions of Microsoft.Graph.Core.dll and Microsoft.Identity.Client.dll in the PnP.PowerShell module directory.
  - If Microsoft.Graph.Core.dll exists in the PnP.PowerShell module directory, the file is deleted to avoid conflicts > [GitHub Issue 2285](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/2285). 
  - If the version of Microsoft.Identity.Client.dll in the PnP.PowerShell module directory is 4.50.*, the script attempts to copy it from the Microsoft.Graph.Authentication directory > [GitHub Issue 3637](https://github.com/pnp/powershell/issues/3637). 

## SYNTAX

```powershell
Resolve-TAPnPPowerShellConflicts
```

## COMPATIBILITY
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |        |

## EXAMPLE
```powershell
Resolve-TAPnPPowerShellConflicts
```  

## RELATED LINKS

[Resolve conflicts between PnP.PowerShell and Microsoft.Graph.Authentication module | Topedia Blog](https://blog-en.topedia.com/?p=37829)   
[Invoke-MgGraphRequest with error “Microsoft.Graph.Core, Version=1.25.1.0 | Topedia Blog](https://blog-en.topedia.com/2024/02/invoke-mggraphrequest-with-error-microsoft-graph-core-version-12510/)   
[Microsoft.Graph and PnP.PowerShell conflict | GitHub](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/2285)    
[BUG - Assembly Conflicts with Microsoft.Graph Module | GitHub](https://github.com/pnp/powershell/issues/3637)  