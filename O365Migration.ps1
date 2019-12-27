<#
.SYNOPSIS
    Performs functions for creating and managing Exchange Online migration batches

.DESCRIPTION
    When used to create a new migration batch, this script imports a list of users from a CSV file.
    The import CSV contains email address, bad item limit, large item limit, and mailbox type.

.PARAMETER ImportFileName
    Specify the input path and filename for the file containing user account information. Example: C:\Imports\MigBatchUsers.csv
    CSV must conform to guidelines here: https://docs.microsoft.com/en-us/exchange/csv-files-for-mailbox-migration-exchange-2013-help

.PARAMETER MigrationBatchName
    Specify a unique name for the migration batch. Example: "MigBatch13071019_MoveToO365"

.PARAMETER WaveNumber
    Specify the Wave Number of the migration batch. Prefixed to system generated Migration Batch Name.

.PARAMETER NotifyAddress
    Specify the notification address for migration batch reports. Example: "Notifications@somedomain.com"

.PARAMETER AutoComplete
    Specify if batch is to automatically complete. This is a switch, if present the batch automatically completes.

.PARAMETER CompleteBatch
    This is a switch, if present a previously synced batch's completion phase is started.

.PARAMETER GetBatchStatus
    This is a switch, if present returns information for in-process batches.

.PARAMETER GetBatchStatusSummary
    This is a switch, if present returns summary information for in-process batches.

.PARAMETER GetBatchStatusDetails
    This is a switch, if present returns detailed information about a specified migration batch.

.PARAMETER GetBatchList
    This is a switch, if present returns batch information including just the batch name and current status

.NOTES
    Version:        1.4
    Author:         John O'Neill Sr.
    Creation Date:  10/07/2019
    Change Date:    29/08/2019  
    Purpose/Change: Add additional function.

    Version:        1.5
    Author:         John O'Neill Sr.
    Change Date:    05/09/2019  
    Purpose/Change: Added WaveNumber parameter.
                    Migration batch name creation code modified to include wave number.

    Version:        1.6
    Author:         John O'Neill Sr.
    Change Date:    29/10/2019  
    Purpose/Change: Added GetBatchStatusSummary function.
                    Create parameter and related function to return only identity and status of batches.

.EXAMPLE
    .\O365Migration.ps1 -NewMigrationBatch -WaveNumber 20 -ImportFileName 'C:\Imports\ImportFile.csv' -CompleteBatch

#>

# Provide access to the common parameters
[CmdletBinding()]

Param
(
# Specify if creating new migration batch
[Parameter(Mandatory=$false,ParameterSetName='NewMigrationBatch')]
[Switch]$NewMigrationBatch,

# Specify the input path for the csv file
[Parameter(Mandatory=$true,ParameterSetName='NewMigrationBatch',HelpMessage='Specify the input path for the file containing user mailbox information. Example: "C:\Imports\MigBatchUsers.csv"')]
[String]$ImportFileName = 'C:\Imports\MigBatchUsers.csv',

# Specify if batch automatically completes
[Parameter(Mandatory=$false,ParameterSetName='NewMigrationBatch')]
[Switch]$AutoComplete,

# Specify Wave Number of migration batch
[Parameter(Mandatory=$false,ParameterSetName='NewMigrationBatch')]
[Int]$Wave = 0,

# Specify migration batch name
[Parameter(Mandatory=$false,HelpMessage='Specify the name for the migration batch. Example: "MigBatch13071019_MoveToO365"')]
[String]$MigrationBatchName = "",

# Specify if completing previously synced batch
[Parameter(Mandatory=$false,ParameterSetName='CompleteMigrationBatch')]
[Switch]$CompleteBatch,

# Specify what email to send migration report
[Parameter(Mandatory=$false,HelpMessage='Specify the notification address for migration batch reports. Example: "Notifications@somedomain.com"')]
[String]$NotifyAddress = 'notavalidaddress@somedomain.com',

# Specify if the desire is only to get running batch information
[Parameter(Mandatory=$false, ParameterSetName='GetBatchStatus')]
[Switch]$GetBatchStatus,

# Specify if the desire is only to get running batch information
[Parameter(Mandatory=$false, ParameterSetName='GetBatchStatusSummary')]
[Switch]$GetBatchStatusSummary,

# Specify if the desire is only to get running batch information
[Parameter(Mandatory=$false, ParameterSetName='GetBatchStatusDetails')]
[Switch]$GetBatchStatusDetails,

# Specify if the desire is only to get a name and status for batches
[Parameter(Mandatory=$false, ParameterSetName='GetBatchList')]
[Switch]$GetBatchList

)

# $ErrorActionPreference = "SilentlyContinue"

