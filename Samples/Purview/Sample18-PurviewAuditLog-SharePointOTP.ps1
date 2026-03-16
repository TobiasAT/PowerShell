
<#
.SYNOPSIS
    Queries the Microsoft Purview Audit Log for SharePoint OTP authentication events.
    Sample for my post at https://blog-en.topedia.com/?p=64003. 

.DESCRIPTION
    Connects to Microsoft Graph using the AuditLogsQuery scopes and submits an audit log query
    via the Graph beta API targeting the SharePoint EmailAuthOTPAuthenticationSucceeded operation
    over the last 180 days. The script polls the query status until it succeeds (up to 60 minutes)
    and then retrieves all result records with paging support.
    Results are output showing the event date, user principal name, operation, and service.

.NOTES
    .Author: Tobias Asboeck - https://www.linkedin.com/in/tobiasasboeck/
    .Date: 2026-03-16
#>

Import-Module Microsoft.Graph.Authentication
Connect-MgGraph -Scopes AuditLogsQuery-SharePoint.Read.All, AuditLogsQuery-OneDrive.Read.All

# Create a new Audit Log Query for SharePoint OTP authentication events in the last 180 days
$StartDate = (Get-Date).AddDays(-180).ToString("yyyy-MM-ddT00:00:00Z")
$EndDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

$Body = 
@"
{
    "displayName": "MSGraphAuditlogQuery-SPOOTP",
    "filterStartDateTime": "$StartDate",
    "filterEndDateTime": "$EndDate",
    "serviceFilters": ["SharePoint"],    
    "operationFilters": [
        "EmailAuthOTPAuthenticationSucceeded"
    ],
  }
"@

$Url = "https://graph.microsoft.com/beta/security/auditLog/queries"
$AuditLogNewQuery = Invoke-MgGraphRequest -Method POST -Uri $Url -Body $Body -ContentType "application/json"

# Poll the query status until it is completed, wait up to 60 minutes
$AuditLogNewQueryID = $AuditLogNewQuery.id
$QueryUrl = "https://graph.microsoft.com/beta/security/auditLog/queries/$AuditLogNewQueryID"

$QueryTimeoutMinutes = 60
$QueryPollIntervalSeconds = 60
$QueryStartTime = Get-Date

do {
    $Result = Invoke-MgGraphRequest -Method Get -Uri $QueryUrl -ContentType "application/json"

    Write-Host ("[{0}] Status: {1}" -f (Get-Date -Format "HH:mm:ss"), $Result.status)

    if ($Result.status -eq "succeeded") {
        Write-Host "Audit log query completed successfully."
        break
    }

    if ($Result.status -eq "failed") {
        throw "Audit log query failed. QueryId: $AuditLogNewQueryID"
    }

    Start-Sleep -Seconds $QueryPollIntervalSeconds

} while ((Get-Date) -lt $QueryStartTime.AddMinutes($QueryTimeoutMinutes))

if ($Result.status -ne "succeeded") {
    throw "Timeout reached. Audit log query did not complete within $QueryTimeoutMinutes minutes."
}


# Get the results of the search job (paging included)
$Url = "https://graph.microsoft.com/beta/security/auditLog/queries/$AuditLogNewQueryID/records?`$top=1000"
$AuditLogNewQueryResultRecords = @()

While ( $null -ne $Url ) {
    $data = Invoke-MgGraphRequest -Method GET -Uri $Url -ContentType "application/json" 
    $AuditLogNewQueryResultRecords += $data.Value         
    $Url = $data.'@odata.nextLink'
}

# Output the results
$AuditLogNewQueryResultRecords | select createdDateTime,userPrincipalName,operation,service | fl


