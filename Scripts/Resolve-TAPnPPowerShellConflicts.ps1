
<#
  .SYNOPSIS
    This script resolves known conflicts between the PnP.PowerShell and Microsoft.Graph.Authentication PowerShell modules.
    For my blog post at https://blog-en.topedia.com/2024/04/fix-conflicts-between-pnppowershell-and-microsoftgraphauthentication-module. 

  .DESCRIPTION
    The Resolve-TAPnPPowerShellConflicts script checks the installed versions of the PnP.PowerShell and Microsoft.Graph.Authentication modules. 
    If the modules are installed and their versions are 2.* or higher, the script proceeds to check the versions of Microsoft.Graph.Core.dll and Microsoft.Identity.Client.dll in the PnP.PowerShell module directory.
    - If Microsoft.Graph.Core.dll exists in the PnP.PowerShell module directory, the file is deleted to avoid conflicts.
    - If the version of Microsoft.Identity.Client.dll in the PnP.PowerShell module directory is 4.50.*, the script attempts to copy it from the Microsoft.Graph.Authentication directory.

  .EXAMPLE
    Resolve-TAPnPPowerShellConflicts

  .NOTES
    It's recommended to close your PowerShell sessions first before running this script to avoid file conflicts.
    In case of issues with the PnP.PowerShell module just update the module with the following command: Update-Module PnP.PowerShell -Force

    Author: Tobias Asboeck - https://github.com/TobiasAT/PowerShell 
    Date: 20.03.2024

  .LINK
  https://topedia.net/QUDaEa
#>

# Get the directory of the PnP.PowerShell module
$PnPModuleDirectory = Get-Module PnP.PowerShell -ListAvailable | ?{$_.Version -like "2.*" } | sort Version -Descending

# Check if the PnP.PowerShell module is installed
if( $PnPModuleDirectory.Count -gt 0 )
{ 
    # If it is, set the $PnPModuleDirectory to the ModuleBase of the first (latest version) module
    $PnPModuleDirectory = $PnPModuleDirectory[0].ModuleBase 
}
else
{ 
    # If it's not, display an error message and exit the script
    Write-Host "PnP PowerShell module not installed" -f red; return 
}

# Get the directory of the Microsoft.Graph.Authentication module
$MgGraphAuthModuleDirectory = Get-Module Microsoft.Graph.Authentication -ListAvailable | ?{$_.Version -like "2.*" } | sort Version -Descending

# Check if the Microsoft.Graph.Authentication module is installed
if( $MgGraphAuthModuleDirectory.Count -gt 0 )
{ 
    # If it is, set the $MgGraphAuthModuleDirectory to the ModuleBase of the first (latest version) module
    $MgGraphAuthModuleDirectory = $MgGraphAuthModuleDirectory[0].ModuleBase 
}
else
{ 
    # If it's not, display an error message and exit the script
    Write-Host "Microsoft.Graph.Authentication module not installed" -f red; return 
}

# Check the version of Microsoft.Graph.Core.dll
Write-Host "Checking Microsoft.Graph.Core.dll version..." -f Yellow
if( Test-Path ($PnPModuleDirectory + "\Core\Microsoft.Graph.Core.dll")) {
  Write-Host "Deleting Microsoft.Graph.Core.dll from PnP.PowerShell module directory" 

  # Try to delete the Microsoft.Graph.Core.dll file
  try {
    Remove-Item -Path ($PnPModuleDirectory + "\Core\Microsoft.Graph.Core.dll") -Force -ErrorAction Stop
  }
  catch {
    # If the file is in use and can't be deleted, display an error message
    Write-Host "Error deleting Microsoft.Graph.Core.dll, file is in use. Please close any PowerShell sessions and try again." -f Red
  }    
} 
else { 
  # If the file doesn't exist, display a message
  Write-Host "Microsoft.Graph.Core.dll has already been deleted in PnP.PowerShell module directory" 
}  

# Check the version of Microsoft.Identity.Client.dll
Write-Host "Checking Microsoft.Identity.Client.dll version..." -f Yellow
$PnPIdentityClientFile = Get-Item -Path ($PnPModuleDirectory + "\Core\Microsoft.Identity.Client.dll")
if( $PnPIdentityClientFile.VersionInfo.FileVersion -like "4.5.*" ) {

  Write-Host "Copying Microsoft.Identity.Client.dll from Microsoft.Graph.Authentication to PnP.PowerShell module directory"   

  # Try to copy the Microsoft.Identity.Client.dll file from the Microsoft.Graph.Authentication module to the PnP.PowerShell module
  try {
    Get-Item -Path ($MgGraphAuthModuleDirectory + "\Dependencies\Core\Microsoft.Identity.Client.dll")  | Copy-Item -Destination ($PnPModuleDirectory + "\Core") -Force -ErrorAction Stop
  }
  catch {
    # If the file is in use and can't be copied, display an error message
    Write-Host "Error copying Microsoft.Identity.Client.dll, file is in use. Please close any PowerShell sessions and try again." -f Red
  }  
} else 
{ 
  # If the version of the file is not 4.5.*, display a message
  Write-Host "Skipped, Microsoft.Identity.Client.dll version is not 4.50.*" 
}

