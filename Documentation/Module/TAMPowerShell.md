| Module                                             | Author                                                      | Blog                     |
| ------------------------------------------------------------ | ----------------------------------------------------------- | ------------------------ |
|**[TAMPowerShell](/Modules/TAMPowerShell)**  |[Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/) |https://blog.topedia.com |

# TAMPowerShell Module

## SYNOPSIS

PowerShell Module for some of my commands. 



## SYNTAX

```powershell
Import-Module TAMPowerShell
```

## DESCRIPTION
The following commands are included in the module: 

- [Get-TAMSAuthToken](/Documentation/Get-TAMSAuthToken.md)  
- [Get-TAMSGraphAllResults](/Documentation/Get-TAMSGraphAllResults.md)
- [New-TAMSAuthJWT](/Documentation/New-TAMSAuthJWT.md)  
- [Show-TAAuthWindow](/Documentation/Show-TAAuthWindow.md)  
- [Write-TAPSLog](/Documentation/Write-TAPSLog.md)


## Installation
Currently the module is not available in the public PowerShell Gallary.   
Download the **TAMPowerShell** module in the [releases](https://github.com/TobiasAT/PowerShell/releases) of this repository and unzip the file into your local PowerShell module directory. Alternatively check the [module directory](/Modules/TAMPowerShell).  

**Current user only:** 

```
PowerShell 7: C:\Users\[Username]\Documents\PowerShell\Modules
PowerShell 5: C:\Users\[Username]\Documents\WindowsPowerShell\Modules
```

**All users:**
```
PowerShell 7: C:\Program Files\PowerShell\7\Modules
PowerShell 5: C:\Program Files\WindowsPowerShell\Modules
```


**OR** you can add an environment variable to your directory of choice.



## Compatibility
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   X    |




## RELATED LINKS

[How to Write a PowerShell Script Module | Microsoft](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-script-module)  
[About Modules | Microsoft](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_modules)  
[Understanding and Building PowerShell Modules | Adam the Automator](https://adamtheautomator.com/powershell-modules)    