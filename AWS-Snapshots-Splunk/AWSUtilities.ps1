############## R E A D M E ##############
#--Variables in ALL CAPS live in AWSConfig.ps1

#Run next line only once; is is required to create source for Windows Event Log
#New-EventLog -Source "AWS PowerShell Utilities" -LogName "Application"


############## G L O B A L ##############


############## U T I L I T Y   F U N C T I O N S ##############

#Description: Returns true if function has been running longer than permitted 
#Returns: bool
function IsTimedOut([datetime] $start, [string] $functionName)
{    
    
    $current = new-timespan $start (get-date)
    
    If($current.Minutes -ge $MAX_FUNCTION_RUNTIME)
    {
        WriteToLog "ErrorMessage='$FunctionName has taken longer than $MAX_FUNCTION_RUNTIME min. Aborting!'"
        throw new-object System.Exception "$FunctionName has taken longer than $MAX_FUNCTION_RUNTIME min. Aborting!"
        return $true
    } 
    return $false
}
#Description: Adds a tag to an Amazon Web Services Resource
#Returns: n/a
function AddTagToResource([string] $resourceID, [string] $key, [string] $value)
{   
    try
    {
        $tag = new-object amazon.EC2.Model.Tag
        $tag.Key=$key
        $tag.Value=$value
        
        $createTagsRequest = new-object amazon.EC2.Model.CreateTagsRequest
        $createTagsRequest.Resources = $resourceID
        $createTagsRequest.Tags = $tag
        $createTagsResponse = $EC2_CLIENT.CreateTags($createTagsRequest)
        $createTagsResult = $createTagsResponse.CreateTagsResult; 
    }
    catch [Exception]
    {
        $function = "AddTagToResource"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
    }
}
#Description: Add carriage return characters for formatting purposes
#Returns: string[]
function FixNewLines([string[]] $text)
{    
    $returnText=""
    try
    {
        for($i=0;$i -le $text.Length;$i++)
        {
            $returnText+=$text[$i]+"`r`n"
        }
    }
    catch [Exception]
    {
        $function = "FixNewLines"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
    }

    return $returnText
       
}
#Description: Returns the current log name by determining the timestamp for the first day of the current week
#Returns: string
function GetLogDate
{
    $dayOfWeek = (get-date).DayOfWeek
    switch($dayOfWeek)
    {
        "Sunday" {$dayOfWeekNumber=0}
        "Monday" {$dayOfWeekNumber=1}
        "Tuesday" {$dayOfWeekNumber=2}
        "Wednesday" {$dayOfWeekNumber=3}
        "Thursday" {$dayOfWeekNumber=4}
        "Friday" {$dayOfWeekNumber=5}
        "Saturday" {$dayOfWeekNumber=6}
    }
    if($dayOfWeekNumber -eq 0)
    {
        $logDate = get-date -f yyyyMMdd
    }
    else
    {
        $logDate = get-date ((get-date).AddDays($dayOfWeekNumber * -1)) -f yyyyMMdd
    } 
    return  $logDate 
}

#Description: Writes a message to a log file, console
#Returns: n/a
function WriteToLog([string[]] $text, [bool] $isException = $false)
{    
    try
    {
        if((Test-Path $LOG_PATH) -eq $false)
        {
            [IO.Directory]::CreateDirectory($LOG_PATH) 
        }
        $date = GetLogDate
        $logFilePath = $LOG_PATH + $date + ".txt"
        $currentDatetime = get-date -format G 
        add-content -Path $logFilePath -Value "$currentDatetime $text"
        write-host "$datetime $text"
        if($isException)
        {
            write-eventlog -Logname "Application" -EntryType "Information" -EventID "0" -Source "AWS PowerShell Utilities" -Message $($text)
        }
    }
    catch [Exception]
    {
        $function = "WriteToLog"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
    }    
}

############## I N S T A N C E   F U N C T I O N S ##############

#Description: Returns an Amazon Web Service Instance object for a given instance Id
#Returns: Instance
function GetInstance([string] $instanceID)
{
    try
    {
        $instancesRequest = new-object amazon.EC2.Model.DescribeInstancesRequest
        $instancesRequest.InstanceIds = $instanceID
        $instancesResponse = $EC2_CLIENT.DescribeInstances($instancesRequest)
        $instancesResult = $instancesResponse.Reservations
        return $instancesResult[0].Instances[0]
    }
    catch [Exception]
    {
        $function = "GetInstance"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }
}

