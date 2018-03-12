
#=======================================================================
#      Microsoft provides programming examples for illustration only, 
#      without warranty either expressed or implied, including, but 
#      not limited to, the implied warranties of merchantability 
#      and/or fitness for a particular purpose. It is assumed 
#      that you are familiar with the programming language being 
#      demonstrated and the tools used to create and debug procedures. 
#      Microsoft support professionals can help explain the functionality 
#      of a particular procedure, but they will not modify these examples 
#      to provide added functionality or construct procedures to meet your 
#      specific needs. If you have limited programming experience, you may 
#      want to contact a Microsoft Certified Partner or the Microsoft fee-based 
#      consulting line at (800) 936-5200. For more information about Microsoft 
#      Certified Partners, please visit the following Microsoft Web site: 
#      http://www.microsoft.com/partner/referral/
#
#========================= Start of the script =========================

#test on the default instance so we omit the instance name in server 08R2. we can use the actual instance
$dataSource = "." #such as win08r2\mssql
$database = "ADUser"
$viewName="userList"
$DomainB="Juneday.lab" #Use for cross-domain
$logPath="c:\work\"

#if we use the Windows integated security, user and pwd is not required and $IntegratedAuth=$true
#else we need specify user and pwd and $IntegratedAuth=$false
$IntegratedAuth=$true

$user = "sqlUser"
$pwd = "Password01!"


import-module activedirectory
$dateTime=(Get-Date).ToString()

$logName="groupPermissionLog"+(Get-Date -UFormat "%Y.%m.%d") +".txt"
$logFile=$logPath+$logName
if (!(test-path($logFile))){
    $result=new-item $logFile -type file
}

$message=(Get-Date).ToString() +" Script Starts."
      add-content $logFile $message -encoding utf8

try{
if($IntegratedAuth){
$connectionString = "Server=$dataSource;Database=$database;Integrated Security=$IntegratedAuth;"
}
else
{

$connectionString = "Server=$dataSource;Database=$database;User ID=$user;Password=$pwd;"

}
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString

$connection.Open()

$query = “SELECT * FROM dbo.”+ $viewName

$command = $connection.CreateCommand()
$command.CommandText = $query

$reader = $command.ExecuteReader()
$userName=@()
 while ($Reader.Read()) {
         $userName +=$Reader.GetValue($1)
     }
 $message=(Get-Date).ToString() +" Successfully connect to dataSource $dataSource, database $database and table $viewName" 
add-content $logFile $message -encoding utf8
     
$Connection.Close()

}
catch{
    $ExceptionData=$_.Exception.Message
    $ExceptionCode=$_.Exception.ErrorCode
    $message=(Get-Date).ToString() +" Something wrong with reading from dataSource $dataSource and database $database:$ExceptionData, $ExceptionCode"
    add-content $logFile $message -encoding utf8
    break
}
 
 
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString

$connection.Open() 

    
foreach($item in $userName) {
    try{
    $user=$item.trim()
    $groupsA=Get-ADPrincipalGroupMembership $user | select name 
    $groupsB=Get-ADPrincipalGroupMembership $user -ResourceContextServer $DomainB | select name 
   
    foreach($group in $groupsA){
     
       if(!($group.name -eq 'Domain Users')){
          
            Remove-adgroupmember -identity $group.name -members $user -Confirm:$false
                           
            $message=(Get-Date).ToString() +" Successfully remove $user from $($group.name)"
             add-content $logFile $message -encoding utf8
       }
       
    }
      foreach($group in $groupsB){
     
       if(!($group.name -eq 'Domain Users')){
           
            Remove-adgroupmember -identity $group.name -members $user -Confirm:$false -server $DomainB
                                 
            $message=(Get-Date).ToString() +" Successfully remove $user from $($group.name)"
             add-content $logFile $message -encoding utf8
       }
       
    }
    $boolean=1
    }
    catch{
        $ExceptionData=$_.Exception.Message
        $ExceptionCode=$_.Exception.ErrorCode
        
         $message=(Get-Date).ToString() +" Something wrong with retrieving ADGroups of $user :$ExceptionData, $ExceptionCode"
         add-content $logFile $message -encoding utf8
        $boolean=0
        break
    }
  try{
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.connection = $connection
    #$cmd.CommandTimeout = 600000
    $dateValue= "{0:yyyy-MM-dd HH:mm:ss}" -f (get-date)
  
    $cmd.commandtext ="UPDATE dbo."+ $viewName+ " SET removeGroup = '$boolean',timeStamp ='$dateValue'  WHERE userName ='$user'"
    $result=$cmd.executenonquery()
    
      $message=(Get-Date).ToString() +" Successfully update data of $user in the table"
      add-content $logFile $message -encoding utf8
    
   }
   catch{
        $ExceptionData=$_.Exception.Message
        $ExceptionCode=$_.Exception.ErrorCode
        write-host " Something wrong with updating data of $user in the table :$ExceptionData, $ExceptionCode"
        
   }
}    
$Connection.Close()


      $message=(Get-Date).ToString() +" All Over"
      add-content $logFile $message -encoding utf8
