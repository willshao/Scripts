#############################################################
$REMOTE_LIST_FILE = "hostList.csv"
$TITLE = "getRemoteAdmins"
$UUID = "729ac832f6b848fbadff8f17fe64a602"
#############################################################
$PWD_PATH = Get-Location
$BASE_DIR = $MyInvocation.MyCommand.Definition
$BASE_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

$UUIDDIR = "$UUID"
$SPLIT_FLAG = ","
$VBS_FILE = "$TITLE.vbs"
$VBS_TARGET_PATH = "C:\$UUIDDIR\$VBS_FILE"

$LOG_PATH = "$BASE_DIR\$TITLE.log"
$OUTPUT_PATH = "$BASE_DIR\output.csv"
$TMP_FILE = "$BASE_DIR\tmp\tmp.txt"

function MyLog([string]$msgs)
{
    Add-Content -path $LOG_PATH -value $msgs -force
    Write-Host $msgs
}

function OutputLog([string]$msgs)
{
    Add-Content -path $OUTPUT_PATH -value $msgs -force
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

    if (Test-Path $OUTPUT_PATH)
    {
        Remove-Item -Recurse $OUTPUT_PATH
    }
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
    $REMOTE_DIR = "\\$remoteComputer\C$\$UUIDDIR"
    if (-not (Test-Path $REMOTE_DIR))
    {
        md $REMOTE_DIR
    }

    copy tools\*.vbs $REMOTE_DIR\
}

function Teardown([string]$remoteComputer)
{
    $REMOTE_DIR = "\\$remoteComputer\C$\$UUIDDIR"
    if (Test-Path $REMOTE_DIR)
    {
        Remove-Item -Recurse $REMOTE_DIR
    }
}

function testConnect([string]$remoteComputer, [string]$user, [string]$password)
{
    if ($user -eq "")
    {
        tools\PsExec.exe \\$remoteComputer ipconfig
    }
    else
    {
        tools\PsExec.exe \\$remoteComputer -u "$user" -p "$password" ipconfig
    }
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
        
        if (-not (Test-Path "\\$remoteComputer\c$"))
        {
            if ($remoteUser -eq "")
            {
                testConnect "$remoteComputer" "$remoteUser" "$remotePassword"
            }
        }

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
                $result = "$result".Trimend()
                MyLog $result
                if ($result -match "^\s*$TITLE.+$")
                {
                    $result = $result -replace "^(\s*)($TITLE )(.+)$", '$1$3'
                    OutputLog ("$remoteComputer,$result")
                }
            }
        }
        else
        {
            MyLog "$remoteComputer couldn't be connected!"
            continue
        }
    }
}

ExitEnv