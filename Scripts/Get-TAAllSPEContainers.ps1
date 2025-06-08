

<#
    .SYNOPSIS
        Retrieves all SharePoint Embedded containers for Loop and/or Designer with optional detailed output and paging support.

    .DESCRIPTION
        This script connects to SharePoint Online (requires an active session) and fetches all SharePoint Embedded containers
        owned by Microsoft Loop, Microsoft Designer, or both. It includes automatic paging support for more than 200 containers.

        If the -IncludeDetails switch is specified, the script retrieves full metadata for each container.

        For additional context, see the related blog post: https://blog-en.topedia.com/?p=51401

    .PARAMETER OwningApplication
        Optional. Specifies which application to filter containers by.
        Acceptable values:
        - All (default): Retrieves containers for both Loop and Designer
        - MicrosoftLoop: Retrieves only Loop Workspace containers
        - MicrosoftDesigner: Retrieves only Microsoft Designer containers

    .PARAMETER IncludeDetails
        Optional. If specified, the script retrieves detailed metadata for each container (via an additional call per container).

    .EXAMPLE
        .\Get-TAAllSPEContainers.ps1 -OwningApplication MicrosoftLoop

        Retrieves all SharePoint Embedded containers owned by Microsoft Loop.

    .EXAMPLE
        .\Get-TAAllSPEContainers.ps1 -IncludeDetails

        Retrieves all containers across Loop and Designer, including detailed metadata for each.

    .NOTES
        - Requires PowerShell 5.x due to the SharePoint Online Management Shell module.
        - Ensure you're connected to SharePoint Online using Connect-SPOService before running this script.

        Author: Tobias Asböck — https://www.linkedin.com/in/tobiasasboeck  
        Last Updated: 8 June 2025
#>


param(
    [ValidateSet("MicrosoftLoop", "MicrosoftDesigner", "All")]
    [string]$OwningApplication = "All",
    [switch]$IncludeDetails 
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
$AllSPEContainerDetails = @()

foreach ($SPEApp in $SPEContainerApps) {
    Write-Host "Collecting containers for $SPEApp..." -ForegroundColor Cyan

    $OwningApplicationId = $SPEContainerIdMap[$SPEApp]
    $SPOContainers = Get-SPOContainer -OwningApplicationId $OwningApplicationId -Paged

    # When using -Paged, Get-SPOContainer returns up to 200 items, plus a paging marker as the 201st item.
    # The marker is a string with a paging token at the end, which must be extracted manually.
    # On the final page, the last item will instead be "End of containers view", indicating there are no more pages to load.

    if ($SPOContainers.Count -eq 201 -and $SPOContainers[200] -like "Retrieve remaining containers*") {
        $CurrentContainers = $SPOContainers[0..199]
        $PagingToken = $SPOContainers[200].Split(" ")[-1]

        while ($true) {
            $SPOContainers = Get-SPOContainer -OwningApplicationId $OwningApplicationId -Paged -PagingToken $PagingToken
            $lastItem = $SPOContainers[-1]

            if ($lastItem -like "Retrieve remaining containers*") {
                $CurrentContainers += $SPOContainers[0..199]
                if ($SPOContainers.Count -gt 200) {
                    $PagingToken = $SPOContainers[200].Split(" ")[-1]
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
        $AllSPEContainers += $SPOContainers[0..($SPOContainers.Count - 2)]
    }

    # If specified, the script retrieves detailed metadata for each container.
    # Depending on the number of containers, this may take a while.
    if( $IncludeDetails -eq $true) {

        $Count = 1
        $TotalContainers = $AllSPEContainers.Count
        foreach ($SPEContainer in $AllSPEContainers) {
            Write-Host "   Collecting details for container $Count of $TotalContainers`: $($SPEContainer.ContainerId)" 
            $AllSPEContainerDetails += Get-SPOContainer -Identity $SPEContainer.ContainerId
            $Count++
        } 

        $AllSPEContainers = @()     
    }
}

# Output the end result
if( $IncludeDetails -eq $true) {
 return $AllSPEContainerDetails 
} else {
  return $AllSPEContainers
}


