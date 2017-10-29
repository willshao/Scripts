# Configuration
import-module ActiveDirectory
$NEVER_MATCH_STR = "ThIsStRiNgIsNeVeRmAtChEd"
$EXPIRE_DATE_STR = $NEVER_MATCH_STR + "EXPIREDATE"
$USER_NAME_STR = $NEVER_MATCH_STR + "USERNAME"
##########################################################################

$EXPIRE_DAY = 1500

$MAIL_SUBJECT = "您的Windows域账户(${USER_NAME_STR})的密码将于${EXPIRE_DATE_STR}(月/日/年)过期."
$MAIL_FROM = "tt753951@gmail.com"
$MAIL_FROM_NAME = "DisplayName"
$MAIL_BODY = "您的Windows域账户(${USER_NAME_STR})的密码将于${EXPIRE_DATE_STR}(月/日/年)过期, please update password ASAP."
$MAIL_PRIORITY = "High"

$SMTP_SERVER = "smtp.googlemail.com"
$SMTP_USER = "tt753951@gmail.com"
$SMTP_PASSWORD = "753951tt"
$SMTP_ENABLE_SSL = $true #SMTP server needs SSL should set this attribute

##########################################################################

# Gloable Var
$SMTP = New-Object System.Net.Mail.SmtpClient -argumentList $SMTP_SERVER
$SMTP.Credentials = New-Object System.Net.NetworkCredential -argumentList $SMTP_USER,$SMTP_PASSWORD
$SMTP.EnableSsl = $SMTP_ENABLE_SSL

$MAIL = New-Object System.Net.Mail.MailMessage
$MAIL.From = New-Object System.Net.Mail.MailAddress($MAIL_FROM, $MAIL_FROM_NAME)
$MAIL.Priority  = $MAIL_PRIORITY

function Get-XADUserPasswordExpirationDate() 
{
    Param ([Parameter(Mandatory=$true,  Position=0,  ValueFromPipeline=$true, HelpMessage="Identity of the Account")]
    [Object] $accountIdentity)
    PROCESS {
        $accountObj = Get-ADUser $accountIdentity -properties PasswordExpired, PasswordNeverExpires, PasswordLastSet
        if ($accountObj.PasswordExpired) {
            echo ("Password of account: " + $accountObj.Name + " already expired!")
        } else { 
            if ($accountObj.PasswordNeverExpires) {
                echo ("Password of account: " + $accountObj.Name + " is set to never expires!")
            } else {
                $passwordSetDate = $accountObj.PasswordLastSet
                if ($passwordSetDate -eq $null) {
                    echo ("Password of account: " + $accountObj.Name + " has never been set!")
                }  else {
                    $maxPasswordAgeTimeSpan = $null
                    $dfl = (get-addomain).DomainMode
                    if ($dfl -ge 3) { 
                        ## Greater than Windows2008 domain functional level
                        $accountFGPP = Get-ADUserResultantPasswordPolicy $accountObj
                        if ($accountFGPP -ne $null) {
                            $maxPasswordAgeTimeSpan = $accountFGPP.MaxPasswordAge
                        } else {
                            $maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
                        }
                    } else {
                        $maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
                    }
                    if ($maxPasswordAgeTimeSpan -eq $null -or $maxPasswordAgeTimeSpan.TotalMilliseconds -eq 0) {
                        echo ("MaxPasswordAge is not set for the domain or is set to zero!")
                    } else {
                        echo ("Password of account@ " + $accountObj.Name + " expires on@ " + ($passwordSetDate + $maxPasswordAgeTimeSpan))
                    }
                }
            }
        }
    }
}

function GetExpireReminderUserList()
{
    Param($ExpireDay)
    
    $expireDate = (Get-Date).adddays($ExpireDay)
    $userList = Get-ADUser -Filter * -properties Name, DisplayName, Mail, PasswordExpired, PasswordNeverExpires, enabled | Where-Object {($_.DisplayName -ne $null) -and ($_.Mail -ne $null) -and ($_.PasswordExpired -ne $true) -and ($_.PasswordNeverExpires -ne $true) -and ($_.enabled -eq $true) -and (([datetime]((Get-XADUserPasswordExpirationDate $_).split("@",10)[-1])) -lt $expireDate)}

    return $userList
}

function SendExpireReminderMail()
{
    Param($User)
    
    $mailTo = $User.Mail
    $userName = $User.DisplayName
    $name = $User.SamAccountName
    
    #Write-Host $mailTo
    #Write-Host $userName
    
    $expireDate = ((Get-XADUserPasswordExpirationDate $User).split("@",10)[-1].split(" ",3)[1])
    $MAIL.To.Clear()
    $MAIL.To.Add($mailTo)
    $MAIL.Subject = ($MAIL_SUBJECT -replace "${EXPIRE_DATE_STR}","$expireDate") -replace "${USER_NAME_STR}","$name"
    $MAIL.Body = ($MAIL_BODY -replace "${EXPIRE_DATE_STR}","$expireDate") -replace "${USER_NAME_STR}","$name"

    #Write-Host $MAIL.To $MAIL.Priority $MAIL.From
    #Write-Host $MAIL.Subject $MAIL.Body
    #return

    #send the message
    try{
        $SMTP.Send($MAIL)
        Write-Host 'Ok, Send success!'
    }
    catch [Exception] {
        Write-Host $_.Exception.GetType().FullName; 
        Write-Host $_.Exception.Message; 
        Write-Host 'Error! Failed!'
    }
}

function Main()
{
    $userList = GetExpireReminderUserList -ExpireDay $EXPIRE_DAY
    foreach($user in $userList)
    {
        if ($user)
        {
            Write-Host "Send Mail to" $user.DisplayName $user.Mail
            #SendExpireReminderMail -User $user
        }
    }
}

. Main

#Get-ADUser 'test3' -properties Enabled, PasswordLastSet | Format-List
#C:\Users\Administrator>ldifde -f output.txt -d "cn=test3,ou=testOU,dc=wenw,dc=com"
#C:\Users\Administrator>ldifde -f output.txt -d "cn=test3,ou=testOU,dc=wenw,dc=com" -l pwdlastset,useraccountcontrol