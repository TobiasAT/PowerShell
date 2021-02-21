| Command                                                      | Author                                                      | Module                                                |
| ------------------------------------------------------------ | ------------------------ | ------------------------ |
|**[New-TAMSAuthJWT](/Commands/Authentication/New-TAMSAuthJWT.ps1)**  |[Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/) |[TAMPowerShell](/Documentation/Module/TAMPowerShell.md) |

# New-TAMSAuthJWT

## SYNOPSIS
Builds a JSON Web Token (JWT) for an Azure app certificate authentication. 

## SYNTAX

```powershell
New-TAMSAuthJWT [-CertThumbprint <String>] [-Tenantname <String>] [-AppID <String>] 
```

## Compatibility
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   X    |

## TAM365 REFERENCE
[Client Secrets und Zertifikate von Azure Apps ersetzen | TAM365 Blog](https://blog.topedia.com/2021/02/client-secrets-und-zertifikate-von-azure-apps-ersetzen)  

## EXAMPLE

```powershell
New-TAMSAuthJWT -CertThumbprint "8AE434B2A0F361E6783CC4858A78CD6653FD8843" -Tenantname "contoso.onmicrosoft.com" -AppID "69dc00r2-d7d7-4835-a16a-d2f299854j37"
```
## PARAMETERS

### -CertThumbprint
The Thumbprint of the authentication certificate. The private key of the certificate must be available in the local cert store.

```yaml
Type: String
Required: True
Position: Named
Default value: None
```

### -Tenantname
The Microsoft 365 tenant name. The format must be [Tenant].onmicrosoft.com.

```yaml
Type: String
Required: True
Position: Named
Default value: None
```

### -AppID
The Azure Application ID from the App Registration.

```yaml
Type: String
Required: True
Position: Named
Default value: None
```


## RELATED LINKS

[Microsoft identity platform application authentication certificate credentials | Microsoft](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-certificate-credentials)  
[JSON Web Token | Wikipedia](https://en.wikipedia.org/wiki/JSON_Web_Token)  