$LOG_PATH = "checkUnchangedPassword.log"
$AD_USER_FILE = "adUsers.csv"

import-module ActiveDirectory

function InitLog
{
    Clear-Content $LOG_PATH
    Add-Content -path $LOG_PATH -value ("=" * 40) -force
}

function MyLog
{
	param($msg) 
	$msgs = (Get-Date).toString() + ": " + $msg
	Add-Content -path $LOG_PATH -value $msgs -force
}

function checkADAuthentication {
    param($username,$password)
    return ((new-object directoryservices.directoryentry "",$username,$password).psbase.name -ne $null)
}

function Main()
{
    InitLog
    MyLog "Begin!"

    $userList = Get-Content -Path $AD_USER_FILE 
    foreach ($user in $userList)
    {
        $userName, $password = $user.Split(',')
        #Write-Host "$userName" "$password"
        if (checkADAuthentication "$userName" "$password")
        {
            #Set-ADUser -Identity "$userName" -ChangePasswordAtLogon $true
            Write-Host "$userName" "$password"
            MyLog $userName
        }
    }
}

. Main