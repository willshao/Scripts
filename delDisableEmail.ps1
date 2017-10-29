$OU = "OU=testOU,DC=ad08test1,DC=com"
$REMOVE_DATE = 30

####################
$TITLE = "delDisableEmail"
$UUID = "ce966333c33d46d2aece30ae8c7c4192"

$PWD_PATH = Get-Location
$BASE_DIR = $MyInvocation.MyCommand.Definition
$BASE_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

$IGNORE_LIST = "$BASE_DIR\ignoreList.txt"
$LOG_PATH = "$BASE_DIR\$TITLE.log"

####################

Import-Module ActiveDirectory

function MyLog([string]$msgs)
{
    $dateMsgs = (Get-Date).ToString()+" :: $msgs"
    Add-Content -path $LOG_PATH -value "$dateMsgs" -force -Encoding UTF8
    Write-Host $msgs
}

function GetUserList {
    $userList = Get-ADUser -Filter * -properties Name,DistinguishedName,Enabled,SamAccountName,EmailAddress -SearchBase "$OU"
    return $userList
}

function RemoveCheck($user) {
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

function Get-LastModifyUacTime([string]$userName)
{
    $user = Get-ADObject -Filter { SamAccountName -eq $userName } -Properties SamAccountName,userAccountControl,mail, "msDS-ReplAttributeMetaData";
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
    MyLog "======================================="
    $ignoreList = Get-Content $IGNORE_LIST | % {$_.Trim()} | ? {$_ -ne ""}
    foreach ($user in $ignoreList)
    {
        MyLog "ignore: $user"
    }

    $userList = (GetUserList)
    foreach ($user in $userList)
    {
        MyLog "Checking $user"
        if (($ignoreList -notcontains $user.Name.Trim()) -and (RemoveCheck $user))
        {
            MyLog ("Remove: " + $user)
            Disable-Mailbox ¨Cidentity $user.DistinguishedName ¨Cconfirm:$false
        }
    }
}

. Main