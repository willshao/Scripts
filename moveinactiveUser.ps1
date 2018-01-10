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
function MoveInactiveADComputers 
 (
  [parameter(Mandatory=$false)][String]$Searchbase,
 [String]$TargetPath,
 [TimeSpan]$InactiveTimeSpan,
  [bool]$ExcludeLastLogondateNull,
 [bool]$Move
 )
 {
    #log file path
    $file_output=".\inactivecomputersoutput.txt"

    #Load the required Snapins
     if (!(import-module "activedirectory" -ea 0)) {
     Write-Host "Loading active directory module." -ForegroundColor Yellow
         try
         {
            import-module "activedirectory" -ea Stop
         }
         catch
         {
              Write-Host "[ERROR] ActiveDirectory Module couldn't be loaded. Script will stop!" 
              Exit 1 
         }
     }#endif

    if(Test-Path $file_output){
        Remove-Item $file_output
    }

    #computers
    if ([string]::IsNullOrEmpty($Searchbase))
    {
        $inactivecomputers=search-adaccount -Computersonly -AccountInactive -TimeSpan $InactiveTimeSpan  
    } 
    else
    {
        $inactivecomputers=search-adaccount -Computersonly -SearchBase $Searchbase -AccountInactive -TimeSpan $InactiveTimeSpan
    }

    
    if ($Move -eq $true)
    {
        "********** Start move computers**********">>$file_output
        if ($inactivecomputers -ne $null)
        {
             foreach ($computer in $inactivecomputers){
             "Move computer:" + $computer.Name>>$file_output

                if ($ExcludeLastLogondateNull -eq $true -and $computer.lastlogondate -eq $null)
                {
                    "Don't move the computer that lastlogondate is null" >>$file_output
                }
                else
                {
                     try
                     {
                        move-adobject -identity $computer.DistinguishedName -targetpath $TargetPath
                        "Success to move the computer" >> $file_output
                     }
                     catch
                     {
                        Write-Host $Error[0] -ForegroundColor Red
                        $Error[0]>>$file_output
                     }
                }
             }
        }
        "********** Complete move computers**********">>$file_output
    }
    else
    {
        "********** List all inactive computers, not move them**********">>$file_output
        $inactivecomputers>>$file_output
    }
 }


 #MoveInactiveADComputers -TargetPath "OU=InactivePC,DC=TFSTrain,DC=com" -InactiveTimeSpan 90.00:00:00 `
 #-ExcludeLastLogondateNull $false -Move $false


MoveInactiveADComputers -Searchbase "OU=OU2,DC=TFSTrain,DC=com" -TargetPath "OU=OU1,DC=TFSTrain,DC=com" -InactiveTimeSpan 90.00:00:00 `
 -ExcludeLastLogondateNull $false -Move $false
