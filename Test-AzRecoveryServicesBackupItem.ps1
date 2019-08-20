$ErrorActionPreference = "stop"

Function Out-Log
{
    param(
    [string]$message,
    [string]$Color = 'White'
    )

    Write-Host "$message" -ForegroundColor $Color
}

$results = @{}

$vaults = Get-AzRecoveryServicesVault
$vaults | ForEach-Object {

    $vault = $_
    $ItemsPerVault = New-Object System.Collections.ArrayList

    $containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -VaultId $vault.ID 
    $containers | ForEach-Object {
    
        $container = $_
        $items = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vault.ID
        $items | ForEach-Object {
            $item = [ordered]@{}
            $item.Name = ($_.Name -split ";")[3]
            $item.ProtectionState = $_.ProtectionState.ToString()
            $item.LastBackupStatus = $_.LastBackupStatus.ToString()
            $item.LastBackupTime = ($_.LastBackupTime).ToString('yyyy/MM/dd hh:mm:ss')
            $ItemsPerVault.add($item) | Out-Null
        }
    }
    $results.add($vault.Name,$ItemsPerVault)
}

$results.Keys | ForEach-Object {
    $vaultName = $_
    Out-Log -message "Validate $vaultName" -Color "white"

    $results[$vaultName] | ForEach-Object {
        $lastBackupStatus = ""
        if ($_.LastBackupStatus -eq ""){
            $lastBackupStatus = "Nothing"
        } else {
            $lastBackupStatus = $_.LastBackupStatus
        }
        $msg = " - $($_.Name) is $($_.ProtectionState). Last backup is $($lastBackupStatus) $($_.LastBackupTime)"

        [DateTime]$_.LastBackupTime -gt $now.AddDays(-7)

        if ($lastBackupStatus -eq "Complete" -or [DateTime]$_.LastBackupTime -gt $now.AddDays(-7) ){
            Out-Log -message $msg -Color "Green"
        } else {
            Out-Log -message $msg -Color "Red"            
        }
    }
}


