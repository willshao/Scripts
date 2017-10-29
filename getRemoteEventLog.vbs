SEP_TAG = ", "
PLUS_HOUR = 0
TIME_PER_DAY = 24*10    '每天查询次数
LAST_MINUTES = 6        '每次查询时间长度：分钟

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
TITLE = "getRemoteEventLog"
UUID = "37c9cde31e6e425092a3f19489ee64f1"

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Set objShell = CreateObject("Wscript.Shell")
strPath = Wscript.ScriptFullName
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.GetFile(strPath)
BASE_DIR = objFSO.GetParentFolderName(objFile)
'BASE_DIR = "C:\" & TITLE & "-" & UUID
LOG_FILE = BASE_DIR & "\log.txt"
TMP_BAT = BASE_DIR & "\tmp\tmp.bat"
TMP_OUT = BASE_DIR & "\tmp\tmp-out.txt"
TMP_ERR = BASE_DIR & "\tmp\tmp-err.txt"
PS_PATH = BASE_DIR & "\" & TITLE & ".ps1"
RESTR_RESULT_OK = "((The command completed)|(命令))"

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function InitLog()
    Logfile.WriteBlankLines(2)
    Logfile.WriteLine "************************************************"
    Logfile.WriteLine Now() & " Title: " & TITLE
    Logfile.WriteLine "************************************************"
End Function

Function MyLog(msg)
    'WScript.Echo TITLE & ":: " & msg
    'Logfile.WriteLine TITLE & ":: " & msg
    WScript.Echo msg
    Logfile.WriteLine msg
End Function

