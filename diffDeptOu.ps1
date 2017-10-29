$BASE_OU_DN = "OU=testOU,DC=ad08test1,DC=com"
####################

Import-Module ActiveDirectory

$adUserList = Get-AdUser -SearchBase "$BASE_OU_DN" -Properties DistinguishedName,Department -Filter *

foreach ($adUser in $adUserList)
{
    $userDN = $adUser.DistinguishedName;
    $userOU = $userDN -replace '(^.+?)(OU=.+)$', '$2'
    $userDepartment = $adUser.Department
    $userDeptStr = ""
    if ($userDepartment.Length -gt 0)
    {
        $userDeptStr = $userDepartment.Replace('\','\\').Replace(',','\,').Replace('=','\=');
    }
    else
    {
        $userDepartment = "None"
    }
    if ($userOU.Indexof("OU=$userDeptStr,") -ne 0)
    {
        Write-Host "$userDN`t$userDepartment`t$userOU"
    }
}