#Description: Returns all Amazon Web Service Instance objects
#Returns: ArrayList<Instance>
function GetAllInstances()
{
    try
    {
        $instancesRequest = new-object amazon.EC2.Model.DescribeInstancesRequest
        $instancesResponse = $EC2_CLIENT.DescribeInstances($instancesRequest)
        $instancesResult = $instancesResponse.Reservations
        
         $allInstances = new-object System.Collections.ArrayList
        
        foreach($reservation in $instancesResult)
        {
            foreach($instance in $reservation.Instances)
            {
                $allInstances.Add($instance) | out-null
            }
        }
        
        return $allInstances
    }
    catch [Exception]
    {
        $function = "GetAllInstances"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }
}

#Description: Returns an ArrayList of all running Amazon Web Service Instance objects that are
#Returns: Instance
function GetRunningInstances()
{
    try
    {

        $allInstances = GetAllInstances
        $runningInstances = new-object System.Collections.ArrayList

        foreach($instance in $allInstances)
        {
            if($instance.State.Name -eq "running")
            {
                $runningInstances.Add($instance) | out-null
            }
        }
        
        return $runningInstances
    }
    catch [Exception]
    {
        $function = "GetRunningInstances"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }
}

#Description: Gets the status of an Amazon Web Service Instance object for a given instance Id
#Returns: string
function GetInstanceStatus([string] $instanceID)
{
    try
    {
        $instance = GetInstance $instanceID
        return $instance.State.Name
    }
    catch [Exception]
    {
        $function = "GetInstanceStatus"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }
}

#Description: Gets the name of an Amazon Web Service Instance object for a given instance Id
#Returns: string
function GetInstanceName([string] $instanceID)
{
    try
    {
        $name = ""
        $instance = GetInstance $instanceID
        foreach($tag in $instance.Tags)
        {
            if($tag.Key -eq "Name")
            {
                $name = $tag.Value
            }
        }
        return $name
    }
    catch [Exception]
    {
        $function = "GetInstanceName"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }
}

#Description: Starts an Amazon Web Service Instance object for a given instance Id
#Returns: n/a
function StartInstance([string] $instanceID)
{    
    try
    {
        $instanceStatus = GetInstanceStatus $instanceID
        $name = GetInstanceName $instanceID
        if($instanceStatus -eq "running")
        {   
            WriteToLog "InstanceName=$name InstanceID=$instanceID InstanceStatus=Started"
        }
        else
        {
            #Start instance    
            $startReq = new-object amazon.EC2.Model.StartInstancesRequest
            $startReq.InstanceIds.Add($instanceID);    

            WriteToLog "InstanceName=$name InstanceID=$instanceID InstanceStatus=Starting"    
            $startResponse = $EC2_CLIENT.StartInstances($startReq)
			$startResult = $startResponse
            
            #Wait for instance to finish starting. Unlike Stop instance,start one at a time (ex. DC, SQL, SP)
            $instancesRequest = new-object amazon.EC2.Model.DescribeInstancesRequest
            $instancesRequest.InstanceIds = $instanceID    
            
            $start = get-date
                       
            do{
                #abort if infinite loop or otherwise
                if(IsTimedOut $start) { break } 
                
                start-sleep -s 5
                $instancesResponse = $EC2_CLIENT.DescribeInstances($instancesRequest)
                $instancesResult = $instancesResponse.Reservations
            }
            while($instancesResult[0].Instances[0].State.Name -ne "running") 
            
            WriteToLog "InstanceName=$name InstanceID=$instanceID InstanceStatus=Started"  
        }
    }
    catch [Exception]
    {
        $function = "StartInstance"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
    }    
}

#Description: Starts one or more Amazon Web Service Instance object for a collection of instance Ids
#Returns: n/a
function StartInstances ([string[]] $instanceIDs)
{   
    try
    {
        $start = get-date
        
        foreach($instanceID in $instanceIDs)
        {
            StartInstance $instanceID            
        }
        
        $end = get-date
        $finish = new-timespan $start $end
        $finishMinutes = $finish.Minutes
        $finishSeconds = $finish.Seconds 
        WriteToLog "StatusMsg=Start Instances completed"  
		WriteToLog "FinishTime='${finishMinutes}:$finishSeconds'"
        
    }
    catch [Exception]
    {
        $function = "Start Instances"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
    }
    
}

