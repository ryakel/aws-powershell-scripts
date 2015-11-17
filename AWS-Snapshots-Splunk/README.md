# PowerShell Scripts for EC2 Backups with Key-Value Pair Logging

A set of Windows PowerShell scripts to automate recurring snapshots on tagged AWS EC2 instances.  These have been tested on Windows Server 2012 R2.

## Credit

These scripts are a slightly modified version of [noahlh's AWS Automated Backup Powershell](https://github.com/noahlh/aws-automated-backup-powershell)


## Changes

Besides the update in API that Noahlh included, I have modified this version to remove email alerting and replace it with Key-Value pair logging in order to make it Splunk-friendly.

The instructions below are mostly his, with the exception that email setup has been removed.

## Installation

### 1.  Get the AWS SDK for .NET

Download the [AWS SDK for .NET](http://aws.amazon.com/sdkfornet/)

### 2.  Install the scripts

After the SDK has been installed, pick a place to store the scripts (ex. C:\AWS). Next, copy the scripts into your AWS directory. Additionally, create a directory called “Logs” inside of your AWS directory.

## Configuration

### Configure AWSConfig.ps1

Change the AWS .NET SDK Path:

_(Note the latest version has the DLLs in the \Net35 and \Net45 subdirectories of \bin - I used the \Net45 version for my 2012 R2 setup)_

```PowerShell
# AWS SDK Path 
Add-Type -Path "C:\Program Files (x86)\AWS SDK for .NET\bin\Net45\AWSSDK.EC2.dll"
```

Add your AWS Access Key, Secret, and Account ID:

_(Account ID can be found under your AWS username dropdown -> Security Credentials -> Account Identifiers.  Remove the dashes for the config file)_

```PowerShell
# Access Keys
$accessKeyID="XXXXXXXXXXXXXXXXXXXX"
$secretAccessKey="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$accountID = "############"
```

Uncomment the region(s) that your instances are running in:

```PowerShell
# EC2 Regions
# $serviceURL="https://ec2.us-east-1.amazonaws.com" # US East (Northern Virginia)
# $serviceURL="https://ec2.us-west-2.amazonaws.com" # US West (Oregon)
# $serviceURL="https://ec2.us-west-1.amazonaws.com" # US West (Northern California)
# $serviceURL="https://ec2.eu-west-1.amazonaws.com" # EU (Ireland)
# $serviceURL="https://ec2.ap-southeast-1.amazonaws.com" # Asia Pacific (Singapore)
# $serviceURL="https://ec2.ap-southeast-2.amazonaws.com" # Asia Pacific (Sydney)
# $serviceURL="https://ec2.ap-northeast-1.amazonaws.com" # Asia Pacific (Tokyo)
# $serviceURL="https://ec2.sa-east-1.amazonaws.com" # South America (Sao Paulo)
```

Enter your log path:

```PowerShell
# Log
$LOG_PATH="C:\AWS\Logs\"
```

Edit the max number of days to keep old snapshots and the max allowable runtime of the script:

```PowerShell
# Expiration
$EXPIRATION_DAYS = 7
$EXPIRATION_WEEKS = 4
$MAX_FUNCTION_RUNTIME = 60 # in minutes
```

### Create an Event Log

Execute the following line in PowerShell to allow the scripts to add entries into the event log:

```PowerShell
New-EventLog -Source "AWS PowerShell Utilities" -LogName "Application"
```

### Configure DailySnapshots.ps1

Verify the paths to AWSConfig.ps1 and AWSUtilities.ps1 :

```PowerShell
############## C O N F I G ##############
."C:\AWS\AWSConfig.ps1"

############## F U N C T I O N S ##############
."C:\AWS\AWSUtilities.ps1"
```

Edit the environment variables to define the Name (i.e. "Our Cloud Servers"), Type (i.e. "Staging", "Production", etc.), the Backup Type (i.e. "Daily") and, most importantly, the Tag to look for to identify instances to backup:

```PowerShell
# Environment
$ENVIRONMENT_NAME = "Production"
$ENVIRONMENT_TYPE = "AWS"
$BACKUP_TYPE = "Daily"
$backupTag = "xxxxxxxx" #Make sure the value of this tag is 'Yes', without the quotes, on the instances you want backed up
```
## Usage

Running the script DailySnapshot.ps1 will create a snapshot of each volume for each instance (without shutting them down).  Once it's complete, you'll receive an email via Amazon SES with the status of the backup and details of the process.

To automate the process, you can setup a recurring task in Task Scheduler.  When doing so, make sure you execute the "powershell" command and not just the script:

![task scheduler screenshow](http://i.imgur.com/07ozK3e.png)

## Troubleshooting

The vast majority of issues have to do with IAM permissions for the user / API key executing the scripts.  Make sure your IAM user has permissions for at least the following actions:

EC2:

  * CreateTags
  * DescribeInstances
  * StartInstances
  * StopInstances
  * DescribeSnapshots
  * DeleteSnapshot
  * CreateSnapshot
  * DescribeVolumes


## License

Copyright (C) 2015 - Ryan Kelch. Original script by Noah Lehmann-Haupt. Released under the MIT License. See the bundled LICENSE file for details.
