
<#  
    .SYNOPSIS  
    The command evaluates all wikis in Teams via Microsoft Graph and summarizes it in a CSV file. You can prepare the file and send it to the owners of the teams. 
    For details read https://support.microsoft.com/en-us/office/export-a-wiki-to-a-onenote-notebook-8cd8ab0c-2314-42b0-a1d0-5c6c4c5e1547.     

    .DESCRIPTION
    Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Export-TATeamsWikiInformation.md.

#> 

function Export-TATeamsWikiInformation
{   param(  [switch]$ExcludeMigratedWikis,
            [switch]$ExcludeWikisWithNoContent
    ) 

    if( (Get-Module Microsoft.Graph.Authentication -ListAvailable).Count -eq 0 )
    { Write-Host "PowerShell Module Microsoft.Graph.Authentication is required." -f Red; break }   

    Import-Module Microsoft.Graph.Authentication
    Connect-MgGraph -Scopes Channel.ReadBasic.All, Team.ReadBasic.All, TeamMember.Read.All, TeamsTab.Read.All  | Out-Null

    if( (get-mgContext).ClientId -ne $null )
    {
        $GraphBetaUrl = "https://graph.microsoft.com/beta"        
        $Url = "$GraphBetaUrl/teams"
        $Results = Invoke-MgGraphRequest -Method get $Url        
        
        # Receive all Teams (Graph paging)
        $AllTeams = $Results.value
        while ($Results.'@odata.nextLink' -ne $null )
        {   $Results =  Invoke-MgGraphRequest -Method get $Results.'@odata.nextLink' -ContentType "application/json;charset=utf-8"
            $AllTeams += $Results.value
        }       

        $TeamsWikiInformation = @()
        $Count = 1
        foreach ( $Team in $AllTeams )
        {
            Write-Host ("$Count of " + $AllTeams.Count + " - Team: " + $Team.displayName) -f Yellow
            $TeamID = $Team.id

            $Url = "$GraphBetaUrl/teams/$TeamID/members?`$filter=roles/any(r:r eq 'owner')"
            $AllTeamOwners = Invoke-MgGraphRequest -Method get $Url -ContentType "application/json;charset=utf-8"

            $Url = "$GraphBetaUrl/teams/$TeamID/allChannels"
            $AllTeamChannels = Invoke-MgGraphRequest -Method get $Url -ContentType "application/json;charset=utf-8"            

            foreach( $Channel in $AllTeamChannels.Value )
            {
                Write-Host ("  Channel: " + $Channel.displayName)
                $ChannelID = $Channel.id
                $GraphTabsUrl = "$GraphBetaUrl/teams/$TeamID/channels/$ChannelID/tabs?`$expand=teamsApp"

                # In random cases the tabs API has an response error (400 Bad Request). It's a random issue, the next call works. 
                do{
                    $Failed = $false
                    Try{ $AllChannelTabs = Invoke-MgGraphRequest -Method get $GraphTabsUrl  -ContentType "application/json;charset=utf-8" } 
                    catch { Write-Host ("  API response error, retrying: " + $Channel.displayName) -f Red; $Failed = $true }
                } while ($Failed)

                $AllWikiTabs = @($AllChannelTabs.value | ?{$_.configuration.scenarioName -eq "wiki_init_context" -or $_.teamsapp.id -eq "com.microsoft.teamspace.tab.wiki" })               

                if( $AllWikiTabs.Count -gt 0 )
                {
                    foreach( $WikiTab in $AllWikiTabs )
                    {   
                        if( $ExcludeMigratedWikis -eq $false -and $WikiTab.configuration.hasMigratedToOneNote -eq $true -or $WikiTab.configuration.hasMigratedToOneNote -eq $null )
                        {
                            $TeamsWikiObj = New-Object -TypeName PSObject
                            $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name TeamName -Value $Team.displayName
                            $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name TeamID -Value $TeamID
                            $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name TeamOwners -Value ($AllTeamOwners.Value.email -join ", ")
                            $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name ChannelName -Value $Channel.displayName
                            $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name ChannelType -Value $Channel.membershipType  
                            $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name ChannelID -Value $ChannelID                  
                            $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name WikiName -Value $WikiTab.displayName
                            $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name WikiTabID -Value $WikiTab.id
                            
                            # Note: New Wikis include a creation date, older Wikis include no creation date 
                            if( $WikiTab.configuration.dateAdded -ne $null )
                            {  $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name WikiCreated -Value (Get-date $WikiTab.configuration.dateAdded -Format d) } 
                            else 
                            { $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name WikiCreated -Value $null }

                            $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name WikiHasContent -Value $WikiTab.configuration.hasContent
                            if( $WikiTab.configuration.hasMigratedToOneNote -eq $null )
                            {  $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name WikiMigratedToOneNote -Value $False }
                            else 
                            { $TeamsWikiObj | Add-Member -MemberType NoteProperty -Name WikiMigratedToOneNote -Value $WikiTab.configuration.hasMigratedToOneNote  }  
                     
                            if( $ExcludeWikisWithNoContent -eq $false -or $WikiTab.configuration.hasContent -eq $true )
                            { $TeamsWikiInformation += $TeamsWikiObj }

                        }
                    }
                }
            }
            $Count++              
        }

        $Date = get-date -format "dd-MM-yyyy"
        $ExportPath = ([Environment]::GetFolderPath("MyDocuments") +  "\TeamsWikiExport-$Date.csv")
        $TeamsWikiInformation | Export-Csv -Path $ExportPath -NoTypeInformation -Force -Encoding utf8
        $ExportPath
        
    }

    Disconnect-Graph | Out-Null
    Remove-Module Microsoft.Graph.Authentication
}

