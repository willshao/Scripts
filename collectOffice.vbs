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
'========================Start of the script==============================

Dim objXMLDoc,colFiles,objFile,objFolder,objFSO,FileName,NodeLists,componentText
Dim  objShell, objTextFile
Dim strDirectory, strFile, strText,OfficeComponentList,component,IPV4,strIPAdress
Dim list, one,sIPaddress
Dim Componentlist()

Dim KeyComponentsIsEmpty
Dim SKUNode
Dim TNodeContainKeyCom
Dim SubProNameList(9)
Dim SpaceLength

' OpenTextFile Method needs a Const value
' ForAppending = 8 ForReading = 1, ForWriting = 2
Const ForAppending = 8


Const KeyWord0 = "Microsoft"
Const KeyWord1 = "Microsoft Office" 
Const KeyWord2 = "Professional"
Const KeyWord3 = "Standard"
Const KeyWord4 = "Home and Business"
Const KeyWord5 = "365"

Const SubKeyWord1 = "Visio"
Const SubKeyWord2 = "OneNote"
Const SubKeyWord3 = "Access"
Const SubKeyWord4 = "Project"
Const SubKeyWord5 = "Excel"
Const SubKeyWord6 = "OutLook"
Const SubKeyWord7 = "Word"
Const SubKeyWord8 = "Groove"
Const SubKeyWord9 = "Skype"

'Office XML will  be copy to this folder, please change it properly
'strDirectory = "\\IEM\OfficeInfo"
strDirectory = "C:\test"
'File for Storing the Office summary information 
strFile = "OfficeInfoSummary.txt"

Set objXMLDoc = CreateObject("Microsoft.XMLDOM") 
objXMLDoc.async = false
	
'For control file system
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFolder = objFSO.GetFolder(strDirectory)
Set colFiles = objFolder.Files

