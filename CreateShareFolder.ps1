$BASE_DIR = $MyInvocation.MyCommand.Definition
$BASE_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

$LOG_PATH = "$BASE_DIR\log.txt"
$SPLIT_FLAG = ";"
$AD_USER_LIST_PATH = "$BASE_DIR\ExportAdUser.csv"

$DIR_PREFIX = "C:\TestNewDir"
$DOMAIN_NAME = "wenw"
$FROM_DIR = "\\localhost\C$"

$IGNORE_LINES = 1
######################################################

function InitLog
{
    #Clear-Content $LOG_PATH
    #Add-Content -path $LOG_PATH -value ("=" * 40) -force
    Mylog ""
    $InitStr = "=" * 20 + (Date) + "=" * 20
    MyLog $InitStr
    MyLog ""
}

function MyLog([string]$msgs)
{
    Add-Content -path $LOG_PATH -value $msgs -force
    Write-Host $msgs
}

function CreateShareFolder([string]$dirPostfix, [string]$accountName)
{
    #MyLog ("$dirPostfix $accountName")
    $newDir = "$DIR_PREFIX\$accountName"

    MyLog ("md ""$newDir""")
    md "$newDir"
    
    $cmdStr = "$DOMAIN_NAME\$accountName" +":c"
    MyLog ("cacls ""$newDir"" /g $cmdStr /e")
    cacls "$newDir" /g $cmdStr /e
    
    $cmdStr = "$DOMAIN_NAME\administrator" +":f"
    MyLog ("cacls ""$newDir"" /g $cmdStr /e")
    cacls "$newDir" /g $cmdStr /e
    
    $adminPermissionStr = "$DOMAIN_NAME\administrator,full"
    $userPermissionStr = "$DOMAIN_NAME\"+"$accountName,change"
    MyLog ("net share $accountName=""$newDir"" /grant:""$adminPermissionStr"" /grant:""$userPermissionStr"" ")
    net share $accountName="$newDir" /grant:"$adminPermissionStr" /grant:"$userPermissionStr"
    
    MyLog ("Copy-Item $FROM_DIR\$dirPostfix $newDir -recurse")
    Copy-Item $FROM_DIR\$dirPostfix $newDir -recurse

    MyLog ""
}

function Main()
{
    InitLog

    $lines = Get-Content -Path $AD_USER_LIST_PATH
    $lineNum = 0
    foreach ($line in $lines)
    {
        $lineNum = $lineNum + 1
        if ($lineNum -le $IGNORE_LINES) 
        {
            continue
        }

        $itemArray = $line -split "$SPLIT_FLAG"
        $dirPostfix = $itemArray[5].Trim()
        $accountName = $itemArray[6].Trim()
        #MyLog ("$dirPostfix $accountName")

        CreateShareFolder $dirPostfix $accountName
    }
}

. Main