function New-Batch {
    # Create a new Echange Online migration batch
    
    # Get migration endpoint from Exchange Online
    $MigrationEndpointOnprem = Get-MigrationEndpoint -Identity Alias_OnPrem2016

    # Migration batch name wasn't specified, generate name
    If ($MigrationBatchName -eq "") {
        $DateCode = Get-Date -UFormat "%S_%m%d%y"
        If ($WaveNumber -ne 0){
            $MigrationBatchName = "$Wave"+"_MigBatch$DateCode"+"_MoveToO365"
        } else {
            $MigrationBatchName = "MigBatch$DateCode"+"_MoveToO365"
        }
    }

    If ($AutoComplete -eq $True) {
        New-MigrationBatch -Name $MigrationBatchName -SourceEndpoint $MigrationEndpointOnprem.Identity -TargetDeliveryDomain moldedfiberglass.mail.onmicrosoft.com -NotificationEmails $NotifyAddress -AutoComplete -CSVData ([System.IO.File]::ReadAllBytes($ImportFileName))
        Write-Host "Created migration batch $MigrationBatchName. System will begin Completion phase automatically."
    } Else {
        New-MigrationBatch -Name $MigrationBatchName -SourceEndpoint $MigrationEndpointOnprem.Identity -TargetDeliveryDomain moldedfiberglass.mail.onmicrosoft.com -NotificationEmails $NotifyAddress -CSVData ([System.IO.File]::ReadAllBytes($ImportFileName))
        Write-Host "Created migration batch $MigrationBatchName. System will NOT begin Completion phase automatically."
    }

    try {
        Start-MigrationBatch -Identity $MigrationBatchName
        Write-Host "Migration batch $MigrationBatchName started successfully."
    }
    catch {
        Write-Host "Migration batch $MigrationBatchName could not be started."
        Write-Error
    }
}

function Get-BatchStatus {
    # Display batch information including name and mailbox migration counts within a batch
    If ($MigrationBatchName -ne "") {
        # This includes information about the specified batch only
        Get-MigrationBatch -Identity $MigrationBatchName | Select-Object -Property Identity,Status, ActiveCount, FailedCount, FinalizedCount, PendingCount, ProvisionedCount, StoppedCount, SyncedCount, TotalCount | Format-List
    } else {
        # This includes all in-process batches i.e. status is syncing, synced, or completing
        Get-MigrationBatch | Where-Object {$_.Status -like 'sync*' -or $_.Status -like 'Completing'} | Select-Object -Property Identity,Status, ActiveCount, FailedCount, FinalizedCount, PendingCount, ProvisionedCount, StoppedCount, SyncedCount, TotalCount | Format-List
    }
}
function Get-BatchStatusSummary {
    # Display batch name and status only
    If ($MigrationBatchName -ne "") {
        # This includes information about a specified batch
        Get-MigrationBatch -Identity $MigrationBatchName | Select-Object -Property Identity,Status | Format-Table -AutoSize
    } else {
        # This includes information about all in-process batches i.e. status is syncing, synced, or completing
        Get-MigrationBatch | Where-Object {$_.Status -like 'sync*' -or $_.Status -like 'Completing'} | Select-Object -Property Identity,Status | Format-Table -AutoSize
    }
}
function Get-BatchStatusDetails {
    # Display batch information for each user within a batch
    If ($MigrationBatchName -ne "") {
        # Get specified batch
        $batches = Get-MigrationBatch -Identity $MigrationBatchName
    } else {
        # Get all currently in-process batches
        $batches = Get-MigrationBatch | Where-Object {$_.Status -like 'sync*' -or $_.Status -like 'Completing'}
    }

    # Loop through each running batch retrieving key user statistics
    # Use PS Calculated Properties to add batch data into output
    # Use .NET formatting strings to spruce up output
    ForEach ($batch in $batches) {
        Get-MigrationUser -BatchID $batch.Identity.Name | Get-MigrationUserStatistics | Select-Object -Property @{Name="BatchName"; Expression={$batch.Identity.Name}}, @{Name="BatchStatus"; Expression={$batch.status}}, Identity, Status, @{Name="EstimatedItemsInSourceMailbox"; Expression={ "{0:N0}" -f ($_.TotalItemsInSourceMailboxCount)}}, @{Name="SyncedItems"; Expression={ "{0:N0}" -f ($_.SyncedItemCount)}}, EstimatedTotalTransferSize, BytesTransferred, Error | format-list
 }
}

function Start-Completion {
    # Begin completion phase of previously synced batch
    # Batch name must be specified on command-line
    If ($MigrationBatchName -ne "") {
        Complete-MigrationBatch -Identity $MigrationBatchName -Confirm:$false
        Write-Host "Migration batch $MigrationBatchName completion phase started."
        
    } else {
        Write-Host "Migration batch name required."
    }
}

function Get-BatchList {
    # Retrieve list of in-process batches without other details
    If ($MigrationBatchName -ne "") {
        # This includes information about the specified batch only
        Get-MigrationBatch -Identity $MigrationBatchName | Select-Object -Property Identity, Status | Format-Table
    } else {
        # This includes all in-process batches i.e. status is syncing, synced, or completing
        Get-MigrationBatch | Where-Object {$_.Status -like 'sync*' -or $_.Status -like 'Completing'} | Select-Object -Property Identity, Status | Format-Table
    }
}

Function Set-UpdateEmailAddressPolicyEnabled {
    $MBox = Get-Mailbox $MboxOwnerName
    If ($Mbox.EmailAddressPolicyEnabled) {
        write-host "EmailAddressPolicyEnabled already selected"
    } else {
        Set-Mailbox $Mbox.Name -EmailAddressPolicyEnabled $true
        write-host "EmailAddressPolicyEnabled selected"
    }
}

If ($GetBatchStatus -eq $True) {
    Get-BatchStatus

} elseif ($CompleteBatch -eq $True) {
    Start-Completion

} elseif ($GetBatchStatusSummary -eq $True) {
    Get-BatchStatusSummary

} elseif ($GetBatchStatusDetails -eq $True) {
    Get-BatchStatusDetails

} elseif ($NewMigrationBatch -eq $True) {
    New-Batch

} elseif ($GetBatchList -eq $True) {
    Get-BatchList
}
