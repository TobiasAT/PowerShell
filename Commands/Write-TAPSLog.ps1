
function Write-TAPSLog
{ 
    <#  
		.SYNOPSIS  
		Adds or appends a new line to a log file.

		.DESCRIPTION
		Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Write-TAPSLog.md.

	#> 
    
    param ( 
    [parameter(Mandatory=$true)]
    [ValidateSet('Information','Error')]
    [string]$Type,

    [parameter(Mandatory=$true)]
    [string]$Message,
    [string]$Scriptname,
    $Exception
)

    # Define the script and logfile name
    if($Scriptname -eq "")
        { $Scriptname = ("TAPSLog-" + (Get-Date -Format "dd-MM-yyyy"))   }

    $LogDir = "C:\ScriptLog"

    # Verify that the logfolder is created, else add the folder
    if((Test-Path $LogDir) -eq $false )
        { New-Item -ItemType directory -Path $LogDir | out-null }

    $Script:Logfile = $LogDir + "\$Scriptname.log"

    # Verify whether the logfile is already created, if not create a new file
    if($null -eq (Get-Item $Logfile -ErrorAction SilentlyContinue))
        { ("Date/Time;Type;Message;Exception") | out-file $Logfile }

    Write-Output ((get-date -format G) + "; " + $Type + "; " + $Message + "; " + $Exception) | out-file $Logfile -append

}

