
<#
    .SYNOPSIS
        Retrieves Microsoft-owned SharePoint Embedded containers with optional detailed output and paging support.

    .DESCRIPTION
        This script connects to SharePoint Online (requires an active session) and fetches all SharePoint Embedded containers
        owned by Microsoft. It includes automatic paging support for more than 200 containers.

        If the -IncludeDetails switch is specified, the script retrieves full metadata for each container.

        For additional context, see the related blog post: https://blog-en.topedia.com/?p=51401

    .PARAMETER OwningApplication
        Optional. Specifies which application to filter containers by.
        Acceptable values:
        - All (default): Retrieves all Microsoft-owned containers in your tenant
        - MicrosoftLoop: Retrieves only Loop Workspace containers
        - MicrosoftDesigner: Retrieves only Microsoft Designer containers
        - OutlookNewsletters: Retrieves only Outlook Newsletters containers
        - DeclarativeAgent: Retrieves only Declarative Agent containers
        - TeamsVirtualEventVOD: Retrieves only Teams Virtual Event VOD containers

    .PARAMETER IncludeDetails
        Optional. If specified, the script retrieves detailed metadata for each container (via an additional call per container).

    .EXAMPLE
        .\Get-TAAllSPEContainers.ps1 -OwningApplication MicrosoftLoop

        Retrieves all SharePoint Embedded containers owned by Microsoft Loop.

    .EXAMPLE
        .\Get-TAAllSPEContainers.ps1 -IncludeDetails

        Retrieves Microsoft-owned containers in your tenant, including detailed metadata for each.

    .NOTES
        - Requires PowerShell 5.x due to the SharePoint Online Management Shell module.
        - Ensure you're connected to SharePoint Online using Connect-SPOService before running this script.

        Author: Tobias Asböck — https://www.linkedin.com/in/tobiasasboeck  
        Last Updated: 14 August 2025
#>

[CmdletBinding()]
param(
    [ValidateSet("MicrosoftLoop", "MicrosoftDesigner", "OutlookNewsletters", "DeclarativeAgent", "TeamsVirtualEventVOD", "All")]
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
    "OutlookNewsletters" = "155d75a8-799c-4ad4-ae3f-0084ccced5fa"
    "DeclarativeAgent"   = "e8be65d6-d430-4289-a665-51bf2a194bda"
    "TeamsVirtualEventVOD" = "7fc21101-d09b-4343-8eb3-21187e0431a4"
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
    try { $SPOContainers = Get-SPOContainer -OwningApplicationId $OwningApplicationId -Paged } # The system returns an error if there’s no container for that application 
    catch { $SPOContainers = @() }

    # When using -Paged, Get-SPOContainer returns up to 200 items, plus a paging marker as the 201st item.
    # The marker is a string with a paging token at the end, which must be extracted manually.
    # On the final page, the last item will instead be "End of containers view", indicating there are no more pages to load.

    if($SPOContainers.Count -eq 0 ) { 
       Write-Information "No containers found for $SPEApp, skipping." 
    } else {
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
            # If there are less than 200 containers, remove the last item, which is the paging marker.
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

            # Reset the container list for the next SPE app, as only the detailed results are necessary
            $AllSPEContainers = @()     
        }
    }
}

# Output the end result
if( $IncludeDetails -eq $true) {
 return $AllSPEContainerDetails 
} else {
  return $AllSPEContainers
}
