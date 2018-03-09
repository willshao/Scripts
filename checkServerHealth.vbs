'On Error Resume Next

'Default file path
csvFileFolder="."
'Default file name and localcomputer 
strComputer="."
strComputerName=CreateObject("Wscript.Network").ComputerName
csvFileName=strComputerName &"_CompInfo.csv"
csvFilePath =csvFileFolder & "\" & csvFileName

'Wscript.echo strComputerName
exportInfo strComputer,csvFilePath
'PatchCheck csvFilePath,strComputer
Function exportInfo(strComputer,csvFilePath)
	' Create new CSV file 
	Const ForWriting = 2

	Set objFSO = CreateObject("Scripting.FileSystemObject")

	Set objCSVFile = objFSO.OpenTextFile(csvFilePath, ForWriting, True)
	objCSVFile.writeline "主机名,品牌,型号,序列号,操作系统,开机时间,CPU型号,CPU个数,CPU核数,内存大小,CPU使用率,内存使用率,进程数,文件分区(超过70%),IP地址,网络联通性,有无磁盘映射,盘挂载点,ntp偏差,有无KB2688338,端口占用数量,许可证状态,"

    Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
	OSInfo objWMIService,objCSVFile,objFSO
	
	objCSVFile.close
	Set objCSVFile=nothing 
	Set objFSO=nothing 
	UTF8 csvFileName, csvFileName
End Function

'Export info of OS
Function OSInfo(objWMIService,objCSVFile,objFSO)

	Dim CPUNUM 
	For Each objItem in objWMIService.ExecQuery("Select * from Win32_ComputerSystem") 
		'主机名 
		strComputerName = objItem.Name 
		'品牌
		strManufacturer= objItem.Manufacturer
		'型号
		strModel=objItem.Model
		
		 TotalMem= objItem.TotalPhysicalMemory 
	Next
	For Each objItem In objWMIService.ExecQuery("Select * from Win32_Bios")
		'序列号
		strSerNum=objItem.SerialNumber
	Next
	if strModel="Virtual Machine" then 
		     strManufacturer="VMware. Inc"
			 strModel="VMware Virtual Platform"
			 strSerNum="VMware-" & strSerNum
	End if
	For Each objItem In objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
		'操作系统
		strOSVersion = objItem.Caption & " " & objItem.CSDVersion
		'开机时间
		strBootTime=objItem.LastBootUpTime
		SET objWMIDateTime = CREATEOBJECT("WbemScripting.SWbemDateTime")
		objWMIDateTime.Value = objItem.LastBootUpTime
		strBootTime=objWMIDateTime.GetVarDate
	Next
	CPUNUM=0
	For Each objItem in objWMIService.ExecQuery("Select * from Win32_Processor") 
	    'CPU个数
		CPUNUM = CPUNUM + 1
	    'CPU型号
		CPUNAME = objItem.Name
		'CPU核数
		CPUCORE = objItem.NumberOfCores
	Next
	'CPU总核数
	CPUCORES = CPUCORE * CPUNUM
    '内存大小
	strMemory=Round(TotalMem/1024/1024/1024)
	'CPU使用率
	Set objProc = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\cimv2:win32_processor='cpu0'")
    strCPUPercent=objProc.LoadPercentage & "%"
	'内存使用率
	For Each objItem In objWMIService.InstancesOf("Win32_OperatingSystem") 
		strMemPercent=Round(((objItem.TotalVisibleMemorySize-objItem.FreePhysicalMemory)/objItem.TotalVisibleMemorySize)*100) & "%" 
	Next
	'进程数
	proSum = 0
	For Each objItem in objWMIService.ExecQuery("Select * from Win32_Process")
		proSum = proSum + 1
	Next
	'磁盘分区
	
	strDriversInfo= GetDriversInfo(objFSO)
	'IP 地址 
	Dim strGW(1)
	strIP=""
	strConnect=""
	For Each objItem in objWMIService.ExecQuery("Select * from Win32_NetworkAdapterConfiguration Where IPEnabled = True")
		'IPAddress and Netmask
		strIP =  wfl(objItem.IPAddress, objItem.IPSubnet) & ";" & strIP 
		if not IsNull(objItem.DefaultIPGateway) then
		    '网络联通信
			strConnect=objItem.DefaultIPGateway(0) & " " & Ping(objItem.DefaultIPGateway(0),objWMIService)  & ";" & strConnect
		'Wscript.echo strDefaultIPGateway
		end if

	Next
	'有无NFS服务器 '盘挂载点
	strDrivers=mapDriver

	if len(strDrivers)<>0 then
	    driverBoolean="True"
	else
	    driverBoolean="False"
	End if 
	'ntp偏差
	Set objShell = WScript.CreateObject("WScript.Shell")
	Set ObjExec0 = objShell.Exec("cmd.exe /c w32tm /stripchart /computer:172.21.16.66 /samples:3 /dataonly")
	strNTP=""
	Do
		strFromProc0 = ObjExec0.StdOut.ReadLine()
		strNTP= strNTP  &" "& strFromProc0  
		
	Loop While Not ObjExec0.Stdout.atEndOfStream
	strNTP=replace(strNTP,",",";")
	
	'有无KB2688338
	strKB="2688338" 
	KBBoolean=CheckParticularHotfix(objWMIService,strKB)
      
	'端口占用数量
	strPort=""
	Set ObjExec = objShell.Exec("cmd.exe /c netstat -nao | find /i ""estab"" /c")
	Do
		strFromProc = ObjExec.StdOut.ReadLine()
		strPort=  strPort &" "& strFromProc  
	Loop While Not ObjExec.Stdout.atEndOfStream
	
	
	'许可证状态
	
	strLicense=checkLicense(objWMIService) 

	
	objCSVFile.writeline strComputerName & "," & strManufacturer & "," & strModel & "," & strSerNum & "," & strOSVersion & "," & strBootTime _
	& "," & CPUNAME & "," & CPUNUM & "," & CPUCORE & "," & strMemory & "," & strCPUPercent & "," & strMemPercent & "," & proSum & "," & strDriversInfo _
	& "," & strIP & "," & strConnect & "," & driverBoolean & "," & strDrivers & "," &  strNTP & "," & KBBoolean & "," & strPort & "," & strLicense
	
	Wscript.echo "We have completed the retrieve.:)"
	
