#=======================================================================
#      Microsoft provides programming examples for illustration only, 
#      without warranty either expressed or implied, including, but 
#      not limited to, the implied warranties of merchantability 
#      and/or fitness for a particular purpose. It is assumeed 
#      that you are familiar with the programming language being 
#      demonstrated and the tools used to create and debug procedures. 
#      Microsoft support professionals can help explain the functionality 
#      of a particular procedure, but they will not modify these examples 
#      to provide added functionality or construct procedures to meet your 
#      specific needs. If you have limited programming experience, you may 
#      want to contact a Microsoft Certified Partner or the Microsoft fee-based 
#      consulting line at (800) 936-5200. For more information about Microsoft 
#      Certified Partners, please visit the following Microsoft Web site: 
#      http://www.microsoft.com/partner/referral/
#
#========================= Start of the script =========================


Import-Module ActiveDirectory

if(get-command new-mailcontact -errorAction SilentlyContinue){
    #do nothing if exists
}else{
    add-pssnapin Microsoft.Exchange.Management.PowerShell.E2010
}

$exePath = Split-Path -Parent $MyInvocation.MyCommand.Definition;
Set-Location $exePath;

$srcFile = "$exePath\GM-Active-Users.csv"

$targetOU = "OU=ContactTest,DC=E14DAG,DC=lab"

$execLogs = "$exePath\Import-Logs.txt"


if(Test-Path $srcFile){
    $srcContacts = Import-Csv -Path $srcFile 
    
    #to avoid duplicate checking of imported contacts, doing delete before import user
    $existsContacts = Get-ADObject -SearchBase $targetOU -Filter {(ObjectClass -eq "contact")} -Property Mail
    
    if($existsContacts){
        foreach($ec in $existsContacts){
        
            if($ec){
            
                $isExists = 0
                
                $tmpMail = $ec.Mail.Trim()
                
                #check exists in CSV
                foreach($src in $srcContacts){
                   if($tmpMail -eq $src.Mail.Trim()){
                        $isExists = 1
                        break;
                   }
                }
               
                if($isExists -eq 0){
                    Remove-AdObject $ec -Confirm:$false
                }
            }
        }
    }
    
    #start to import contacts
    foreach($uc in $srcContacts){
        if($uc){
        
            #$employeeID = if($uc.EmployeeID) { $uc.EmployeeID } else {" "}
            $givenName = if($uc.GivenName) {$uc.GivenName } else {" "}
            $surname = if($uc.SurName) {$uc.SurName} else {" "}
            $displayName = if($uc.displayName) {$uc.displayName} else {" "}
            $company = if($uc.Company) {$uc.Company} else {" "}
            $initials = if($uc.initials) { $uc.initials } else {" "}
            #$title = if($uc.title) { $uc.title } else {" "}
            #$businessCategory = if($uc.BusinessCategory) { $uc.BusinessCategory } else {" "}
            $streetAddress = if($uc.streetAddress) {$uc.streetAddress} else {" "}
            $c = if($uc.C) {$uc.C} else {" "}
            $telephoneNumber = if($uc.telephoneNumber) {$uc.telephoneNumber}  else {" "}
            $mobile = if($uc.mobile) {$uc.mobile}  else {" "}
            $mail = if($uc.mail) {$uc.mail}  else {" "}
            $msRTCSIPPrimaryUserAddress = if($uc.'msRTCSIP-PrimaryUserAddress') {$uc.'msRTCSIP-PrimaryUserAddress'}  else {" "}
            #$legacyExchangeDN = if($uc.legacyExchangeDN) {$uc.legacyExchangeDN}  else {" "}

            
            
            #$Attributes = @{ 'givenName' = $givenName; 'sn' = $surname; 'displayName' = $displayName; 'company' = $company;
                       # 'initials' = $initials; 'streetAddress'=$streetAddress;'C'=$c;'telephoneNumber'=$telephoneNumber;'mobile'=$mobile; 
                       #'mail' = $mail;   }
                       
             $Attributes = @{ 'givenName' = $givenName; 'sn' = $surname; 'displayName' = $displayName; 'company' = $company;
                        'initials' = $initials; 'streetAddress'=$streetAddress;'C'=$c;'telephoneNumber'=$telephoneNumber;'mobile'=$mobile; 
                       'mail' = $mail; 'msRTCSIP-PrimaryUserAddress' = $msRTCSIPPrimaryUserAddress;  }
            
            
            #check if exists depend on mail
            $contact = Get-ADObject -SearchBase $targetOU -Filter {((mail -eq $mail) -or (ExternalEmailAddress -eq $mail)) -and (ObjectClass -eq "contact")} 
            if($contact){
                #update contact
                "Updating new contact name: $displayName and mail: $mail " >> $execLogs
                
                try{
                    
                    Set-AdObject $contact -Replace $Attributes  -ErrorAction Stop
                    
                }catch{
                
                    "Error occurred when updating new contact name: $displayName and mail: $mail " >> $execLogs
                    $_.Exception.Message >> $execLogs
                    Write-Error $_.Exception.Message
                    #exit;
                    
                }
                
            }else{
                #add new contact
                
                "Adding new contact name: $displayName and mail: $mail " >> $execLogs
                
               # write-host $attributes
                
                
                try{   
                   $alias = "${givenName}${initials}${surname}.${company}" -replace '\s',''     
                   $obj = New-MailContact -Name "$givenName $surname" -Alias "${alias}" -ExternalEmailAddress $mail -OrganizationalUnit  $targetOU  -ErrorAction Stop
                   
                   $temp = $null
                   $temp = Get-ADObject -Filter {(mail -eq $mail) -and (ObjectClass -eq "contact")} 
                   if($temp){
                        Set-AdObject $temp -Replace $Attributes  -ErrorAction Stop
                   }
                   
                    
                }catch{
                
                    "Error occurred when adding new contact name: $displayName and mail: $mail " >> $execLogs
                    $_.Exception.Message >> $execLogs
                    Write-Error $_.Exception.Message
                    #exit;
                    
                }
            }
            
            
        }
    }

}else{
    "Source CSV file not exists." >> $execLogs
    Write-Warning "Source CSV file not exists."

}

"All done" >> $execLogs
Write-Host "All done"
