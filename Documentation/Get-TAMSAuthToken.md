| Command                                                      | Author                                                      | Module                                                |
| ------------------------------------------------------------ | ------------------------ | ------------------------ |
|**[Get-TAMSAuthToken](/Commands/Authentication/Get-TAMSAuthToken.ps1)**  |[Tobias Asböck](https://www.linkedin.com/in/tobiasasboeck/) |[TAMPowerShell](/Documentation/Module/TAMPowerShell.md) |

# Get-TAMSAuthToken

## SYNOPSIS

Receives an OAuth authentication token from Microsoft APIs. 



## SYNTAX

#### Using a certificate with Application permissions
```powershell
Get-TAMSAuthToken [-CertThumbprint <String>] [-API <String>] [-Tenantname <String>] [-AppID <String>] [-PermissionType <String>] 
[-ReturnAuthHeader] [<CommonParameters>]
```
#### Using a client secret with Application permissions
```powershell
Get-TAMSAuthToken [-ClientSecret <String>] [-API <String>] [-Tenantname <String>] [-AppID <String>] [-PermissionType <String>] 
[-ReturnAuthHeader] [<CommonParameters>]
```
#### Using a certificate with Delegated permissions
```powershell
Get-TAMSAuthToken [-CertThumbprint <String>] [-API <String>] [-Tenantname <String>] [-AppID <String>] [-PermissionType <String>] 
[-AppRedirectUri <String>] [-ReturnAuthHeader] [<CommonParameters>]
```
#### Using a client secret with Delegated permissions
```powershell
Get-TAMSAuthToken [-ClientSecret <String>] [-API <String>] [-Tenantname <String>] [-AppID <String>] [-PermissionType <String>] 
[-AppRedirectUri <String>] [-ReturnAuthHeader] [<CommonParameters>]
```


## DESCRIPTION

To get information from Microsoft APIs an authentication token is required. The command receives an OAuth token for Delegated and/or Application permissions with Client Secret or Certificate authentication. In the default configuration the token is valid for 3600 seconds (60 minutes).

**Prerequisites:**

- An existing Azure App Registration 
- Client secret key or certificate added to the App Registration 
- Application or Delegated permissions to the API
- Command [New-TAMSAuthJWT](/Documentation/New-TAMSAuthJWT.md)  
- Command [Show-TAAuthWindow](/Documentation/Show-TAAuthWindow.md)  
  



**Supported Azure App Registrations:**

- Single tenant apps



**Supported Microsoft APIs:**

 - [Microsoft Graph API](https://docs.microsoft.com/en-us/graph/overview)
 - [SharePoint Online REST API](https://docs.microsoft.com/en-us/sharepoint/dev/sp-add-ins/get-to-know-the-sharepoint-rest-service)
 - [OneDrive for Business REST API](https://docs.microsoft.com/en-us/sharepoint/dev/sp-add-ins/get-to-know-the-sharepoint-rest-service)  
- [Office 365 Service Communications API](https://docs.microsoft.com/en-us/office/office-365-management-api/office-365-service-communications-api-reference)   
 - [Office 365 Management Activity API](https://docs.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-reference) (Enterprise)  
   


## Compatibility
|              | Tested |
| :----------: | :----: |
| PowerShell 7 |   X    |
| PowerShell 5 |   X    |



## TAM365 REFERENCES

[Informationen von Microsoft  Graph beziehen | TAM365 Blog](https://blog.topedia.com/?p=6680) (in German)  
[Client Secrets und Zertifikate von Azure Apps ersetzen | TAM365 Blog](https://blog.topedia.com/2021/02/client-secrets-und-zertifikate-von-azure-apps-ersetzen) (in German) 



## EXAMPLES

#### EXAMPLE 1
```powershell
Get-TAMSAuthToken -CertThumbprint "8AE434B2A0F361E6783CC4858A78CD6653FD8843" -API SharePoint -Tenantname contoso.onmicrosoft.com -AppId "69dc00r2-d7d7-4835-a16a-d2f299854j37" -PermissionType Application -ReturnAuthHeader
```

Receives an authentication token for Application permissions and the SharePoint Online REST API with a local certificate. The token is returned as an authentication header. 

#### EXAMPLE 2
```powershell
Get-TAMSAuthToken -CertThumbprint "8AE434B2A0F361E6783CC4858A78CD6653FD8843" -API Graph -Tenantname contoso.onmicrosoft.com -AppId "69dc00r2-d7d7-4835-a16a-d2f299854j37" -PermissionType Delegated -AppRedirectUri "http://localhost/myapp/" 
```

Receives an authentication token for Delegated  permissions and the Microsoft Graph API with a local certificate. The token is returned in original format with the expiration time. 

#### EXAMPLE 3
```powershell
Get-TAMSAuthToken -ClientSecret "ARandomClientSecretID" -API Management -Tenantname contoso.onmicrosoft.com -AppId "69dc00r2-d7d7-4835-a16a-d2f299854j37" -PermissionType Delegated -AppRedirectUri "http://localhost/myapp/" -ReturnAuthHeader
```

Receives an authentication token for Delegated permissions and the Office 365 Service Communications API with a client secret key. The token is returned as an authentication header. 



## PARAMETERS

### -CertThumbprint
The Thumbprint of the certificate. The private key of the certificate must be available in the local cert store. 

```yaml
Type: String
Parameter Sets: Using a certificate with Application permissions, Using a certificate with Delegated permissions
Required: False
Position: Named
Default value: None
```
### -ClientSecret
The Client Secret of  the Azure App Registration. 

```yaml
Type: String
Parameter Sets: Using a client secret with Application permissions, Using a client secret with Delegated permissions
Required: False
Position: Named
Default value: None
```
### -API
The required Microsoft API. 
 - Graph > Microsoft Graph API (Default)
 - SharePoint > SharePoint Online REST API
 - OneDrive > OneDrive for Business REST API
 - Management > Office 365 Service Communications API and Office 365 Management Activity API (Enterprise)

```yaml
Type: String
Accepted values: Graph, SharePoint, OneDrive, Management
Required: True
Position: Named
Default value: Graph
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

### -PermissionType
The permission type for the API request (Application or Delegated permissions). 

```yaml
Type: String
Accepted values: Application, Delegated
Required: True
Position: Named
Default value: None
```

### -AppRedirectUri
The redirect uri defined in the Azure App Registration.

```yaml
Type: String
Parameter Sets: Using a certificate with Delegated permissions, Using a client secret with Delegated permissions
Required: False
Position: Named
Default value: None
```

### -ReturnAuthHeader
Returns the authentication token in a header format for additional requests. 

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: None
```



## RELATED LINKS

[Register an application with the Microsoft identity platform | Microsoft](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)  
[Authentication and authorization basics for Microsoft Graph | Microsoft](https://docs.microsoft.com/en-us/graph/auth/auth-concepts)  
[Single tenant and multi-tenant apps | Microsoft](https://docs.microsoft.com/bs-cyrl-ba/azure/active-directory/develop/single-and-multi-tenant-apps)  