Function CheckEnv()
    flag = True
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.fileExists(BASE_DIR & "\" & TITLE & ".vbs") Then
        flag = False
    Else
        If Not fso.FolderExists(BASE_DIR & "\tmp") Then
            fso.createfolder(BASE_DIR & "\tmp")
        End If
        'If fso.fileExists(LOG_FILE) Then
        '    fso.DeleteFile(LOG_FILE), True
        'End If
        If Not fso.FolderExists(BASE_DIR & "\tmp") Then
            flag = False
        End If
    End If
    
    CheckEnv = flag
End Function

Function TearDown()
    If fso.fileExists(TMP_BAT) Then
        fso.DeleteFile(TMP_BAT), True
    End If
End Function

Function CallCmd(cmdStr, tmpOut, tmpErr, checkFlag)
    MyLog "--> Call cmd: '" & cmdStr & "'"
    cmdStr = cmdStr & " 1>""" & tmpOut & """ 2>""" & tmpErr & """"
    'MyMyLog "--> Call cmd: '" & cmdStr & "'"
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    Set tf = fso.CreateTextFile(TMP_BAT, True)
    tf.WriteLine(cmdStr)
    tf.close
    
    Set wss=createobject("wscript.shell")
    wss.run TMP_BAT, 0, True
    WScript.Sleep 1000
    
    If checkFlag Then
        CheckResult tmpOut, TITLE & UUID
        CheckResult tmpErr, TITLE & UUID
    End If
End Function

Function CheckResult(retFile, regOkStr)
    retFlag = False
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set tf = fso.OpenTextFile(retFile, 1, False, 0)
    
    If regOkStr = "" Then
        regOkStr = ".*"
    End If
    Set reRetState = New RegExp
    reRetState.Pattern = regOkStr
    
    MyLog vbTab & "--> Check Result: '" & retFile & "'"
    Do While Not tf.AtEndOfStream
        strLine = tf.ReadLine
        MyLog vbTab & vbTab & "--> " & strLine
        If reRetState.Test(strLine) Then
            retFlag = True
            Exit Do
        End If
    Loop
    tf.Close
    
    CheckResult = retFlag
End Function

Function IsLaterThan2003()
    retFlag = True
    CallCmd "ver", TMP_OUT, TMP_ERR, True
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set tf = fso.OpenTextFile(TMP_OUT, 1, False, 0)
    
    Set reVer2003 = New RegExp
    reVer2003.Pattern = " [1-5]\.\d+\.\d+"
    
    Do While Not tf.AtEndOfStream
        strLine = tf.ReadLine
        If reVer2003.Test(strLine) Then
            retFlag = False
            Exit Do
        End If
    Loop
    tf.Close
    
    IsLaterThan2003 = retFlag
End Function

Function DoWork(arg)
    MyLog "Checking: " & arg
    CallCmd "echo " & arg , TMP_OUT, TMP_ERR, True
    retFlag = CheckResult(TMP_OUT, RESTR_DSMOD_OK)
    If retFlag Then
        MyLog vbTab & samid & vbTab & " => OK"
    Else
        MyLog vbTab & samid & vbTab & " => NOK"
    End If
End Function

Function GetUserListInGroup(localGroupName)
    retStr = ""

    TMP_OUT_LOCAL = TMP_OUT & ".GetUserListInGroup"
    TMP_ERR_LOCAL = TMP_ERR & ".GetUserListInGroup"
    CallCmd "net localgroup """ & localGroupName & """", TMP_OUT_LOCAL, TMP_ERR_LOCAL, True
    retFlag = False
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set tf = fso.OpenTextFile(TMP_OUT_LOCAL, 1, False, 0)
    
    Set reStrLineBegin = New RegExp
    reStrLineBegin.Pattern = "^-+$"
    
    Set reStrLineEnd = New RegExp
    reStrLineEnd.Pattern = RESTR_RESULT_OK
    
    Do While Not tf.AtEndOfStream
        strLine = tf.ReadLine
        If retFlag Then
            If reStrLineEnd.Test(strLine) Then
                Exit Do
            Else
                retStr = retStr & strLine & "; "
            End If
        Else
            If reStrLineBegin.Test(strLine) Then
                retFlag = True
            End If
        End If
    Loop
    tf.Close
    
    Set regEx = New RegExp
    regEx.Pattern = "^(.*);$"
    retStr = Trim(retStr)
    retStr = regEx.Replace(retStr, "$1")
    MyLog "GetUserListInGroup:: " & retStr
    
    GetUserListInGroup = retStr
End Function

Function WMIDateStringToDate(dtmInstallDate)
    WMIDateStringToDate = DateAdd("h", PLUS_HOUR, CDate(Mid(dtmInstallDate, 5, 2) & "/" & _
        Mid(dtmInstallDate, 7, 2) & "/" & Left(dtmInstallDate, 4) _
            & " " & Mid (dtmInstallDate, 9, 2) & ":" & _
                Mid(dtmInstallDate, 11, 2) & ":" & Mid(dtmInstallDate, _
                    13, 2)))
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Main
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

checkFlag = CheckEnv
If Not checkFlag Then
    WScript.Echo "Verify environment failed!"
    WScript.Echo "Make sure your codes in: " & BASE_DIR & ", and have correct permissions."
    WScript.Quit
End If

Set fso = CreateObject("Scripting.FileSystemObject")
Const ForAppending = 8
Set Logfile = fso.OpenTextFile(LOG_FILE, ForAppending, True)

InitLog

Set objArgs = WScript.Arguments
If objArgs.Count <> 4 Then
    MyLog "Usage: cmd <account> <date> <logname> <group>"
    Wscript.Quit
Else
    account = objArgs(0)
    dateNum = objArgs(1)
    logFileName = objArgs(2)
    group = objArgs(3)
End If

groupArray = Split(group, ";")
For each group in groupArray
    group = Trim(group)
    retAccounts = GetUserListInGroup(group)
    If retAccounts <> "" Then
        If account <> "" Then
            account = account & ";"
        End If
        account = account & retAccounts
    End If
Next

verFlag = IsLaterThan2003
If verFlag Then
    MyLog "Version > 2003"
    cmdStr = "powershell " & PS_PATH & " -account '" & account & "' -logname """ & logFileName & """ -date " & dateNum
    CallCmd cmdStr, TMP_OUT, TMP_ERR, True
    Set tf = fso.OpenTextFile(TMP_OUT, 1, False, 0)
    
    Do While Not tf.AtEndOfStream
        strLine = tf.ReadLine
        Wscript.Echo strLine
    Loop
    tf.Close
    Wscript.Quit
End If

strComputer = "." 
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2") 
Set colComputers = objWMIService.ExecQuery("Select * from Win32_ComputerSystem") 
For Each objComputer in colComputers 
    localHostName = objComputer.Name
Next 

strComputer = "."
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" _
    & strComputer & "\root\cimv2")

Set dtmStartDate = CreateObject("WbemScripting.SWbemDateTime")
Set dtmEndDate = CreateObject("WbemScripting.SWbemDateTime")

If dateNum < 0 Then
    queryStr = "Select * from Win32_NTLogEvent Where Logfile = '" & logFileName & "'"
    
    Set reLogonType = New RegExp
    reLogonType.Pattern = "\s*((登录类型:)|(Logon Type:))\s+(\d+)\s*"
    
    Set colLoggedEvents = objWMIService.ExecQuery(queryStr)
    MyLog queryStr
    For Each objEvent in colLoggedEvents
        flag = False
        If account = "" Then
            flag = True
        Else
            accountArray = Split(account, ";")
            For each user in accountArray
                user = Trim(user)
                fullUserName = localHostName & "\" & user
                eventUser = Trim("" & objEvent.User)
                If LCase(eventUser) = LCase(user) Then
                    flag = True
                    Exit For
                ElseIf LCase(eventUser) = LCase(fullUserName) Then
                    flag = True
                    Exit For
                End If
            Next
        End If
        If flag Then
            Set contents = reLogonType.Execute(objEvent.Message)
            If contents.Count > 0 Then
                logonType = contents(0).SubMatches(3)
            Else
                logonType = ""
            End If
            
            Wscript.Echo "Result :: " _
                & objEvent.User & SEP_TAG _
                & WMIDateStringToDate(objEvent.Timegenerated) & SEP_TAG _
                & objEvent.EventCode & SEP_TAG _
                & objEvent.Type & SEP_TAG _
                & objEvent.Category & SEP_TAG _
                & logonType '& SEP_TAG _
                '& objEvent.Logfile & SEP_TAG _
                '& objEvent.ComputerName & SEP_TAG _
                '& objEvent.RecordNumber & SEP_TAG _
                '& objEvent.CategoryString & SEP_TAG _
                '& objEvent.EventIdentifier & SEP_TAG _
                '& objEvent.EventType & SEP_TAG _
                '& objEvent.SourceName & SEP_TAG _
                '& objEvent.Type '& SEP_TAG _
                '& objEvent.Message & SEP_TAG _
        End If
    Next
Else
    startTime = Date - dateNum

    For hourDelta = 1 to TIME_PER_DAY
        dtmStartDate.SetVarDate DateAdd("n", (TIME_PER_DAY-hourDelta)*LAST_MINUTES, startTime), True
        dtmEndDate.SetVarDate DateAdd("n", (TIME_PER_DAY+1-hourDelta)*LAST_MINUTES, startTime), True
    
        queryStr = "Select * from Win32_NTLogEvent Where Logfile = '" _
                & logFileName & "' And TimeWritten >= '" & dtmStartDate _
                & "'" & " and TimeWritten < '" & dtmEndDate & "'" 
    
        Set reLogonType = New RegExp
        reLogonType.Pattern = "\s*((登录类型:)|(Logon Type:))\s+(\d+)\s*"
        
        Set colLoggedEvents = objWMIService.ExecQuery(queryStr)
        MyLog queryStr
        For Each objEvent in colLoggedEvents
            flag = False
            If account = "" Then
                flag = True
            Else
                accountArray = Split(account, ";")
                For each user in accountArray
                    user = Trim(user)
                    fullUserName = localHostName & "\" & user
                    eventUser = Trim("" & objEvent.User)
                    If LCase(eventUser) = LCase(user) Then
                        flag = True
                        Exit For
                    ElseIf LCase(eventUser) = LCase(fullUserName) Then
                        flag = True
                        Exit For
                    End If
                Next
            End If
            If flag Then
                Set contents = reLogonType.Execute(objEvent.Message)
                If contents.Count > 0 Then
                    logonType = contents(0).SubMatches(3)
                Else
                    logonType = ""
                End If
                
                Wscript.Echo "Result :: " _
                    & objEvent.User & SEP_TAG _
                    & WMIDateStringToDate(objEvent.Timegenerated) & SEP_TAG _
                    & objEvent.EventCode & SEP_TAG _
                    & objEvent.Type & SEP_TAG _
                    & objEvent.Category & SEP_TAG _
                    & logonType '& SEP_TAG _
                    '& objEvent.Logfile & SEP_TAG _
                    '& objEvent.ComputerName & SEP_TAG _
                    '& objEvent.RecordNumber & SEP_TAG _
                    '& objEvent.CategoryString & SEP_TAG _
                    '& objEvent.EventIdentifier & SEP_TAG _
                    '& objEvent.EventType & SEP_TAG _
                    '& objEvent.SourceName & SEP_TAG _
                    '& objEvent.Type '& SEP_TAG _
                    '& objEvent.Message & SEP_TAG _
            End If
        Next
    Next
End If

TearDown