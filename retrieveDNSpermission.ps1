
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

#Usage: for example C:\Work\retrieveDNSPermissionV3.ps1 -outPath c:\work\abnormalDNSList.csv


[CmdletBinding()] 
[OutputType('System.DirectoryServices.ActiveDirectorySecurity')] 
param ( 
    [Parameter(Mandatory, 
               ValueFromPipeline, 
               ValueFromPipelineByPropertyName)] 
    [string]$outPath, 
    [Parameter(ValueFromPipeline, 
               ValueFromPipelineByPropertyName)] 
 
    [string]$AdIntegrationType = 'Domain' 
) 

 begin { 
    $ErrorActionPreference = 'SilentlyContinue' 
    Set-StrictMode -Version Latest 
} 

process{


Import-Module activedirectory
$DomainName = (Get-ADDomain).Forest

$DomainDn = (Get-AdDomain).DistinguishedName


$path= "AD:DC=$DomainName,CN=MicrosoftDNS,DC=$AdIntegrationType`DnsZones,$DomainDn"
$count=0
$Obj =@()

$recordA= Get-DnsServerResourceRecord -ZoneName $DomainName -RRType "A"

foreach ($Record in $recordA) { 
     
try{
       
        
         $recordName=$Record.HostName
     
         if($recordName -like '_*' -or $recordName -like '.*' -or $recordName -eq 'DomainDnsZones' -or $recordName -eq 'ForestDnsZones'  -or $recordName -eq '@'){
                    continue
                }


            $resource = Get-DnsServerResourceRecord -name $recordName -ZoneName $DomainName
            
        if($resource.Timestamp -eq $Null) {
            continue
        }
         
                            
        $object=$recordName +'$'
       
        $isNormal=$false
        $access=(Get-Acl -Path "ActiveDirectory:://RootDSE/$($Record.DistinguishedName)").Access 
        foreach($identity in $access.IdentityReference.value){
            if($identity -like '*$'){

              
                if( $($identity.split('\')[1]) -eq $object){
                    
                    $isNormal=$true
                    
                }
            }
        }

        if(!$isNormal){
             #output
             $count=$count+1

             $Properties = @{'Name' = $recordName
                             'DistinguishedName' = $Record.DistinguishedName
                            }
   
            $Obj += New-Object -TypeName PSObject -Property $Properties

           
	    
	        	       
	           
        }
   } 
   catch{

     Write-Error "Something wrong while retrieving the record:$($recordName). $($_.Exception.Message) "
    }

}#end foreach
  
   if(!$count){write-host "No abnoroml record is found."}
   else{
         $Obj|Select-Object Name,DistinguishedName | Export-Csv -Path $outPath -NoTypeInformation -encoding UTF8  #新建文件
        Write-host "$count record(s) are found."
   }
} #end process
