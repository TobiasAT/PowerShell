
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