#Description: Starts all Amazon Web Service Instances
#Returns: n/a
function StartAllInstances()
{
    try
    {
        $instances = GetRunningInstances
        foreach($instance in $instances)
        {
            if($STARTALL_EXCEPTIONS -notcontains $instance.InstanceID)
            {
                StopInstance($instance)
            }
        }
    }
    catch [Exception]
    {
        $function = "StopRunningInstances"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
    }
}

#Description: Stops an Amazon Web Service Instance object for a given instance Id
#Returns: bool - is instance already stopped?
function StopInstance([string] $instanceID)
{    
    try
    {
        $instanceStatus = GetInstanceStatus $instanceID
        $name = GetInstanceName $instanceID
        if($instanceStatus -eq "stopped")
        {   
            WriteToLog "InstanceName=$name InstanceID=$instanceID InstanceStatus=Stopped"
            WriteToLog "InstanceName=$name Status='Already stopped'"
            return $true
        }
        else
        {
            #Stop instance    
            $stopReq = new-object amazon.EC2.Model.StopInstancesRequest
            $stopReq.InstanceIds.Add($instanceID);
       
            WriteToLog "InstanceName=$name InstanceID=$instanceID InstanceStatus=Stopping"
            $stopResponse = $EC2_CLIENT.StopInstances($stopReq)
            $stopResult = $stopResponse.StopInstancesResult;  
            return $false      
        }
    }
    catch [Exception]
    {
        $function = "StopInstance"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }
}

#Description: Stops one or more Amazon Web Service Instance object for a collection of instance Ids
#Returns: n/a
function StopInstances([string[]] $instanceIDs)
{    
    try
    {    
        $statusInstanceIDs = new-object System.Collections.ArrayList($null)
        $statusInstanceIDs.AddRange($instanceIDs)
        
        #Stop all instances
        foreach($instanceID in $instanceIDs)
        {        
            if(StopInstance $instanceID)
            {
                $statusInstanceIDs.Remove($instanceID)
            }
        }
        #Wait for all instances to finish stopping
        $instancesRequest = new-object amazon.EC2.Model.DescribeInstancesRequest   
        
        $start = get-date        
        do
        {
            #abort if infinite loop or otherwise
            if(IsTimedOut $start) { break } 
                
            start-sleep -s 5
            foreach($instanceID in $statusInstanceIDs)
            {
                $status = GetInstanceStatus $instanceID
                if($status -eq "stopped")
                {
                    $name = GetInstanceName $instanceID
                    WriteToLog "InstanceName=$name InstanceID=$instanceID InstanceStatus=Stopped"
                    $statusInstanceIDs.Remove($instanceID)
                    break
                }
            }      
        }
        while($statusInstanceIDs.Count -ne 0)        
       
        $end = get-date
        $finish = new-timespan $start $end
        $finishMinutes = $finish.Minutes
        $finishSeconds = $finish.Seconds         
        WriteToLog "StatusMsg=Stop Instances completed" 
		WriteToLog "FinishTime=${finishMinutes}:$finishSeconds"
    }
    catch [Exception]
    {
        $function = "StopInstances"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
    }
}

#Description: Stops all Amazon Web Service Instances
#Returns: n/a
function StopAllInstances()
{
    try
    {
        [System.Collections.ArrayList]$instances = GetAllInstances
        foreach($instance in $instances)
        {
            if($STOPALL_EXCEPTIONS -notcontains $instance.InstanceID)
            {
                StopInstance($instance.InstanceID)
            }
        }
    }
    catch [Exception]
    {
        $function = "StopAllInstances"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
    }
}


############## S N A P S H O T   F U N C T I O N S ##############

#Description: Returns a Amazon Web Service Snapshot with a given snapshot Id
#Returns: Snapshot
function GetSnapshot([string] $snapshotID)
{
    try
    {
        $snapshotsRequest = new-object amazon.EC2.Model.DescribeSnapshotsRequest
        $snapshotsRequest.SnapshotIds = $snapshotID
        $snapshotsResponse = $EC2_CLIENT.DescribeSnapshots($snapshotsRequest)
		$snapshotsResult = $snapshotsResponse
        return $snapshotsResult.Snapshots[0]
    }
    catch [Exception]
    {
        $function = "GetSnapshot"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }
}