End Function

Function checkLicense(objWMIService) 
	Set colItems = objWMIService.ExecQuery("Select * from SoftwareLicensingProduct Where ProductKeyID like '%-%' and Description like '%Windows%'")
	 For Each objItem in colItems
		
		intGracePeriod = Int(objItem.GracePeriodRemaining / 60)
		Select Case objItem.LicenseStatus

			Case 0 checkLicense= "Unlicensed"

			Case 1 checkLicense= "Licensed"

			Case 2 checkLicense= "Out-Of-Box Grace Period"

			Case 3 checkLicense= "Out-Of-Tolerance Grace Period"

			Case 4 checkLicense= "Non-Genuine Grace Period"

		End Select

Next
End Function

Function CheckParticularHotfix(objWMIService,strHotfixID)
        On Error Resume Next
		Set colQuickFixes = objWMIService.ExecQuery("SELECT * FROM Win32_QuickFixEngineering where HotFixID='KB" & strHotfixID &"'")
		If err.number <> 0 Then 
		    CheckParticularHotfix="Unable to get WMI"
		else
		    tal=colQuickFixes.count
			
			if tal>0 Then
			   CheckParticularHotfix="True"
			else
			    CheckParticularHotfix="FALSE"
			end if
		end if
		Set colQuickFixes=nothing
		Err.Clear
		on Error Goto 0
End Function


Function TimeSpan(dt1, dt2) 
		If (ISDATE(dt1) AND ISDATE(dt2)) = False Then
			TimeSpan = "0" 
			Exit Function
		End If
		seconds = ABS(DATEDIFF("S", dt1, dt2)) 
		days = seconds \ 60 \ 60 \ 24
		TimeSpan = days
	End Function

Function mapDriver()

	Set WshNetwork = WScript.CreateObject("WScript.Network")
	Set oDrives = WshNetwork.EnumNetworkDrives
	Set oPrinters = WshNetwork.EnumPrinterConnections
    strDriver=""
	For i = 0 to oDrives.Count - 1 Step 2
		strDriver="Drive " & oDrives.Item(i) & " = " & oDrives.Item(i+1) &";"& strDriver
	Next
	mapDriver=strDriver
End Function

Function Ping(HostIP,objWMIService)
    For Each objItem in objWMIService.ExecQuery("SELECT * FROM Win32_PingStatus WHERE Address = '" & HostIP & "'") 
        If Not IsObject( objItem ) Then
            Ping = False
        ElseIf objItem.StatusCode = 0 Then
            Ping = True
        Else
            Ping = False
        End If
    Next
