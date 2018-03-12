

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

#Usage: for example C:\Work\addDNSPermissionV2.ps1 -inPath c:\work\abnormalDNSList.csv 


[CmdletBinding()] 
[OutputType('System.DirectoryServices.ActiveDirectorySecurity')] 
param ( 
    [Parameter(Mandatory, 
               ValueFromPipeline, 
               ValueFromPipelineByPropertyName)] 
    [string]$inPath, 
    [Parameter(ValueFromPipeline, 
               ValueFromPipelineByPropertyName)] 
 
    [string]$AdIntegrationType = 'Domain' 
) 

 begin { 
    $ErrorActionPreference = 'SilentlyContinue' 
    Set-StrictMode -Version Latest 
} 

process{
    $DomainName = (Get-ADDomain).Forest

    $lists=import-csv $inPath
    $Obj =@()

    $inPathNameLen = $inPath.split("\")[$($inPath.split("\").length)-1].length
    $outPath=$inPath.Substring(0,$inPath.length-$inPathNameLen) + "DnsListOutput.csv"

    foreach ($list in $lists){
        try{
            $Sid = (Get-ADComputer $list.name -Properties ObjectSID).ObjectSID.Value
            $domain=$DomainName.split('.')[0]
            $account=$domain +'\'+ $($list.name)
            #$user=[System.Security.Principal.NTAccount]$account
            $user=[System.Security.Principal.SecurityIdentifier]$sid
            $AccessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($user, ‘GenericAll’, ‘Allow’)

            $disName=(Get-DnsServerResourceRecord -name $list.Name -ZoneName $DomainName).distinguishedname

            $acl=(Get-Acl -Path "ActiveDirectory:://RootDSE/$($disName)")
            $result = $Acl.AddAccessRule($AccessRule)
            $result = Set-Acl -Path "ActiveDirectory:://RootDSE/$disName" -AclObject $Acl

            # Write-host "Add permission on the record of $($list.Name)."
          

             $Properties = @{'Name' = $($list.Name)
                             'result' = "Success"
                            }
   
            $Obj += New-Object -TypeName PSObject -Property $Properties
        }
        catch {
             $Properties = @{'Name' = $($list.Name)
                                 'result' = "Failure. $($_.Exception.Message) "
                                }
   
                $Obj += New-Object -TypeName PSObject -Property $Properties
              # Write-Error "Something wrong while executing on the record:$($list.Name). $($_.Exception.Message) "
        }
        
    }

   $Obj| Select-Object Name,result | Export-Csv -Path $outPath -NoTypeInformation -encoding UTF8  #新建文件
      

    Write-host "Completed. Please refer to the detail in $outPath"
}
