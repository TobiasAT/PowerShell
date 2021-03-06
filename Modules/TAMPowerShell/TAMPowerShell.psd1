#
# Module manifest for module 'TAMPowerShell'
# Author: Tobias Asboeck
# Blog: https://blog.topedia.com
# LinkedIn: https://www.linkedin.com/in/tobiasasboeck
# GitHub: https://github.com/TobiasAT/PowerShell
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'TAMPowerShell.psm1'

# Version number of this module.
ModuleVersion = '1.1'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '32df1a12-6f35-4419-995a-5d199c414fb3'

# Author of this module
Author = 'Tobias Asboeck - https://www.linkedin.com/in/tobiasasboeck'

# Company or vendor of this module
CompanyName = ''

# Copyright statement for this module
Copyright = '(c) Tobias Asboeck. All rights reserved.'

# Description of the functionality provided by this module
Description = 'For details about this module please visit https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Module/TAMPowerShell.md'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @("Get-TAMSAuthToken","Get-TAMSGraphAllResults","New-TAMSAuthJWT","Show-TAAuthWindow","Write-TAPSLog")

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("Microsoft Graph","API","PowerShell","TAM365")

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Module/TAMPowerShell.md'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'https://github.com/TobiasAT/PowerShell/blob/main/Documentation/ReleaseNotes/TAMPowerShell.md'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

