<#
.SYNOPSIS
    Creates Exchange Online migration batch for users listed in a CSV file

.DESCRIPTION
    This imports a list of users from a CSV file. It uses this information to create a new migration batch within Exchange Online.
    The import CSV contains email address, bad item limit, large item limit, and mailbox type.

.PARAMETER ImportFileName
    Specify the input path and filename for the file containing user account information. Example: C:\Imports\MigBatchUsers.csv

.PARAMETER MigrationBatchName
    Specify a unique name for the migration batch. Example: "MigBatch13071019_MoveToO365"

.PARAMETER NotifyAddress
    Specify the notification address for migration batch reports. Example: "Notifications@somedomain.com"

.PARAMETER CompleteBatch
    Specify if batch is to automatically complete. This is a switch, if present the batch automatically completes.

.NOTES
    Version:        1.0
    Author:         John O'Neill Sr.
    Creation Date:  10/07/2019
    Change Date:    
    Purpose/Change:

.EXAMPLE
    .\New-O365Migration.ps1 -ImportFileName 'C:\Imports\ImportFile.csv' -CompleteBatch

#>

[CmdletBinding()]

Param
(
# Specify the input path for the csv file
[Parameter(Mandatory=$true,HelpMessage='Specify the input path for the file containing user mailbox information. Example: "C:\Imports\MigBatchUsers.csv"')]
[String]$ImportFileName = 'C:\Imports\MigBatchUsers.csv',

# Specify Migration Batch Name
[Parameter(Mandatory=$false,HelpMessage='Specify a unique name for the migration batch. Example: "MigBatch13071019_MoveToO365"')]
[String]$MigrationBatchName = "",

# Specify what email to send migration report
[Parameter(Mandatory=$false,HelpMessage='Specify the notification address for migration batch reports. Example: "Notifications@somedomain.com"')]
[String]$NotifyAddress = 'Notifications@somedomain.com',

# Specify if batch is to automatically complete
[Parameter(Mandatory=$false)]
[Switch]$CompleteBatch
)

# Migration batch name not manually specified, so generate name
If ($MigrationBatchName -eq "") {
    $DateCode = Get-Date -UFormat "%S_%m%d%y"
    $MigrationBatchName = "MigBatch$DateCode"+"_MoveToO365"
}

function New-Batch {
    # Get migration endpoint from Exchange Online
    $MigrationEndpointOnprem = Get-MigrationEndpoint -Identity Server_OnPrem2016

    If ($CompleteBatch -eq $True) {
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

New-Batch
