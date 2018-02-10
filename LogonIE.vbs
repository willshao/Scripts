Option Explicit
Dim sURL,sTime
'Specify the URL and time(year,Month,Day)

sURL="http://www.microsoft.com"

sTime="2017/08/18"


'Start the script process
Dim objWMIService,colItems,objItem
Dim dtmLocalTime,dtmMonth,dtmDay,dtmYear
Dim objsTime,objsTImeItem,sdtm
Dim sdtmYear,sdtmMonth,sdtmDay
objsTime=split(sTime,";")

Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colItems = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
For Each objItem in colItems
    dtmLocalTime = objItem.LocalDateTime
    dtmMonth = Mid(dtmLocalTime, 5, 2)
    dtmDay = Mid(dtmLocalTime, 7, 2)
    dtmYear = Left(dtmLocalTime, 4)
    
Next

For each objsTImeItem in objsTime
    sdtm=split(objsTImeItem,"/")
	sdtmYear=sdtm(0)
	sdtmMonth=sdtm(1)
	sdtmDay=sdtm(2)
	If sdtmYear= dtmYear and sdtmMonth =dtmMonth and sdtmDay = dtmDay Then 
	    LogonScript(sURL)
	    Exit For
	End If
    'Wscript.echo "Time: " & sdtm(0)
Next
'Wscript.Echo dtmLocalTime


Function LogonScript(sURL)
	On Error Resume Next
	
	Dim sIE
	Set sIE = CreateObject("InternetExplorer.Application")
	
	sIE.navigate sURL
	sIE.FullScreen=True
	sIE.Visible = True
	
    If Err.Number <> 0 Then 
	   Wscript.Echo "Error occured when running IE: " & err.description
	End If
	Set sIE=nothing
End Function
 
 
 
 
