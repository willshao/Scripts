


BatFile="patch_Windows6.1.bat"

On Error Resume Next
ServiceNames=Array("BITS","wuauserv")
StartMode="Automatic"

'Service setting
for i=0 to Ubound(ServiceNames)
	StartServ ServiceNames(i),StartMode
Next
'GPO setting
call GPOConfig

'Regristry setting
call setRegStr

'Call batch file
errTrap=CallBat(BatFile)
If errTrap <> 0 Then
    Wscript.echo "Error occured when call the bat file and errCode is " & errTrap
End If


Function setRegStr()
' Create a WSH Shell object: 
   Set wshShell = CreateObject( "WScript.Shell" ) 
' 
    On Error Resume Next
	strPath=Array("SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate", "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")
				  
	strName1=Array("WUServer","WUStatusServer")
	strValue1=Array("http://103.1.33.14")

	strName2=Array("NoAutoUpdate","AUOptions","ScheduledInstallDay","ScheduledInstallTime", "UseWUServer","NoAutoRebootWithLoggedOnUsers","AutoInstallMinorUpdates")
	strValue2=Array("00000000","00000004","00000000","00000012","00000001","00000001","00000001")


	RegPath="HKLM\" & strPath(0) & "\" & strName1(0)
	wshShell.RegWrite RegPath, strValue1(0), "REG_SZ" 
	RegPath="HKLM\" & strPath(0) & "\" & strName1(1)
	wshShell.RegWrite RegPath, strValue1(0), "REG_SZ"
	For i=0 to Ubound(strName2)
	    On Error Resume Next
		RegPath="HKLM\" & strPath(1) & "\" & strName2(i)
		wshShell.RegWrite RegPath, strValue2(i), "REG_DWORD"
		IF Err.Number <>0  Then 
			wscript.echo "Error with setstringvalue: " & i & ":" & Err.Number
		End IF
	Next

    Set wshShell=nothing
   
 End Function
 

Sub StartServ(ServiceName,StartMode)
	On Error Resume Next
    Set ServiceSet = GetObject("winmgmts:\\.\root\cimv2").ExecQuery("select * from Win32_Service where Name='" & ServiceName & "'")

	  for each oService in ServiceSet
		  'Start the service
          Result1 = oService.ChangeStartMode(StartMode)		  
		  if (Result1 <> 0) Then 
		      wscript.echo "Error with changing startMode on "&  ServiceName &". Error code: " & Result1 
		  End If
		  Result0= oService.StartService
		  If (Result0 <> 0 AND Result0 <> 10 ) Then
		 
			wscript.echo "Start " & ServiceName & " error code: " & Result0
			exit Sub 
		  End If
	  Next
     Set ServiceSet=nothing
End Sub


Function CallBat(BatFile)
    On Error Resume Next
	dim shell
	set shell=createobject("wscript.shell")
	 CallBat= shell.run(BatFile)
	 if err.number <> 0 Then 
	     Wscript.echo " Error with calling bat file, Errorcode:  " & err.number
	 End if
	set shell=nothing
    
End Function


Function GPOConfig()
    dim shell,mySystemRoot
	set shell=createobject("wscript.shell")
    mySystemRoot = Shell.ExpandEnvironmentStrings( "%SystemRoot%" )
	CallBat= shell.run("CMD.exe /C LGPO.exe /r .\Win7MachineGPO.txt /w  " & mySystemRoot & "\System32\GroupPolicy\Machine\Registry.pol", 1, True)
	
	set shell=nothing
End Function

