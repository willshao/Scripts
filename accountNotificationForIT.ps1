<#
Usage:
  This script is used to notify the IT ADMIN whose accounts are expired but still enabled
  
Example: 
.\accountNotificationForIT.ps1 

#>



Import-Module ActiveDirectory

#*** Please configure the following variables ***#

$smtpServer = "192.168.0.50"
$smtpFrom = "it@test.com"

$textEncoding = [System.Text.Encoding]::UTF8

$itAdmin = "yejxu@microsoft.com","dxu@microsoft.com" #will send email to this account for those already expired accounts
$csvFile = "c:\expiredAccounts.csv" #use for attachment of email

#*** end of variables ***#

$today = get-date


#query all enabled account which will be expired in specific days
$users = Get-AdUser -Filter{Enabled -eq "True" -and AccountExpirationDate -lt $today} -Properties Name, DistinguishedName, AccountExpirationDate

if($users)
{
    $expiredAccounts = @();

    foreach($u in $users)
    {
    
            #account already expired, but still enabled
            #$expiredAccounts += $u.UserPrincipalName;
            $expiredAccounts += New-Object PSObject -Property @{
                UserPrincipalName = $u.UserPrincipalName
                ExpiredDate = $u.AccountExpirationDate
            }
        
    }
    
    
    #send email to IT administrator
    if($expiredAccounts)
    {
        $mailSubject = "[Accounts Notification]There are accounts which already expired but still enabled";
        $mailBody = "
        ---------------------------------------------------------------------------------------------------------------------------------
        This is an automated notification email, please do not reply to this message.
        ---------------------------------------------------------------------------------------------------------------------------------

        ---------------------------------------------------------------------------------------------------------------------------------
        Account Expiration Notification
        ---------------------------------------------------------------------------------------------------------------------------------


        Hello Admin,
        
        There are accounts are already expired but still enabled, please check attached file to get the list.
        
            
        ---------------------------------------------------------------------------------------------------------------------------------
        The IT Team
        ---------------------------------------------------------------------------------------------------------------------------------
        "
        
        
        $expiredAccounts | Export-Csv -Path $csvFile -NoTypeInformation
        
        Send-MailMessage -To $itAdmin  -From $smtpFrom -Subject $mailSubject -Body $mailBody -Attachments $csvFile -SmtpServer $smtpServer -priority High -Encoding $textEncoding
    }
}