#Description: Returns all Amazon Web Service Snapshots
#Returns: Snapshot[]
function GetAllSnapshots
{
    try
    {
        $snapshotsRequest = new-object amazon.EC2.Model.DescribeSnapshotsRequest
        $snapshotsRequest.OwnerIds = $accountID
        $snapshotsResponse = $EC2_CLIENT.DescribeSnapshots($snapshotsRequest)
		$snapshotsResult = $snapshotsResponse
        return $snapshotsResult.Snapshots
    }
    catch [Exception]
    {
        $function = "GetAllSnapshots"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }
}

#Description: Returns the Description for Amazon Web Service Snapshot with a given snapshot Id
#Returns: string - description of snapshot
function GetSnapshotDescription([string] $snapshotID)
{
    try
    {
        $snapshot = GetSnapshot $snapshotID
        return $snapshot.Description
    }
    catch [Exception]
    {
        $function = "GetSnapshotDescription"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }    
}

#Description: Deletes an Amazon Web Service Snapshot with a given snapshot Id
#Returns: n/a
function DeleteSnapshot([string] $snapshotID)
{    
    try
    {
        $name = GetSnapshotDescription $snapshotID                 
        WriteToLog "InstanceName=$name SnapshotID=$snapshotID SnapshotStatus=Deleting"

        $deleteSnapshotRequest = new-object amazon.EC2.Model.DeleteSnapshotRequest
        $deleteSnapshotRequest.SnapshotId = $snapshotID
        $deleteSnapshotResponse = $EC2_CLIENT.DeleteSnapshot($deleteSnapshotRequest)
		$deleteSnapshotResult = $deleteSnapshotResponse;
        
        WriteToLog "InstanceName=$name SnapshotID=$snapshotID SnapshotStatus=Deleted" 
        
    }
    catch [Exception]
    {
        $function = "DeleteSnapshot"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
    }
    
}

#Description: Creates an Amazon Web Service Snapshot for a given instance Id
#Returns: string - newly created snapshotID
function CreateSnapshotForInstance([string] $volumeID, [string] $instanceID)
{    
    try
    {
        #Generate meaningful description for snapshot
        $date = get-date -format yyyyMMddhhmmss
        $name = GetInstanceName $instanceID
        $description = "{0} {1} {2} {3}" -f $name, $volumeID, $BACKUP_TYPE, $date
                 
        WriteToLog "InstanceName=$name VolumeID=$volumeID SnapshotStatus=Creating Snapshot"
                 
        $createSnapshotRequest = new-object amazon.EC2.Model.CreateSnapshotRequest
        $createSnapshotRequest.Description = $description
        $createSnapshotRequest.VolumeId = $volumeID
        $createSnapshotResponse = $EC2_CLIENT.CreateSnapshot($createSnapshotRequest)
        $createSnapshotResult = $createSnapshotResponse; 
        
        WriteToLog "InstanceName=$name InstanceID=$instanceID SnapshotID=$snapshotID SnapshotDescription='$description' SnapshotStatus=Created"
        return $createSnapshotResult.Snapshot.SnapshotId
    }
    catch [Exception]
    {
        $function = "CreateSnapshotForInstance"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }
}

#Description: Creates Amazon Web Service Snapshots for a collection of instance Ids
#Parameters: $instanceIDs string[]
#Returns: n/a
function CreateSnapshotsForInstances([string[]] $instanceIDs)
{
    try
    {
        if($InstanceIDs -ne $null)
        {
            $volumesRequest = new-object amazon.EC2.Model.DescribeVolumesRequest
            $volumesResponse = $EC2_CLIENT.DescribeVolumes($volumesRequest)
			$volumesResult = $volumesResponse
            foreach($volume in $volumesResult.Volumes)
            {
                if($InstanceIDs -contains $volume.Attachments[0].InstanceId)
                {
                    #Create the snapshot
                    $snapshotId = CreateSnapshotForInstance $volume.VolumeId $volume.Attachments[0].InstanceId

                    #Wait for snapshot creation to complete
                    $snapshotsRequest = new-object amazon.EC2.Model.DescribeSnapshotsRequest
                    $snapshotsRequest.SnapshotIds = $snapshotId   
                    
                    $start = get-date             
                    do
                    {
                        #abort if infinite loop or otherwise
                        if(IsTimedOut $Start) { break } 
                        
                        start-sleep -s 5
                        $snapshotsResponse = $EC2_CLIENT.DescribeSnapshots($snapshotsRequest)
                        $snapshotsResult = $snapshotsResponse
                    }
                    while($snapshotsResult.Snapshots[0].State -ne "completed")
                    
                }            
            }  
        }
        else
        {
            WriteToLog "SnapshotStatus=Backup failed' StatusMsg='No InstanceIDs to process'"
        }
    }
    catch [Exception]
    {
        $function = "CreateSnapshotForInstances"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
    }
}

