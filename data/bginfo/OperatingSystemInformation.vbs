' Special BGInfo Script
' Operating System Information v1.3
' Programmed by WindowsStar - Copyright (c) 2009-2010
' --------------------------------------------------------
 
strComputer = "."
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
 
Set colOperatingSystems = objWMIService.ExecQuery ("Select * from Win32_OperatingSystem")
 
For Each objOperatingSystem in colOperatingSystems
    OSCaption = Trim(Replace(objOperatingSystem.Caption,"Microsoft ",""))
    OSCaption = Replace(OSCaption,"Microsoft","")
    OSCaption = Replace(OSCaption,"(R)","")
    OSCaption = Trim(Replace(OSCaption,",",""))
    Echo OSCaption
Next