<#
Usage:
  This script is used to notify the user whose account is 
  about to expire in specific days.
  
Example: 
.\UserExpiryReminder.ps1 -expDays 50

#>


param(
   [int]$expDays
)

function Show-BalloonTip {            
    [cmdletbinding()]            
    param(            
     [parameter(Mandatory=$true)]            
     [string]$Title,            
     [ValidateSet("Info","Warning","Error")]             
     [string]$MessageType = "Info",            
     [parameter(Mandatory=$true)]            
     [string]$Message,            
     [string]$Duration=10000            
    )            

    [system.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null            
    $balloon = New-Object System.Windows.Forms.NotifyIcon            
    $path = Get-Process -id $pid | Select-Object -ExpandProperty Path            
    $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)            
    $balloon.Icon = $icon            
    $balloon.BalloonTipIcon = $MessageType            
    $balloon.BalloonTipText = $Message            
    $balloon.BalloonTipTitle = $Title            
    $balloon.Visible = $true            
    $balloon.ShowBalloonTip($Duration)   
    
    #Unregister-Event -SourceIdentifier Click_Event -ErrorAction SilentlyContinue
  
}

$userName=$Env:username
$Ldap = "dc="+$env:USERDNSDOMAIN.replace(".",",dc=")         
#$Filter = "(&(objectCategory=person)(objectClass=user))" 

$searcher=[adsisearcher]"" 
$searcher.Filter="(&(objectCategory=person)(objectClass=user)(sAMAccountName=$userName))" 
             
$Ldap = $Ldap.replace("LDAP://","") 
$searcher.SearchRoot="LDAP://$Ldap" 
$results=$searcher.FindAll() 
 
$ADObjects = @() 
$today = get-date

foreach($result in $results) 
{ 
    [Array]$propertiesList = $result.Properties.PropertyNames 

    $obj = New-Object PSObject 
    foreach($property in $propertiesList) 
    {  
       $obj | add-member -membertype noteproperty -name $property -value ([string]$result.Properties.Item($property)) 
    } 
    
    $intVal = $obj.accountexpires;

    if(($intVal -eq 0) -or ($intVal -gt [DateTime]::MaxValue.Ticks)){
        #never expired
    }else{
       
        #Check the expiry date of the current user
        $Expiry=[DateTime]::FromFileTime($intVal)
        $ExpiryDays=($Expiry-$today).Days
        if($ExpiryDays -gt 0 -and $ExpiryDays -lt $expDays){
           Show-BalloonTip -Title “开机提醒|Account Warning：” -MessageType Warning -Message “您的账号 $userName 剩余有效期为 $ExpiryDays 天，如需延期，请在ITSH中申请。`r`nYour account $userName will be expired after $ExpiryDays days, please goto ITSH for applying if you need extension” -Duration 600000
       }
    }
}

