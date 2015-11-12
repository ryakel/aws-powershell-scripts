############## C O N F I G ##############

#AWS SDK Path 
Add-Type -Path "C:\Program Files (x86)\AWS SDK for .NET\bin\Net45\AWSSDK.EC2.dll"
Add-Type -Path "C:\Program Files (x86)\AWS SDK for .NET\bin\Net45\AWSSDK.SimpleEmail.dll" #Comment out if using custom email server

#Access Keys
$accessKeyID="XXXXXXXXXXXXXXXXX"
$secretAccessKey="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$accountID = "XXXXXXXXXXX"

#EC2 Regions
#$serviceURL="https://ec2.us-east-1.amazonaws.com" # US East (Northern Virginia)
#$serviceURL="https://ec2.us-west-2.amazonaws.com" # US West (Oregon)
#$serviceURL="https://ec2.us-west-1.amazonaws.com" # US West (Northern California)
#$serviceURL="https://ec2.eu-west-1.amazonaws.com" # EU (Ireland)
#$serviceURL="https://ec2.ap-southeast-1.amazonaws.com" # Asia Pacific (Singapore)
#$serviceURL="https://ec2.ap-southeast-2.amazonaws.com" # Asia Pacific (Sydney)
#$serviceURL="https://ec2.ap-northeast-1.amazonaws.com" # Asia Pacific (Tokyo)
#$serviceURL="https://ec2.sa-east-1.amazonaws.com" # South America (Sao Paulo)

#SES Regions (do not uncomment if using custom email server)
#$sesURL="https://email.us-east-1.amazonaws.com" # US East (Northern Virginia)
#$sesURL="https://email.us-west-2.amazonaws.com" # US West (Oregon)
#$sesURL="https://email.eu-west-1.amazonaws.com" # EU (Ireland)

#Log
$LOG_PATH="C:\AWS\Logs\"

#Expiration
$EXPIRATION_DAYS = 7
$EXPIRATION_WEEKS = 4
$MAX_FUNCTION_RUNTIME = 60 # minutes

############## A W S  C L I E N T S ##############
#Global Amazon EC2 Client
$config=New-Object Amazon.EC2.AmazonEC2Config
$config.ServiceURL = $serviceURL
$EC2_CLIENT=New-Object Amazon.EC2.AmazonEC2Client($accessKeyID, $secretAccessKey, $config)

