
function Get-TAMSAuthToken
{ 	
	<#  
		.SYNOPSIS  
		Receives an authentication token from Microsoft APIs.

		.DESCRIPTION
		Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Get-TAMSAuthToken.md.
	#> 
	
	param( 
	[Parameter(Mandatory=$true, ParameterSetName = 'ClientSecret')][string]$ClientSecret,
	[Parameter(Mandatory=$true, ParameterSetName = 'Certificate')][string]$CertThumbprint,	
	[Parameter(Mandatory=$true)]
	[ValidateScript({$_ -like '*.onmicrosoft.com'})][string]$Tenantname,
	[Parameter(Mandatory=$true)][string]$AppID,		
	[Parameter(Mandatory=$true)]
	[ValidateSet('Graph','SharePoint','OneDrive','Management')]
	[string]$API,	
	[Parameter(Mandatory=$true)]
	[ValidateSet('Application','Delegated')]
	[string]$PermissionType,	
	[switch]$ReturnAuthHeader
	
	)	
	
	DynamicParam{
        $AttrCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParamDic = new-object System.Management.Automation.RuntimeDefinedParameterDictionary				
		
        if ($PermissionType -eq 'Delegated')
		{   $ParamAttribute = new-object System.Management.Automation.ParameterAttribute
            $ParamAttribute.Mandatory = $true
            $AttrCollection.Add($ParamAttribute)           
            $DynamicParam = new-object System.Management.Automation.RuntimeDefinedParameter('AppRedirectUri', [string], $AttrCollection)
            $ParamDic.Add('AppRedirectUri', $DynamicParam)
            return $ParamDic
        }        

    }	
	
	process{ 
				
		$TokenUrl = "https://login.microsoftonline.com/$Tenantname/oauth2/v2.0/token"	
		$Tenant = $Tenantname.Replace('.onmicrosoft.com','')		
		
		if( $API -eq 'SharePoint' )
		{ $AuthScope = "https://$Tenant.sharepoint.com/.default" } 
		elseif( $API -eq 'OneDrive' )
		{ $AuthScope = "https://$Tenant-my.sharepoint.com/.default" }
		elseif( $API -eq 'Management' )
		{ $AuthScope = 'https://manage.office.com/.default' }
		else
		{ $AuthScope = 'https://graph.microsoft.com/.default' }	
		
		
		if( $PermissionType -eq 'Delegated' )	
        {	
			if( (get-command Show-TAAuthWindow -ErrorAction SilentlyContinue).Count -eq 0 )
			{  Write-Error 'Command Show-TAAuthWindow is required.'; Write-Information 'Please download the command from my PowerShell Repository at https://github.com/TobiasAT/PowerShell.'; return }
								
			if($PSVersionTable.PSVersion.Major -lt 6 )
			{ Add-Type -AssemblyName System.Web }
			
			$URLEncodedredirectUri = [System.Web.HttpUtility]::UrlEncode($PSBoundParameters.AppRedirectUri)			
			$AuthUrl  = "https://login.microsoftonline.com/$Tenantname/oauth2/v2.0/authorize" +
							'?client_id='    + $AppID +                
							'&redirect_uri=' + $URLEncodedredirectUri  +
							'&response_type=code' +
							'&response_mode=query' +
							'&scope=' + $AuthScope	

			$queryOutput = Show-TAAuthWindow -Url $AuthUrl			
			$AuthCode = $queryOutput.Code	
			
		}
		
		if($CertThumbprint -ne '' )
		{	
			if( (get-command New-TAMSAuthJWT -ErrorAction SilentlyContinue).Count -eq 0 )
			{   Write-Error 'Command New-TAMSAuthJWT is required.'; Write-Information 'Please download the command from my PowerShell Repository at https://github.com/TobiasAT/PowerShell.'; return }
			
			$AuthJWT = New-TAMSAuthJWT -CertThumbprint $CertThumbprint -Tenantname $Tenantname -AppID $AppID
					
			if($null -ne $AuthJWT)
			{   # Create body for certificate authentication 
			
				if( $PermissionType -eq 'Application' )
				{   $Body = @{
						client_id = $AppId
						client_assertion = $AuthJWT
						client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
						scope = $AuthScope
						grant_type = 'client_credentials'
					}
				}
				else
				{   $Body = @{
						client_id = $AppId
						client_assertion = $AuthJWT
						client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
						redirect_uri = $PSBoundParameters.AppRedirectUri
						grant_type = 'authorization_code'
						code = $AuthCode
					}
				}
			} else
			{ Write-Error 'AuthJWT was not built.'; return }		
			
		} else		
		{	
			if( $PermissionType -eq 'Application' )
			{
				$Body = @{
					client_id = $AppId
					client_secret = $ClientSecret
					scope = $AuthScope
					grant_type = 'client_credentials'
				}
			}
			else
			{	$Body = @{
					client_id = $AppId
					client_secret = $ClientSecret
					scope = $AuthScope 
					redirect_uri = $PSBoundParameters.AppRedirectUri
					grant_type = 'authorization_code'				
					code = $AuthCode
				}				
			}		
		}

		
		$AuthToken = Invoke-RestMethod -Method Post -Uri $TokenUrl -Body $Body 
		if($ReturnAuthHeader -eq $false )
		{ $AuthToken }
		else
		{   $AuthHeader = @{ Authorization = "$($AuthToken.token_type) $($AuthToken.access_token)" }	
			$AuthHeader
		}	
	}

}

