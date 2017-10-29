#############################################################
$REMOTE_LIST_FILE = "hostList.txt"
#############################################################
$TITLE = "getRemoteLocalGroupUser"
$UUID = "5d77c755661b49a2903fa0bc97ab8f89"
#############################################################
$PWD_PATH = Get-Location
$BASE_DIR = $MyInvocation.MyCommand.Definition
$BASE_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

$UUIDDIR = "$TITLE-$UUID"
$VBS_FILE = "$TITLE.vbs"
$VBS_TARGET_PATH = "C:\$UUIDDIR\$VBS_FILE"
$TMP_FILE = "tmp\tmp.txt"
$SPLIT_FLAG = ","

$LOG_PATH = "$BASE_DIR\$TITLE-log.txt"
$CSV_PATH = "$BASE_DIR\$TITLE-output.txt"
$USER_CSV_PATH = "$BASE_DIR\userList.csv"
$GROUP_CSV_PATH = "$BASE_DIR\groupList.csv"

function MyLog([string]$msgs)
{
    Add-Content -path $LOG_PATH -value $msgs -force
    Write-Host $msgs
}

function Log2CSV([string]$computeName, [string]$msgs)
{
    Add-Content -path $CSV_PATH -value "$computeName:: $msgs" -force
}

function Log2UserCSV([string]$computeName, [string]$msgs)
{
    Add-Content -path $USER_CSV_PATH -value "$computeName$SPLIT_FLAG $msgs" -force
}

function Log2GroupCSV([string]$computeName, [string]$msgs)
{
    Add-Content -path $GROUP_CSV_PATH -value "$computeName$SPLIT_FLAG $msgs" -force
}

function EntryEnv()
{
    Mylog ""
    $InitStr = "=" * 20 + (Date) + "=" * 20
    MyLog $InitStr
    MyLog ""

    cd $BASE_DIR
    If (-not (Test-Path tmp))
    {
        md tmp
    }

    if (Test-Path $CSV_PATH)
    {
        Remove-Item -Recurse $CSV_PATH
    }

    if (Test-Path $USER_CSV_PATH)
    {
        Remove-Item -Recurse $USER_CSV_PATH
    }
    Add-Content -path $USER_CSV_PATH -value "HostName$SPLIT_FLAG UserName$SPLIT_FLAG AccountType$SPLIT_FLAG Caption$SPLIT_FLAG Description$SPLIT_FLAG Disabled$SPLIT_FLAG Domain$SPLIT_FLAG FullName$SPLIT_FLAG LocalAccount$SPLIT_FLAG Lockout$SPLIT_FLAG PasswordChangeable$SPLIT_FLAG PasswordExpires$SPLIT_FLAG PasswordRequired$SPLIT_FLAG SID$SPLIT_FLAG SIDType$SPLIT_FLAG Group$SPLIT_FLAG Status" -force

    if (Test-Path $GROUP_CSV_PATH)
    {
        Remove-Item -Recurse $GROUP_CSV_PATH
    }
    Add-Content -path $GROUP_CSV_PATH -value "HostName$SPLIT_FLAG GroupName$SPLIT_FLAG Members" -force
}

function ExitEnv()
{
    Mylog ""
    $InitStr = "*" * 20 + (Date) + "*" * 20
    MyLog $InitStr
    MyLog ""
    
    cd $PWD_PATH
}

function Setup([string]$remoteComputer)
{
    $VBS_DIR = "\\$remoteComputer\C$\$UUIDDIR"
    if (-not (Test-Path $VBS_DIR))
    {
        md $VBS_DIR
    }
    if (-not (Test-Path $VBS_DIR\tmp))
    {
        md $VBS_DIR\tmp
    }
    copy tools\$VBS_FILE $VBS_DIR\
}

function Teardown([string]$remoteComputer)
{
    $VBS_DIR = "\\$remoteComputer\C$\$UUIDDIR"
    if (Test-Path $VBS_DIR)
    {
        Remove-Item -Recurse $VBS_DIR
    }     
}

function testConnect([string]$remoteComputer, [string]$user, [string]$password)
{
    tools\PsExec.exe \\$remoteComputer -u "$user" -p "$password" ipconfig
}

function RemoteRPC([string]$remoteComputer, [string]$user, [string]$password)
{
    if ($user -eq "")
    {
        #MyLog "PsExec: Default user and password"
        tools\PsExec.exe \\$remoteComputer cscript $VBS_TARGET_PATH > $TMP_FILE
    }
    else
    {
        #MyLog "PsExec: Specific user and password: $user, $password"
        tools\PsExec.exe \\$remoteComputer -u "$user" -p "$password" cscript $VBS_TARGET_PATH > $TMP_FILE
    }
    #type $TMP_FILE
}

#############################################################
# Main
#############################################################

EntryEnv

$lines = Get-Content -Path $REMOTE_LIST_FILE
foreach ($line in $lines)
{
    $line = $line.Trim()
    if ($line -ne "")
    {
        $lineArray = $line -split "$SPLIT_FLAG"
        if ($lineArray.Count -eq 1)
        {
            $remoteComputer = $lineArray[0].Trim()
            $remoteUser = ""
            $remotePassword = ""
        }
        elseif ($lineArray.Count -eq 3)
        {
            $remoteComputer = $lineArray[0].Trim()
            $remoteUser = $lineArray[1].Trim()
            $remotePassword = $lineArray[2].Trim()
        }
        else
        {
            MyLog "Ignore Line: $line"
            continue
        }

        MyLog ""
        MyLog "==> $remoteComputer"
        testConnect $remoteComputer "$remoteUser" "$remotePassword"
        
        if (Test-Path "\\$remoteComputer\c$")
        {
            MyLog "Connect to: $remoteComputer"
            Teardown $remoteComputer
            Setup $remoteComputer
            RemoteRPC $remoteComputer "$remoteUser" "$remotePassword"
            Teardown $remoteComputer

            $state = ""
            $results = Get-Content -Path $TMP_FILE
            foreach ($result in $results)
            {
                $result = $result.Trim()
                if ($result -match "^$TITLE::")
                {
                    MyLog $result
                    if ($result -notmatch "^$TITLE::\s+-->")
                    {
                        $outputStr = $result -replace "^($TITLE:: )(.+)$", '$2'
                        Log2CSV $remoteComputer $outputStr
                        if ($outputStr -match "^UserList:: ")
                        {
                            $outputStr = $outputStr -replace "^(UserList:: )(.+)$", '$2'
                            Log2UserCSV $remoteComputer $outputStr
                        }
                        if ($outputStr -match "^GroupList:: ")
                        {
                            $outputStr = $outputStr -replace "^(GroupList:: )(.+)$", '$2'
                            Log2GroupCSV $remoteComputer $outputStr
                        }
                    }
                }
            }
        }
        else
        {
            MyLog "$remoteComputer couldn't be connected!"
            Log2CSV $remoteComputer "Connect NOK"
            continue
        }
    }
}

ExitEnv