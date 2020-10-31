
# Sample how to create a new DLP policy via PowerShell for https://go.topedia.com/zcvbp

# Replace the Guid with a sample policy from your tenant. All non-business connectors should be included in the sample policy. 
Add-PowerAppsAccount
$DLPPolicy = Get-DlpPolicy -PolicyName [PolicyGuid]

# Receive the connectors for SharePoint, OneDrive, Facebook and Outlook Mails
$DLPSharePointConnector = $DLPPolicy.connectorGroups.connectors | ?{$_.Name -eq "SharePoint" }
$DLPOneDriveConnector = $DLPPolicy.connectorGroups.connectors | ?{$_.Name -eq "OneDrive for Business" }
$DLPFacebookConnector = $DLPPolicy.connectorGroups.connectors | ?{$_.Name -eq "Facebook" }
$DLPO365OutlookConnector = $DLPPolicy.connectorGroups.connectors | ?{$_.Name -eq "Office 365 Outlook" }

# Name your new policy
$DLPPolicyName = "Allow SharePoint, OneDrive, Exchange, Block Facebook"

# Add an empty policy and enable the policy for all environments
$NewDLPPolicy = New-DlpPolicy -DisplayName $DLPPolicyName -EnvironmentType "AllEnvironments"

# Prepare the blocked connectors 
$BlockedFacebookConnector = [pscustomobject]@{
        id =  $DLPFacebookConnector.id
        name = $DLPFacebookConnector.name
        type = $DLPFacebookConnector.type
    }

$BlockedConnectors = @()
$BlockedConnectors += $BlockedFacebookConnector 
$BlockedConnectorsGroup = [pscustomobject]@{
        classification = "Blocked"
        connectors = $BlockedConnectors
    }

# Prepare the business connectors 
$ConfSharePointConnector = [pscustomobject]@{
        id =  $DLPSharePointConnector.id
        name = $DLPSharePointConnector.name
        type = $DLPSharePointConnector.type
    }
	
$ConfOneDriveConnector = [pscustomobject]@{
        id =  $DLPOneDriveConnector.id
        name = $DLPOneDriveConnector.name
        type = $DLPOneDriveConnector.type
    }
	
$ConfOutlookConnector = [pscustomobject]@{
        id =  $DLPO365OutlookConnector.id
        name = $DLPO365OutlookConnector.name
        type = $DLPO365OutlookConnector.type
    }
	
$ConfConnectors = @()
$ConfConnectors += $ConfSharePointConnector
$ConfConnectors += $ConfOneDriveConnector
$ConfConnectors += $ConfOutlookConnector
$ConfConnectorsGroup = [pscustomobject]@{
        classification = "Confidential"
        connectors = $ConfConnectors
    }

# Prepare the non-business connectors (in my scenario the policy should include no non-business connectors)	
$GeneralConnectors = @()
$GeneralConnectorsGroup = [pscustomobject]@{
        classification = "General"
        connectors = $GeneralConnectors
    }

# Combine all connector configurations
$AllConnectorGroups = @()
$AllConnectorGroups += $BlockedConnectorsGroup
$AllConnectorGroups += $ConfConnectorsGroup
$AllConnectorGroups += $GeneralConnectorsGroup


# Add the connector configuration to the new DLP policy
$NewDLPPolicy.connectorGroups = $AllConnectorGroups
$NewDLPPolicy = Set-DlpPolicy -PolicyName $NewDLPPolicy.name -UpdatedPolicy $NewDLPPolicy

