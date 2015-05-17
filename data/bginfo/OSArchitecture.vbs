' Special BGInfo Script
' OS Architecture v1.5
' Programmed by WindowsStar - Copyright (c) 2009
' ---------------------------------------------------
 
strComputer = "."
On Error Resume Next
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set colSettings = objWMIService.ExecQuery ("Select * from Win32_Processor")
For Each objComputer in colSettings
     If objComputer.Architecture = 0 Then ArchitectureType = "32Bit"
     If objComputer.Architecture = 6 Then ArchitectureType = "Intel Itanium"
     If objComputer.Architecture = 9 Then ArchitectureType = "64Bit"
Next
 
Echo ArchitectureType