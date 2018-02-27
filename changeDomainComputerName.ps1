<#
This script is used to rename the computer in the domain.

#>

$file=".\pcList.csv"


FUnction renameComp(){

    param(
       [Parameter(Mandatory=$True)] 
       [string] $file_pclist,
       [Switch]$VerboseMsg
    )
    
   Begin 
    { 
    Write-Verbose "Rename the specified computers" 
    } 
     
Process 
    { 
       #Get the permission of domain admin 
       $admin ="testMS\administrator" # Read-Host -Prompt 'Please input the admin account,forexample, testMS\admin'
       $pwd ="Password01@" # Read-Host -Prompt 'Please input the password'
       $log=".\result.csv"
       $log1=".\log.txt"

       $Count=0
       if(Test-Path $file_pclist){
            $compInfo=import-csv -path $file_pclist ;
            $UserNames=@()
            foreach($Item in $compInfo){
                  
                     $count=$count+1
                 
                  $UserName=$Item."username";
                  $compName=$Item."CompName"; 
                  $newCompName=$Item."newCompName";
                  
                  $return=netdom renamecomputer $compName /newname:$newCompName /userd:$admin /passwordd:$pwd /force /reboot:80           
                  "$(get-date) Rename the computer $($compName). $return " >>$log1
                  if($return -like "*failed*"){
                     $result="Failure"
                     $comment=$return -join ""
                  }
                  if($return -like "*The command completed successfully*"){
                     $result="Success"
                     $comment=""
                  }
                   $obj=New-object -TypeName PSObject -Property @{'Username'=$Username
                                                        'oldcompName'=$compName
                                                        'newCompName'=$newCompName
                                                        'result'=$result
                                                        'comment'=$comment
                                                       }

            	  if($obj){
                      if($Count -eq 1){
    	    
                	         $Obj|Select-Object Username,oldcompName,newCompName,result,comment| Export-Csv -Path $log -NoTypeInformation
                	    }
                	    else
                	    {
                	           #Append to CSV file
                	        
                	        $Obj| Select-Object Username,oldcompName,newCompName,result,comment | ConvertTo-Csv -NoTypeInformation `
                	        | select -Skip 1 `
                	        | Out-File -Append $log
                	        
                    }
                }
                 # SendNetMessage -Message "Your computer will restart in a minute." -Computername $compName -Seconds 30 -Wait
            }
        }
        else
        {
           write-host "No found the pclist file $file_pclist" 
        }
    } 
End 
    { 
    Write-Verbose "All done." 
    } 
}

renameComp -file_pclist $file

