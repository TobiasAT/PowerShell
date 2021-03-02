| Command                                                      | Author                                                      | Module                                                |
| ------------------------------------------------------------ | ------------------------ | ------------------------ |
|**[Write-TAPSLog](/Commands/Write-TAPSLog.ps1)**  |[Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/) |[TAMPowerShell](/Documentation/Module/TAMPowerShell.md) |

# Write-TAPSLog

## SYNOPSIS
Adds or appends a new line  to a log file.

## SYNTAX

```powershell
Write-TAPSLog [-Type <String>] [-Message <String>] [-Scriptname <String>] [-Exception] 
```
## DESCRIPTION
Can be used in scripts for logging purposes. Adds or appends a new line to a log file. 
- By default the log file is created at C:\ScriptLog. 
- The title of the log file is either the parameter Scriptname, or if not defined TAPSLog-[CurrentDate].log. 
- If the file already exists a new line will be added. 

## COMPATIBILITY
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   X    |

## EXAMPLE

```powershell
Write-TAPSLog -Type "Information" -Message "A demo message" -Scriptname "TAMPowerShell"
```
## PARAMETERS

### -Type
The log type.

```yaml
Type: String
Accepted values: Information, Error
Required: True
Position: Named
Default value: None
```

### -Message
 A log message, e.g. the error message.

```yaml
Type: String
Required: True
Position: Named
Default value: None
```

### -Scriptname
The name for the logfile. If the parameter is not defined the logfile is in the format TAPSLog-[CurrentDate].log. .

```yaml
Type: String
Required: False
Position: Named
Default value: None
```

### -Exception
 The full exception from an error.

```yaml
Type: Undefined
Required: False
Position: Named
Default value: None
```

