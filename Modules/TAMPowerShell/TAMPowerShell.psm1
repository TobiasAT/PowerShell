

#Region Get-TAMSAuthToken

<#  
    .DESCRIPTION  
    Receives an authentication token from Microsoft APIs.
    Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Get-TAMSAuthToken.md.
#> 
function Get-TAMSAuthToken
{ param( 
	[Parameter(Mandatory=$true, ParameterSetName = 'ClientSecret')][string]$ClientSecret,
	[Parameter(Mandatory=$true, ParameterSetName = 'Certificate')][string]$CertThumbprint,	
	[Parameter(Mandatory=$true)]
	[ValidateScript({$_ -like '*.onmicrosoft.com'})][string]$Tenantname,
	[Parameter(Mandatory=$true)][string]$AppID,		
	[Parameter(Mandatory=$true)]
	[ValidateSet('Graph','SharePoint','OneDrive','Management')]
	[string]$API = 'Graph',	
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
					
			if($AuthJWT -ne $null)
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

#EndRegion Get-TAMSAuthToken

#Region New-TAMSAuthJWT

<#  
    .DESCRIPTION  
    Builds a JSON Web Token (JWT) for an Azure app certificate authentication.
    Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/New-TAMSAuthJWT.md.
#> 


function New-TAMSAuthJWT
{	param( 	
		[Parameter(Mandatory=$true)][string]$CertThumbprint, 
		[Parameter(Mandatory=$true)]
		[ValidateScript({$_ -like '*.onmicrosoft.com'})][string]$Tenantname, 
		[Parameter(Mandatory=$true)][string]$AppID	
	)

	# Loading the certificate from the local cert store
	$Certificate = (Get-ChildItem -Path cert:\* -Recurse | ?{$_.Thumbprint -eq $CertThumbprint -and $_.PrivateKey.Count -eq 1 })

	if( $Certificate.Thumbprint -ne $null)
	{
		$TokenUrl = "https://login.microsoftonline.com/$Tenantname/oauth2/v2.0/token"	
		
		# Create JWT timestamp for expiration
		$StartDate = (Get-Date "1970-01-01T00:00:00Z" ).ToUniversalTime()				
		$JWTExpiration = [math]::Round((New-TimeSpan -Start $StartDate -End (Get-Date).AddMinutes(2)).TotalSeconds,0)

		# Create JWT validity start timestamp
		$JWTNotBefore = [math]::Round((New-TimeSpan -Start $StartDate -End ((Get-Date).AddMinutes(-1))).TotalSeconds,0)
	
		# Create JWT header
		$JWTHeader = @{
			alg = "RS256"
			typ = "JWT"				
			x5t = [System.Convert]::ToBase64String($Certificate.GetCertHash())
		} | ConvertTo-Json -Compress

		# Create JWT payload
		$JWTPayLoad = @{
			aud = $TokenUrl				
			exp = $JWTExpiration				
			iss = $AppID				
			jti = [guid]::NewGuid()			
			nbf = $JWTNotBefore				
			sub = $AppID
		} | ConvertTo-Json -Compress

		# Convert header and payload to base64
		$JWTHeaderToByte = [System.Text.Encoding]::UTF8.GetBytes($JWTHeader)
		$EncodedHeader = [System.Convert]::ToBase64String($JWTHeaderToByte) -replace '\+','-' -replace '/','_' -replace '='
		$JWTPayLoadToByte =  [System.Text.Encoding]::UTF8.GetBytes($JWTPayload)
		$EncodedPayload = [System.Convert]::ToBase64String($JWTPayLoadToByte) -replace '\+','-' -replace '/','_' -replace '='
		
		# Join header and Payload with "." to create a valid (unsigned) JWT
		$JWT = $EncodedHeader + '.' + $EncodedPayload	
		$JWTSignToken = [system.text.encoding]::UTF8.GetBytes($JWT)
		
		# Define RSA signature and crypto algorithm
		$RSACryptoSP = [System.Security.Cryptography.RSACryptoServiceProvider]::new()
		$SHA256CryptoSP = [System.Security.Cryptography.SHA256CryptoServiceProvider]::new()
		$SHA256oid = [System.Security.Cryptography.CryptoConfig]::MapNameToOID("SHA256");

		# Create a JWT signature with the private key of the certificate
		$RSACryptoSP.FromXmlString($Certificate.PrivateKey.ToXmlString($true))
		$hashBytes = $SHA256CryptoSP.ComputeHash($JWTSignToken)		
		$SignedHashBytes = $RSACryptoSP.SignHash($hashBytes, $SHA256oid)
		$CertPrivateSignature = [Convert]::ToBase64String($SignedHashBytes) -replace '\+','-' -replace '/','_' -replace '=' 
		$SHA256CryptoSP.Dispose()
		$RSACryptoSP.Dispose()

		# Join the signature to the JWT with "."
		$JWT = $JWT + "." + $CertPrivateSignature
		$JWT

	}
	else
	{ Write-Error  "Certificate with ID $CertThumbprint not found" }


}

#Region New-TAMSAuthJWT

#Region Show-TAAuthWindow

<#  
    .DESCRIPTION  
    Build and show an (oauth) authentication window (e.g. for an API authentication with Delegated permissions).
    Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Show-TAAuthWindow.md.
#> 


Function Show-TAAuthWindow
{   param([Parameter(Mandatory=$true)][System.Uri]$Url )

    Add-Type -AssemblyName System.Windows.Forms
 
    $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=440;Height=640}
    $web  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=420;Height=600;Url=($url ) }
    $DocComp  = 
	{   $Global:uri = $web.Url.AbsoluteUri
        if ($Global:Uri -match "error=[^&]*|code=[^&]*") {$form.Close() }
    }
	
    $web.ScriptErrorsSuppressed = $true
    $web.Add_DocumentCompleted($DocComp)
    $form.Controls.Add($web)
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() | Out-Null

    $queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)
    $output = @{}
    foreach($key in $queryOutput.Keys)
	{ $output["$key"] = $queryOutput[$key] }
   
    $output
}

#EndRegion Show-TAAuthWindow
