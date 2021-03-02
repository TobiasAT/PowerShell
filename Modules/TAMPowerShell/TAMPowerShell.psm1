

#Region Get-TAMSAuthToken

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


#EndRegion Get-TAMSAuthToken

#Region New-TAMSAuthJWT

function New-TAMSAuthJWT
{	
	<#  
		.SYNOPSIS  
		 Builds a JSON Web Token (JWT) for an Azure app certificate authentication.

		.DESCRIPTION
		Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/New-TAMSAuthJWT.md.
	#> 
	
	param( 	
		[Parameter(Mandatory=$true)][string]$CertThumbprint, 
		[Parameter(Mandatory=$true)]
		[ValidateScript({$_ -like '*.onmicrosoft.com'})][string]$Tenantname, 
		[Parameter(Mandatory=$true)][string]$AppID	
	)

	# Loading the certificate from the local cert store
	$Certificate = (Get-ChildItem -Path cert:\* -Recurse | Where-Object{$_.Thumbprint -eq $CertThumbprint -and $_.PrivateKey.Count -eq 1 })

	if( $null -ne $Certificate.Thumbprint)
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
Function Show-TAAuthWindow
{   
    <#  
		.SYNOPSIS  
		Build and show an (oauth) authentication window (e.g. for an API authentication with Delegated permissions).

		.DESCRIPTION
		Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Show-TAAuthWindow.md.
	#> 

    param([Parameter(Mandatory=$true)][System.Uri]$Url )

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

#Region Write-TAPSLog

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

#EndRegion Write-TAPSLog

#Region Get-TAMSGraphAllResults

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

#EndRegion Get-TAMSGraphAllResults