#Description: Returns true if passed date is before the current date minus $EXPIRATION_DAYS value
#Returns: bool
function IsDailySnapshotExpired([datetime] $backupDate)
{
    try
    {
        $expireDate = (get-date).AddDays($EXPIRATION_DAYS*-1)
        return ($backupDate) -lt ($expireDate)
    }
    catch [Exception]
    {
        $function = "IsDailySnapshotExpired"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return false
    }    
}

#Description: Returns true if passed date is before the current date minus $EXPIRATION_WEEKS value
#Parameters: $backupDate datetime
#Returns: bool
function IsWeeklySnapshotExpired([datetime] $backupDate)
{
    try
    {
        $expireDate = (get-date).AddDays(($EXPIRATION_WEEKS * 7) * -1)
        return ($backupDate) -lt ($expireDate)
    }
    catch [Exception]
    {
        $function = "IsWeeklySnapshotExpired"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return false
    }    
}

#Description: Deleted old daily snapshots
#Parameters: n/a
#Returns: n/a
function CleanupDailySnapshots
{
    try
    {
        WriteToLog "StatusMsg='Cleaning up daily snapshots'"
        $deleteCount = 0
        
        $snapshots = GetAllSnapshots
        foreach($snapshot in $snapshots)
        {
            $description = $snapshot.Description
            $snapshotID = $snapshot.SnapshotId
            if($snapshot.Description -and $snapshot.Description.Contains("Daily"))
            {
                $backupDateTime = get-date $snapshot.StartTime
                $expired = IsDailySnapshotExpired $backupDateTime
                if($expired)
                {
                    DeleteSnapshot $snapshot.SnapshotId
                    $deleteCount ++
                    WriteToLog "SnapshotID=$snapshotID SnapshotDescription='$description' SnapshotStatus=Expired"
                }
                
            }
        }
        WriteToLog "DailySnapDelete=$deleteCount"
    }
    catch [Exception]
    {
        $function = "CleanupWeeklySnapshots"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return false
    } 
}

#Description: Deleted old weekly snapshots
#Parameters: n/a
#Returns: n/a
function CleanupWeeklySnapshots
{
    try
    {
        WriteToLog "StatusMsg='Cleaning up weekly snapshots'"
        $deleteCount = 0
        
        $snapshots = GetAllSnapshots
        foreach($snapshot in $snapshots)
        {
            $description = $snapshot.Description
            $snapshotID = $snapshot.SnapshotId
            if($snapshot.Description -and $snapshot.Description.Contains("Weekly"))
            {
                $backupDateTime = get-date $snapshot.StartTime
                $expired = IsWeeklySnapshotExpired $backupDateTime
                if($expired)
                {
                    DeleteSnapshot $snapshot.SnapshotId
                    $deleteCount ++
                    WriteToLog "SnapshotID=$snapshotID SnapshotDescription='$description' SnapshotStatus=Expired"
                }
                
            }
        }
        WriteToLog "WeeklySnapDelete=$deleteCount"
    }
    catch [Exception]
    {
        $function = "CleanupWeeklySnapshots"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return false
    } 
}

#Description: Checks if an Amazon Web Service Instance object is set to be backed up
#Returns: string
function GetBackedUpInstances([string[]] $backupTag)
{
    try
    {
        $backedUpInstancesRequest = new-object amazon.EC2.Model.DescribeInstancesRequest
        $backedUpInstancesResponse = $EC2_CLIENT.DescribeInstances($backedUpInstancesRequest)
        $backedUpInstancesResult = $backedUpInstancesResponse.Reservations
        $backedUpInstances = new-object System.Collections.ArrayList
        
        foreach($reservation in $backedUpInstancesResult)
        {
            foreach($instance in $reservation.Instances)
            {
                foreach($tag in $instance.Tags)
                {
                    If($tag.Key -eq $backupTag)
                    {
                        If($tag.value -eq "Yes")
                        {
                            $backedUpInstances.Add($instance.InstanceId) | out-null
                        }
                    }
                }
            }
        }
        return $backedUpInstances
    }
    catch [Exception]
    {
        $function = "GetBackedUpInstances"
        $exception = $_.Exception.ToString()
        WriteToLog "Function=$function Exception=$exception" -isException $true
        return $null
    }
}
