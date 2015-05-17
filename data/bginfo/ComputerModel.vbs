winmgt = "winmgmts:{impersonationLevel=impersonate}!//"

Set oWMI_Qeury_Result = GetObject(winmgt).InstancesOf("Win32_ComputerSystem")


For Each oItem In oWMI_Qeury_Result
 Set oComputer = oItem
Next


If IsNull(oComputer.Model) Then
  sComputerModel = "*no-name* model"
Else
  If LCase(oComputer.Model) = "system product name" Then
    sComputerModel =  "Custom-built PC"
  Else
    sComputerModel =  oComputer.Model
  End If
End If

If IsNull(oComputer.Manufacturer) Then
  sComputerManufacturer = "*no-name* manufacturer"
Else
  If LCase(oComputer.Manufacturer) = "system manufacturer" Then
    sComputerManufacturer =  "some assembler"
  Else
    sComputerManufacturer =  oComputer.Manufacturer
  End If
End If


sComputer = Trim(sComputerModel) & " by " & Trim(sComputerManufacturer)

Echo sComputer