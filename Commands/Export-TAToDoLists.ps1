
<#  
    .SYNOPSIS  
    The command creates a summary about Microsoft To-Do lists for all accounts in the tenant with a To-Do service plan.
    By default, the command evaluates for all user accounts with To-Do service plan whether they use shared lists and if they are the owners of the list. Alternatively, the evaluation of all lists is possible.  

    .DESCRIPTION
    Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Export-TAToDoLists.md.

#> 


function Export-TAToDoLists
{  param( [switch]$IncludePersonalLists,
          [switch]$IncludeSystemLists,
          [string]$UPN
    ) 

    if($UPN -eq "" )
    { $Url = "https://graph.microsoft.com/v1.0/users?`$count=true&`$filter=assignedPlans/any(x:x/service eq 'To-Do')" 
      $AllUsers = Invoke-MgGraphRequest -Method get $Url -Headers @{"ConsistencyLevel" = "eventual"}
      $AllUsers = $AllUsers.value
    }
    else 
    {   $Url = "https://graph.microsoft.com/v1.0/users/$UPN"
        $AllUsers = @(Invoke-MgGraphRequest -Method get $Url )
    }  

    $ToDoListInformation = @()
    $UserCount = 1
    foreach( $User in $AllUsers )
    {
        Write-host ("$UserCount of " + $AllUsers.Count + " - " + $User.userPrincipalName) -f Yellow
        
        $UserID = $User.id      
        $Url = "https://graph.microsoft.com/v1.0/users/$UserID/todo/lists`?$top=100" # For accounts with a high amount of To-Do lists. To Graph API has still issues to send more than 100 lists > https://github.com/microsoftgraph/microsoft-graph-docs/issues/15112.
        Try{ $Results = Invoke-MgGraphRequest -Method get $Url -ContentType "application/json;charset=utf-8"; $ToDoInUse = $true } 
        catch { Write-Host "Unable to receive To-Do lists (Probably the account never used Microsoft To-Do)." ; $ToDoInUse = $false }

        if( $ToDoInUse -eq $true )
        {  
            $AllUserLists = $Results.value 
            while ($Results.'@odata.nextLink' -ne $null )
            {   $Results =  Invoke-MgGraphRequest -Method get $Results.'@odata.nextLink' -ContentType "application/json;charset=utf-8"
                $AllUserLists += $Results.value
            }       

            $SystemLists = $AllUserLists | ?{ $_.wellknownListName -ne "none" }
            $PersonalLists = $AllUserLists | ?{ $_.isShared -eq $false -and $_.wellknownListName -eq "none" }
            $SharedLists = $AllUserLists | ?{ $_.isShared -eq $true }

            $AllExportLists = @()
            $AllExportLists += $SharedLists
            
            if( $IncludePersonalLists -eq $true )
            { $AllExportLists += $PersonalLists }

            if( $IncludeSystemLists -eq $true )
            { $AllExportLists += $SystemLists }

            if( $AllExportLists.Count -eq 0 )
            { Write-Host ("No lists for the account " + $User.userPrincipalName); Start-Sleep -Seconds 1 } 
            else 
            {
                foreach($List in $AllExportLists )
                {   Write-Host ("   To-Do list: " + $List.displayName)

                    $ToDoListObj = New-Object -TypeName PSObject
                    $ToDoListObj | Add-Member -MemberType NoteProperty -Name UserPrincipalName -Value $User.userPrincipalName
                    $ToDoListObj | Add-Member -MemberType NoteProperty -Name UserID -Value $User.id
                    $ToDoListObj | Add-Member -MemberType NoteProperty -Name Listname -Value $List.displayName

                    if( $List.isShared -eq $true )
                    { $ToDoListObj | Add-Member -MemberType NoteProperty -Name ListType -Value "Shared" } 
                    elseif( $List.wellknownListName -ne "none" )
                    { $ToDoListObj | Add-Member -MemberType NoteProperty -Name ListType -Value "System" } 
                    else 
                    { $ToDoListObj | Add-Member -MemberType NoteProperty -Name ListType -Value "Personal" } 


                    $ToDoListObj | Add-Member -MemberType NoteProperty -Name ListID -Value $List.id
                    $ToDoListObj | Add-Member -MemberType NoteProperty -Name isOwner -Value $List.isOwner
                    $ToDoListObj | Add-Member -MemberType NoteProperty -Name isShared -Value $List.isShared

                    # For accounts with a high amount of To-Do lists. To Graph API has still issues to send more than 100 lists > https://github.com/microsoftgraph/microsoft-graph-docs/issues/15112. 
                    if( $AllUserLists.Count -ge 100 )
                    { $ToDoListObj | Add-Member -MemberType NoteProperty -Name "100+Lists" -Value $true } else 
                    { $ToDoListObj | Add-Member -MemberType NoteProperty -Name "100+Lists" -Value $false }          


                    $ToDoListInformation += $ToDoListObj
                }
            }
        } else 
        { Start-Sleep -Seconds 1 }
        $UserCount++

    }
    
    if( $ToDoListInformation.Count -gt 0 )
    {
        $Date = get-date -format "dd-MM-yyyy"
        $ExportPath = ([Environment]::GetFolderPath("MyDocuments") +  "\ToDoListExport-$Date.csv")
        $ToDoListInformation | Export-Csv -Path $ExportPath -NoTypeInformation -Force -Encoding utf8
        Write-Host "Exported: $ExportPath"
    } 
    else 
    { Write-Host "No Microsoft To-Do lists to export." -f Green }
    Write-Host ""

}
