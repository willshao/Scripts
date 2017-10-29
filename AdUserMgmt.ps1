$LOG_PATH = "AdUserMgmt"
$SECURITY_GROUP_SAMACCOUNTNAME = "testGroup"
$DISABLE_DATE = 90
$REMOVE_DATE = 30
$SEARCH_BASE = "ou=testOU,dc=wenw,dc=com"

######################################################

$LOG_PATH = $LOG_PATH + "-" + (date -format "yyyyMMdd") + ".csv"

import-module ActiveDirectory

function InitLog
{
    Clear-Content $LOG_PATH
    Add-Content -path $LOG_PATH -value ("=" * 40) -force
}

function MyLog
{
	param($msg) 
	$msgs = (Get-Date).toString() + "; " + $msg
	Add-Content -path $LOG_PATH -value $msgs -force
    #Write-Host $msgs
}

function getUserList {
    $userList = Get-ADUser -Filter * -properties * -SearchBase "$SEARCH_BASE" |  Where-Object {($_.MemberOf -notcontains (Get-ADGroup -Filter {SamAccountName -eq $SECURITY_GROUP_SAMACCOUNTNAME}))}
    
    return $userList
}

function RemoveCheck {
    param($user)

    if (! $user.Enabled)
    {
        $lastModifyDate = Get-LastModifyUacTime $user.SamAccountName
        if ($lastModifyDate.adddays($REMOVE_DATE) -lt (Get-Date))
        {
            return $true
        }
    }

    return $false
}

function DisableCheck {
    param($user)

    if ($user.Enabled)
    {
        $lastLogonDate = Get-ADUserLastLogon $user.SamAccountName
        if ($lastLogonDate.adddays($DISABLE_DATE) -lt (Get-Date))
        {
            return $true
        }
    }

    return $false
}

function Get-ADUserLastLogon([string]$userName)
{
    $user = Get-ADUser $userName | Get-ADObject -Properties lastLogonTimeStamp, createTimeStamp
    $dt = $user.createTimeStamp
    if($user.lastLogonTimeStamp -gt 0)
    {
        $time = $user.lastLogonTimeStamp
        $dt = [DateTime]::FromFileTime($time)
    }
    return $dt
}

function Get-LastModifyUacTime([string]$userName)
{
    $user = Get-ADObject -Filter { SamAccountName -eq $userName } -Properties SamAccountName, userAccountControl, mail, "msDS-ReplAttributeMetaData";
    $repData = [xml] ("<root>"+ $user."msDS-ReplAttributeMetaData" +"</root>").Replace([char]0, " ")
  
    foreach ($attribute in $repData.root.DS_REPL_ATTR_META_DATA) {
        if ($attribute.pszAttributeName -eq "userAccountControl") {
            $changedDate = Get-Date($attribute.ftimeLastOriginatingChange);
            return $changedDate
        }
    }
}

function Main()
{
    $userList = (getUserList)
    foreach ($user in $userList)
    {
        if ("" -eq "$user")
        {
            return
        }
        elseif (RemoveCheck $user)
        {
            MyLog ("Remove; " + $user)
            #Get-AdUser -Filter {SamAccountName -eq $user.SamAccountName} | Remove-AdUser -Confirm:$false
            #$dn = $user.DistinguishedName
            #dsrm "$dn" -noprompt
        }
        elseif (DisableCheck $user)
        {
            $timeStamp = (Get-ADUserLastLogon $user)
            MyLog ("Disable; " + $user + "; $timeStamp")
            #Set-AdUser $user -Manager $null
            #foreach ($group in $user.MemberOf)
            #{
            #    $groupObj = ($group | Get-AdGroup)
            #    Remove-AdGroupmember $groupObj -Member $user -Confirm:$false
            #}
            #Disable-ADAccount -Identity $user.SamAccountName
        }
    }
}

. Main