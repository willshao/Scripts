#############################################################
Param(
    [Parameter(Mandatory=$True)]
    [int]$date,

    [Parameter(Mandatory=$True)]
    [string]$logname,

    [string]$account
)
#############################################################

$SEP_TAG = ", "

if ($date -lt 0)
{
    $events = Get-EventLog -LogName $logname
}
else
{
    $startDate = (Get-Date).Date.AddDays(-1 * $date)
    $endDate = (Get-Date).Date.AddDays(-1 * ($date-1))
    $events = Get-EventLog -LogName $logname -After $startDate -Before $endDate
}
$accountArray = @($account -split ";" | %{$_.Trim().ToLower()})
$uidsArray =  @($accountArray | ?{$_ -match "\\"} | %{$_ -replace "^(.+)\\([^\\]+)$", '$2'})
$accountArray = $uidsArray + $accountArray
$hostNameStr = (hostname)

foreach ($objEvent in $events)
{
    $flag = $false
    
    if ($accountArray.Length -eq 0)
    {
        $flag = $True
        $userName = $objEvent.UserName
    }
    else
    {
        if (($accountArray -contains ($objEvent.UserName+"").Trim().ToLower()) -or ($accountArray -contains ("$hostNameStr\"+$objEvent.UserName).Trim().ToLower()))
        {
            $flag = $true
            $userName = $objEvent.UserName
        }
        else
        {
            #check if it is in any replacement string
            foreach ($objString in $objEvent.ReplacementStrings)
            {
                $objString = [string]$objString
                $objString = $objString.Trim().ToLower()
                if (($accountArray -contains $objString) -or ($accountArray -contains ("$hostNameStr\" + $objString).Trim().ToLower()))
                {
                    $flag = $true
                    $userName = $objString
                    break
                }
            }
        }
    }

    #check the name is included in adminArray, if yes, record to the file
    if ($flag -eq $true)
    {
        $logonType = ""
        if ($objEvent.Message -match "\s*((登录类型:)|(Logon Type:))\s+(\d+)\s*")
        {
            $logonType = $objEvent.Message -replace "(?s)^.+\s*((登录类型:)|(Logon Type:))\s+(\d+)\s*.+$", '$4'
        } 
        $outStr = "Result :: $userName $SEP_TAG " + $objEvent.TimeGenerated + " $SEP_TAG " + [string]$objEvent.InstanceId + " $SEP_TAG " + $objEvent.EntryType + " $SEP_TAG " + $objEvent.CategoryNumber + " $SEP_TAG " + $logonType
        Write-Host $outStr
    }
}