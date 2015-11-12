############## C O N F I G ##############
."C:\AWS\AWSConfig.ps1"

############## F U N C T I O N S ##############
."C:\AWS\AWSUtilities.ps1"

#Environment
$ENVIRONMENT_NAME = "Prod"
$ENVIRONMENT_TYPE = "AWS"
$BACKUP_TYPE = "Daily"
$backupTag = "Backup" #Make sure the value of this Tag is 'Yes', without the quotes, on the instances you want backed up

############## M A I N ##############

try
{
    $start = Get-Date
    WriteToLog "EnvName=$ENVIRONMENT_NAME EnvType=$ENVIRONMENT_TYPE BackupType=$BACKUP_TYPE StatusMsg='Backup Starting'" -excludeTimeStamp $true
    
    $stagingInstanceIDs= GetBackedUpInstances $backupTag

    CreateSnapshotsForInstances $stagingInstanceIDs

    CleanupDailySnapshots

    WriteToLog "EnvName=$ENVIRONMENT_NAME EnvType=$ENVIRONMENT_TYPE BackupType=$BACKUP_TYPE StatusMsg='Backup Complete'" -excludeTimeStamp $true   
    
    $end = Get-Date
    $timespan = New-TimeSpan $start $end
    $hours=$timespan.Hours
    $minutes=$timespan.Minutes    
    WriteToLog "Backup took $hours hour(s) and $minutes minute(s)"
    
}
catch
{
    WriteToLog -successString "FAILED"
}
