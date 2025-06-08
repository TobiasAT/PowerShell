

<#
.SYNOPSIS
    Retrieves SharePoint Embedded containers filtered by OwningApplication with paging support.

.DESCRIPTION
    This script connects to SharePoint Online (requires connection) and fetches all SharePoint Embedded containers
    for either Microsoft Loop, Microsoft Designer or both. It handles paging automatically.

    For more information read my blog post at https://blog-en.topedia.com/?p=51401.

.PARAMETER OwningApplication
    Optional, the owning application to filter containers. 
    Acceptable values:
    - All (default) > collects containers for all applications (Loop and Designer) 
    - MicrosoftLoop > collects containers for Microsoft Loop
    - MicrosoftDesigner > collects containers for Microsoft Designer

.EXAMPLE
    .\Get-TAAllSPEContainers.ps1 -OwningApplication MicrosoftLoop

    Retrieves SharePoint Embedded containers related to Loop Workspaces.

.NOTES
    - Requires PowerShell 5.x and the Microsoft.Online.SharePoint.PowerShell module.
    - You must be connected to SharePoint Online using Connect-SPOService before running.

    Author: Tobias Asböck - https://www.linkedin.com/in/tobiasasboeck    
    Update Date: 8 June 2025

#>

param(
    [ValidateSet("MicrosoftLoop", "MicrosoftDesigner", "All")]
    [string]$OwningApplication = "All"
)

#requires -Module Microsoft.Online.SharePoint.PowerShell

if ($PSVersionTable.PSVersion.Major -ne 5) {
    Write-Error "This script must be run in PowerShell 5.x (due to the SharePoint Online PowerShell module)."
    exit 1
}

try {
    # Lightweight connection check
    Get-SPOTenant -ErrorAction Stop | Out-Null
} catch {
    Write-Error "Please connect to SharePoint Online first using Connect-SPOService."
    exit 1
}

# Map application to GUID
$SPEContainerIdMap = @{
    "MicrosoftLoop"     = "a187e399-0c36-4b98-8f04-1edc167a0996"
    "MicrosoftDesigner" = "5e2795e3-ce8c-4cfb-b302-35fe5cd01597"
}

$SPEContainerApps = if ($OwningApplication -eq "All") {
    $SPEContainerIdMap.Keys
} else {
    @($OwningApplication)
}

$AllSPEContainers = @()

foreach ($SPEApp in $SPEContainerApps) {
    Write-Host "Collecting containers for $SPEApp..." -ForegroundColor Cyan

    $OwningApplicationId = $SPEContainerIdMap[$SPEApp]
    $SPOContainers = Get-SPOContainer -OwningApplicationId $OwningApplicationId -Paged

    # When using -Paged, Get-SPOContainer returns up to 200 items, plus a paging marker as the 201st item.
    # The marker is a string with a paging token at the end, which must be extracted manually.
    # On the final page, the last item will instead be "End of containers view", indicating there are no more pages to load.

    if ($SPOContainers.Count -eq 201 -and $SPOContainers[200] -like "Retrieve remaining containers*") {
        $CurrentContainers = $SPOContainers[0..199]
        $PagingID = $SPOContainers[200].Split(" ")[-1]

        while ($true) {
            $SPOContainers = Get-SPOContainer -OwningApplicationId $OwningApplicationId -Paged -PagingToken $PagingID
            $lastItem = $SPOContainers[-1]

            if ($lastItem -like "Retrieve remaining containers*") {
                $CurrentContainers += $SPOContainers[0..199]
                if ($SPOContainers.Count -gt 200) {
                    $PagingID = $SPOContainers[200].Split(" ")[-1]
                } else {
                    Write-Warning "Expected paging marker at position 200, but fewer items were returned."
                    break
                }
            } elseif ($lastItem -like "End of containers view*") {
                if ($SPOContainers.Count -gt 1) {
                    $CurrentContainers += $SPOContainers[0..($SPOContainers.Count - 2)]
                }
                break
            } else {
                $CurrentContainers += $SPOContainers
                break
            }
        }

        $AllSPEContainers += $CurrentContainers
    } else {
        $AllSPEContainers += $SPOContainers
    }
}

# Output the end result
return $AllSPEContainers