End Function
REM 测试172.21.16.66
REM "172.21.16.66 " & Ping( "172.21.16.66" ) & " "
REM 测试网关
Function GetGateway(byref objIPGateway)
    str=""
    For i=0 to ubound(objIPGateway)
        str = str & objIPGateway(i)
	Next
    GetGateway=str
End function


Function GetDriversInfo(fsoobj)
	GetDriversInfo = ""
	Set drvObj = fsoobj.Drives
	For Each D In drvObj
		Err.Clear
		If D.DriveLetter <> "A" Then
			If D.isReady Then
			DiskUse = Round((100*((D.TotalSize-D.FreeSpace)/D.TotalSize)), 0)
			If DiskUse > 30 Then
				GetDriversInfo = GetDriversInfo & D.DriveLetter & " " & DiskUse & "% "
			End If
			End If 
		End If 
	Next 
End Function

'筛选IP地址和子网掩码
'如果IP地址为0.0.0.0,则跳过
'如果IP地址为169.254.x.x,则跳过
'如果子网掩码为255.255.255.0,则改为/24,其它的不变   
Function reg(string1, string2)
    Dim regEx1, regEx2, regEx3, regEx4, retVal, retVa2, retVa3, retVa4
    '正则表达式,初步筛选IP地址
    Set regEx1 = New RegExp
    regEx1.Pattern = "([1-9]?\d|1\d\d|2[0-4]\d|25[0-5])\.([1-9]?\d|1\d\d|2[0-4]\d|25[0-5])\.([1-9]?\d|1\d\d|2[0-4]\d|25[0-5])\.([1-9]?\d|1\d\d|2[0-4]\d|25[0-5])"
    regEx1.IgnoreCase = False
    retVal = regEx1.Test(string1)
    '正则表达式,排除169.254开头的IP地址
    Set regEx2 = New RegExp
    regEx2.Pattern = "^169.254.+"
    regEx2.IgnoreCase = False
    retVa2 = regEx2.Test(string1)
    If retVal and not retVa2 and string1 <> "0.0.0.0" Then
        If string2 = "255.255.255.0" Then
            reg = string1 & "/24"
        Else
            reg = string1 & "/" & string2
        End If
    End If
   
    '提取IP地址与主机名一并定入文件,供生成文件使用
    '正则表达式,筛选172开头的IP地址
    Set regEx3 = New RegExp
    regEx3.Pattern = "^172.+"
    regEx3.IgnoreCase = False
    retVa3 = regEx3.Test(string1)  
    Set regEx4 = New RegExp
    regEx4.Pattern = "^10.+"
    regEx4.IgnoreCase = False
    retVa4 = regEx4.Test(string1) 

    If retVal and not retVa2 and retVa4 Then
        Set objFSO = CreateObject("Scripting.FileSystemObject")
        Set f = objFSO.OpenTextFile("filename.txt",2,true)
        f.write COMPUTERNAME & "_" & string1
        f.close
        Set objFSO = Nothing
    End If
    If retVal and not retVa2 and retVa3 Then
        Set objFSO = CreateObject("Scripting.FileSystemObject")
        Set f = objFSO.OpenTextFile("filename.txt",2,true)
        f.write COMPUTERNAME & "_" & string1
        f.close
        Set objFSO = Nothing
    End If
    
End Function
Function wfl(byref objIP, byref objMASK)
    str=""
    For i=0 to ubound(objIP)
        For j=0 to ubound(objMASK)
        If i = j Then
            str = str & reg(objIP(i), objMASK(i))
        End If
        Next
    Next
    wfl=str
End function


Function UTF8( myFileIn, myFileOut )

    Dim objStream
    Const CdoUTF_8       = "utf-8"

    ' ADODB.Stream file I/O constants
    Const adTypeText            = 2
    Const adSaveCreateOverWrite = 2
    On Error Resume Next
    
    Set objStream = CreateObject( "ADODB.Stream" )
    objStream.Open
    objStream.Type = adTypeText
    objStream.Position = 0
    objStream.Charset = CdoUTF_8
    objStream.LoadFromFile myFileIn
    objStream.SaveToFile myFileOut, adSaveCreateOverWrite
    objStream.Close
    Set objStream = Nothing
    
    If Err Then
        UTF8 = False
    Else
        UTF8 = True
    End If
    
    On Error Goto 0
End Function




