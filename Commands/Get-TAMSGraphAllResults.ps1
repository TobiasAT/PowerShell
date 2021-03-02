
function Get-TAMSGraphAllResults
{ 
	<#  
		.SYNOPSIS  
		Receives all results from a Microsoft Graph REST request (paging).

		.DESCRIPTION
		Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Get-TAMSGraphAllResults.md.

	#> 
	
	param( [Parameter(Mandatory=$true)]$Results,
        [Parameter(Mandatory=$true)]$AuthHeader
 	) 
	
	$AllResults = $Results.value
	while ($null -ne $Results.'@odata.nextLink' )
	{   $Results = Invoke-RestMethod -Method Get -Headers $AuthHeader -Uri $Results.'@odata.nextLink' -ContentType 'application/json'		
		$AllResults += $Results.value 		
	}
	$AllResults
	
}
