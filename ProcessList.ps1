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
#========================Start of the script=========================

$owners = @{}
$cpus = @{}

gwmi win32_process | % {
    try
    {
        if ($_.getowner().GetType().Name -eq "String")
        {
            $owners[$_.handle] = $_.getowner()
        }
        elseif ($_.getowner().user)
        {
            $owners[$_.handle] = $_.getowner().user
        }
    } catch [Exception] {
      
    }
}

gwmi win32_PerfFormattedData_PerfProc_Process | % {
    $cpus[$_.idprocess.tostring()] = $_.PercentProcessorTime
}

get-process | ?{$owners.ContainsKey($_.id.tostring()) -and $cpus.ContainsKey($_.id.tostring())} | select processname, id, @{N="CPU";E={$cpus[$_.id.tostring()]}}, @{l="Owner";e={$owners[$_.id.tostring()]}}


