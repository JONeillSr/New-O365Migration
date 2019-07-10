# New-O365Migration
PowerShell script creating Exchange Online migration batch for users listed in a CSV file. Scripts supports parameters to control batch performance.

This imports a list of users from a CSV file. It uses this information to create a new migration batch within Exchange Online. The import CSV contains email address, bad item limit, large item limit, and mailbox type.

Supported parameters:
ImportFileName - Specify the input path and filename for the file containing user account information. Example: C:\Imports\MigBatchUsers.csv

MigrationBatchName - Specify a unique name for the migration batch. Example: "MigBatch13071019_MoveToO365"

NotifyAddress - Specify the notification address for migration batch reports. Example: "Notifications@somedomain.com"

CompleteBatch - Specify if batch is to automatically complete. This is a switch, if present the batch automatically completes.
