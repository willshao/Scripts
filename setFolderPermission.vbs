'=======================================================================
'Just for case 117121217306664----Modify the Folder Path C:\Newv and set everyone has permissions to
' full control this folder
'version: 1.0.0.1
'author: wshao
' Add- Popup Error details 
'=======================================================================
'      Microsoft provides programming examples for illustration only, 
'      without warranty either expressed or implied, including, but 
'      not limited to, the implied warranties of merchantability 
'      and/or fitness for a particular purpose. It is assumeed 
'      that you are familiar with the programming language being 
'      demonstrated and the tools used to create and debug procedures. 
'      Microsoft support professionals can help explain the functionality 
'      of a particular procedure, but they will not modify these examples 
'      to provide added functionality or construct procedures to meet your 
'      specific needs. If you have limited programming experience, you may 
'      want to contact a Microsoft Certified Partner or the Microsoft fee-based 
'      consulting line at (800) 936-5200. For more information about Microsoft 
'      Certified Partners, please visit the following Microsoft Web site: 
'      http://www.microsoft.com/partner/referral/
'
'========================Start of the script=========================

Sub ChangeFolderPermission (strDirectory, strUser )
	Dim intRunError,setPerms
	Set WshShell = CreateObject("WScript.Shell")
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	
	If objFSO.FolderExists(strDirectory)=False  Then
		Set objFolder = objFSO.CreateFolder(strDirectory)	 
	end if
	
	If objFSO.FolderExists(strDirectory) Then
		setPerms = "%COMSPEC% /c echo Y| C:\windows\system32\cacls.exe " & Chr(34) & strDirectory & Chr(34) & " /E /G " & strUser & ":F /T"	
		'Wscript.Echo setPerms
		intRunError =WshShell.run(setPerms,2,True)	
		if intRunError<>0 then
			Wscript.Echo "Assigning permissions for user " & strUser & " to spicfy folder " & strDirectory & " ERROR msg " & intRunError		
		end if
	end if
	
	set WshShell = nothing
	set objFSO = nothing
End Sub

call ChangeFolderPermission ("C:\Newv", "everyone" )
