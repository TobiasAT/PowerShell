
<#  
    .SYNOPSIS  
    Instead to force a OneDrive reset this command disconnects a single folder from your OneDrive Sync Client, or removes orphaned configurations to reconnect the synchronized folder again.

    .DESCRIPTION
    Documentation in my PowerShell repository at https://github.com/TobiasAT/PowerShell/blob/main/Documentation/Disconnect-TAOneDriveSyncedFolder.md.

#> 

function Disconnect-TAOneDriveSyncedFolder
{ param ( [Parameter(Mandatory)][string]$Foldername )     

    # Find the necessary registry path for the synchronization folder
    $HKCURegItem = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business*\ScopeIdToMountPointPathCache" | ?{$_ -like "*$Foldername*" }

    if( $HKCURegItem.Count -eq 0 )
    { Write-Host "Folder is not synchronized: $Foldername" -ForegroundColor Red }
    else 
    {
        $HKCURegItemParent = Get-item -Path $HKCURegItem.PSParentPath
        $HKCURegItem = Get-item -Path $HKCURegItem.PSPath

        $LocalLibraryID = $null
        $LocalDirectory = $null
        foreach( $Property in $HKCURegItem.Property )
        { 
            $LocalDirectory = Get-ItemPropertyValue -Path $HKCURegItem.PSPath -Name $Property

            if( $LocalDirectory -like "*$Foldername" )
            {   # A random ID to match the synchronization folder, also part of the synchronization configuration file
                $LocalLibraryID = $Property
                break
            }
        }


        $LocalOneDriveBusinessFolderName =  $HKCURegItemParent.Name.Substring($HKCURegItemParent.Name.LastIndexOf("\") + 1 ) # Different sync instances if more than one tenant is in sync
        $TenantName = Get-ItemPropertyValue -Path $HKCURegItemParent.PSPath -Name "DisplayName" # Tenant name is required for a registry path
        $INIGuid = Get-ItemPropertyValue -Path $HKCURegItemParent.PSPath -Name "cid" # The Guid for the synchronization configuration file

        $OneDriveProc = Get-Process -name OneDrive -ErrorAction Ignore
        
        # Closing all OneDrive Client instances
        if ($OneDriveProc.Count -gt 0) 
        {   $OneDriveRunPath = $OneDriveProc[0].Path
            Write-Host "Closing OneDrive Sync Client..."
            Stop-Process -Name OneDrive
            Start-Sleep -Seconds 5
        } 
        else 
        {   # In case the OneDrive Sync Client is not running, using the OneDrive directory from the registry
            $OneDriveRunPath = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\OneDrive" -Name "OneDriveTrigger"
        }


        $UserSID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
        $RegSID = ("OneDrive!$UserSID!$LocalOneDriveBusinessFolderName|$LocalLibraryID")

        Get-ItemProperty -Path $HKCURegItem.PSPath -Name $LocalLibraryID | Remove-ItemProperty -Name $LocalLibraryID
        Write-Host ("  Item removed: " + (Get-Item -LiteralPath  $HKCURegItem.PSPath).Name + "\$LocalLibraryID") 

        Get-Item -Path "HKCU:\SOFTWARE\SyncEngines\Providers\OneDrive\$LocalLibraryID" | Remove-Item
        Write-Host "  Item removed: HKCU:\SOFTWARE\SyncEngines\Providers\OneDrive\$LocalLibraryID"


        Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager\$RegSID" | Remove-Item -Recurse
        Write-Host "  Item removed: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SyncRootManager\$RegSID"

        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null

        Get-Item -Path "HKU:\$UserSID\SOFTWARE\Microsoft\OneDrive\Accounts\$LocalOneDriveBusinessFolderName\ScopeIdToMountPointPathCache" | Remove-ItemProperty -Name $LocalLibraryID -ErrorAction Ignore
        Write-Host "  Item removed: HKU:\$UserSID\SOFTWARE\Microsoft\OneDrive\Accounts\$LocalOneDriveBusinessFolderName\ScopeIdToMountPointPathCache\$LocalLibraryID"


        Get-Item -Path "HKU:\$UserSID\SOFTWARE\Microsoft\OneDrive\Accounts\$LocalOneDriveBusinessFolderName\Tenants\$TenantName" | Remove-ItemProperty -Name $LocalDirectory -ErrorAction Ignore
        Write-Host "  Item removed: HKU:\$UserSID\SOFTWARE\Microsoft\OneDrive\Accounts\$LocalOneDriveBusinessFolderName\Tenants\$TenantName\$LocalDirectory"
        
        Get-Item -Path "HKU:\$UserSID\SOFTWARE\SyncEngines\Providers\OneDrive\$LocalLibraryID" -ErrorAction Ignore | Remove-Item -ErrorAction Ignore
        Write-Host "  Item removed: HKU:\$UserSID\SOFTWARE\SyncEngines\Providers\OneDrive\$LocalLibraryID"


        $ConfigINIFilePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\settings\$LocalOneDriveBusinessFolderName\$INIGuid.ini"

        if(Test-Path $ConfigINIFilePath)
        {   
            $DestinationPath = ("$ConfigINIFilePath.backup" + (Get-Date -format ddMMyyyy) )
            Copy-Item -Path $ConfigINIFilePath -Destination $DestinationPath -Force
            Write-Host "  Configuration backup file created: $DestinationPath"

            $INIContent = Get-Content -Path $ConfigINIFilePath -Encoding unicode
            $NewINIContent = $INIContent | ?{$_ -notlike "*$LocalLibraryID*" }
            Set-Content -Path $ConfigINIFilePath -Value $NewINIContent -Encoding unicode
            Write-Host "  Configuration file updated: $ConfigINIFilePath"
        }
        else 
        { Write-Host "Configuration file is not available (not updated): $ConfigINIFilePath" -ForegroundColor Red  }
        
        Write-Host "Starting OneDrive Sync Client..."
        Start-Sleep -Seconds 4
        Start-Process -FilePath $OneDriveRunPath        

    }
}
