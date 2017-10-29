$BASE_DIR = $MyInvocation.MyCommand.Definition
$BASE_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition

$SPLIT_FLAG = ","
$AD_USER_LIST_PATH = "$BASE_DIR\userList.csv"

$FROM_OU = "OU=testOU2,DC=ad08test1,DC=com"
$TO_OU = "OU=testOU,DC=ad08test1,DC=com"

$DC_SERVER = "ad.ad08test1.com"

######################################################

import-module ActiveDirectory

function MyLog([string]$msgs)
{
    Write-Host $msgs
}

function Main()
{
    $lines = Get-Content -Path $AD_USER_LIST_PATH
    foreach ($line in $lines)
    {
        $line = $line.Trim()
        if ($line -ne "")
        {
            $lineArray = $line -split "$SPLIT_FLAG"
            $sam = $lineArray[0].Trim()
            MyLog "Checking: $sam"

            try { $exists = Get-ADUser -LDAPFilter "(SamAccountName=$sam)" -Server $DC_SERVER -SearchBase $FROM_OU } 
            catch { } 
            if($exists) 
            {
                MyLog "Move $sam to OU: $TO_OU"
                $dn  = (Get-ADUser $sam).DistinguishedName
                Move-ADObject -Identity $dn -TargetPath $TO_OU
            }
            else
            {
                MyLog "SKIPPED: $sam" 
            }
        }
    }
}

. Main