'loop files and read computer and product name
For Each objFile in colFiles
	'read all XML files
	if UCase(Right(objFile.name,4)) = ".XML" then
		objXMLDoc.load(objFile.Path)
		sComputerName = left(objFile.name,Len(objFile.name)-12)
		
	Set NodeLists = objXMLDoc.selectNodes("//OFFICEINVENTORY/SKU")
	Set IPV4 = objXMLDoc.selectNodes("//OFFICEINVENTORY/IPV4")
	strIPAdress = IPV4(0).attributes(0).text
	Erase SubProNameList
		'if SKU exists
		If NodeLists.length > 1 Then
			Dim k : k =0
			for each SKUNode in NodeLists
				strProductName = SKUNode.attributes(0).text
				if InStr(strProductName,KeyWord1)>0 then
					if InStr(strProductName,KeyWord2)>0 Or InStr(strProductName,KeyWord3)>0 Or InStr(strProductName,KeyWord4)>0 Or InStr(strProductName,KeyWord5)>0 then
						set TNodeContainKeyCom = SKUNode
					end if 
				else 
					if InStr(strProductName,KeyWord0) > 0 then
						if InStr(strProductName,SubKeyWord1)> 0 _ 
							Or InStr(strProductName,SubKeyWord2)> 0 _ 
							Or InStr(strProductName,SubKeyWord3)> 0 _
							Or InStr(strProductName,SubKeyWord4)> 0 _
							Or InStr(strProductName,SubKeyWord5)> 0 _
							Or InStr(strProductName,SubKeyWord6)> 0 _
							Or InStr(strProductName,SubKeyWord7)> 0 _
							Or InStr(strProductName,SubKeyWord8)> 0 _
							Or InStr(strProductName,SubKeyWord9)> 0 then
							
							if InStr(strProductName,KeyWord2) Or InStr(strProductName,KeyWord3) Or InStr(strProductName,KeyWord4) Or InStr(strProductName,KeyWord5) then
								set SubProNameList(k) = SKUNode
								k = k + 1
							else 
								
							end if
						else 
							
						end if				
					else
						
					end if
				end if
			Next
			
			Dim j : j = 1
			if Not IsEmpty(TNodeContainKeyCom) then
				set OfficeComponentList = TNodeContainKeyCom.selectNodes("KeyComponents")
					if(OfficeComponentList(0).childNodes.length >= 1) then
						redim Componentlist(OfficeComponentList(0).childNodes.length)
						for each component in OfficeComponentList(0).childNodes
							if not IsEmpty(component.attributes(0)) then
								Name = component.attributes(0).text
							else
								Name = "broken component"
							end if
							
							if not component.attributes(3) Is nothing then
								version = component.attributes(3).text
							else
								version = "no version details"	
							end if
							
							strName = Space(100) & Name & Space(15) & "version:" & version
							Componentlist(j) = strName
							j = j + 1																	
						Next
						sComputerName = "Computer Name:" & sComputerName
						sIPaddress = Space(35 - Len(sComputerName)) & "IP Address:" & strIPAdress
						sProductname = Space(60 - Len(sIPaddress)) & "Office version:" & TNodeContainKeyCom.getAttribute("ProductName")	
						Componentlist(0) = sComputerName & sIPaddress & sProductname
						strText = "installed"
					
					else
						if ubound(SubProNameList) > 0 then
							redim Componentlist(ubound(SubProNameList))
							for each component in SubProNameList
								if Not IsEmpty(component) then
									if not IsEmpty(component.attributes(0))then
										Name = component.attributes(0).text
									else
										Name = "broken component"
									end if
																		
									strName = Space(100) & Name 
									Componentlist(j) = strName
									j = j + 1	
								end if
								
							Next
							sComputerName = "Computer Name:" & sComputerName
							sIPaddress = Space(35 - Len(sComputerName)) & "IP Address:" & strIPAdress
							sProductname = Space(56 - Len(sIPaddress)) & "Office version:" & TNodeContainKeyCom.getAttribute("ProductName")	
							Componentlist(0) = sComputerName & sIPaddress & sProductname
							strText = "installed"
						end if 	
					end if
			else 
				if ubound(SubProNameList) > 0 then
					redim Componentlist(ubound(SubProNameList))
					for each component in SubProNameList
						if Not IsEmpty(component) then
							if not IsEmpty(component.attributes(0))then
								Name = component.attributes(0).text
							else
								Name = "broken component"
							end if
														
							strName = Space(100) & Name
							Componentlist(j) = strName
							j = j + 1	
						end if
						
					Next
						sComputerName = "Computer Name:" & sComputerName
						sIPaddress = Space(35 - Len(sComputerName)) & "IP Address:" & strIPAdress
						sProductname = Space(80 - Len(sIPaddress)) & "Office version:" & SubProNameList.getAttribute("ProductName")	
						Componentlist(0) = sComputerName & sIPaddress & sProductname
						strText = "installed"
				end if 	
			end if
		else
			sComputerName = "Computer Name:" & sComputerName
			sIPaddress = Space(35 - Len(sComputerName)) & "IP Address:" & strIPAdress
			sProductname = Space(24) & "Office version: None"
			strText = sComputerName & sIPaddress & sProductname
		end if 
		
	
	'insert Data to TXT file 
	'===============================
	' Check that the strDirectory folder exists
		If objFSO.FolderExists(strDirectory) Then
		   Set objFolder = objFSO.GetFolder(strDirectory)
		Else
		   Set objFolder = objFSO.CreateFolder(strDirectory)
		   'WScript.Echo "Just created " & strDirectory
		End If

		If objFSO.FileExists(strDirectory & "\" & strFile) Then
		   Set objFolder = objFSO.GetFolder(strDirectory)
		Else
		   Set objFile = objFSO.CreateTextFile(strDirectory & "\" & strFile)
		   'Wscript.Echo "Just created " & strDirectory & "\" & strFile
		End If 

		set objFile = nothing
		set objFolder = nothing
	
		Set objTextFile = objFSO.OpenTextFile(strDirectory & "\" & strFile, ForAppending, True)
		'insert data every time you run this VBScript
		
		if strText = "installed" then
			for each strone in Componentlist
				objTextFile.writeline(strone)
			Next
		else
			objTextFile.WriteLine(strText)
		end if 
		
		'for each one in list 
		'	objTextFile.writeline(componentText)
		'Next
		
		sComputerName = ""
		sProductname = ""
		Erase Componentlist
		
		objTextFile.close

		'Next'For Each objNode in colNodes
	
	End if'filter XML files
Next'loop files 

if not IsEmpty(objTextFile) then
objTextFile.Close
end if

WScript.Quit
