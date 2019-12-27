# New-O365Migration
Performs functions for creating and managing Exchange Online migration batches

When used to create a new migration batch, this script imports a list of users from a CSV file.
The import CSV contains email address, bad item limit, large item limit, and mailbox type.

Supported parameters:
ImportFileName
    Specify the input path and filename for the file containing user account information. Example: C:\Imports\MigBatchUsers.csv
    CSV must conform to guidelines here: https://docs.microsoft.com/en-us/exchange/csv-files-for-mailbox-migration-exchange-2013-help

MigrationBatchName
    Specify a unique name for the migration batch. Example: "MigBatch13071019_MoveToO365"

WaveNumber
    Specify the Wave Number of the migration batch. Prefixed to system generated Migration Batch Name.

NotifyAddress
    Specify the notification address for migration batch reports. Example: "Notifications@somedomain.com"

AutoComplete
    Specify if batch is to automatically complete. This is a switch, if present the batch automatically completes.

CompleteBatch
    This is a switch, if present a previously synced batch's completion phase is started.

GetBatchStatus
    This is a switch, if present returns information for in-process batches.

GetBatchStatusSummary
    This is a switch, if present returns summary information for in-process batches.

GetBatchStatusDetails
    This is a switch, if present returns detailed information about a specified migration batch.

GetBatchList
    This is a switch, if present returns batch information including just the batch name and current status
