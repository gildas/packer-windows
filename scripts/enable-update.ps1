$mgr = New-Object -ComObject Microsoft.Update.ServiceManager -Strict
$mgr.ClientApplicationID = "packer"
$mgr.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")
