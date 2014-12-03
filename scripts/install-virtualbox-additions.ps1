$disk  = Mount-DiskImage C:\Users\vagrant\VBoxGuestAdditions.iso
if ($? -ne 0) { Write-Error "ERROR %ERRORLEVEL% while adding Oracle certificate to the trusted publishers" }
$drive = $disk.DriveLetter

certutil -addstore -f "TrustedPublisher" ${drive}\cert\oracle-vbox.cer
if ($? -ne 0) { Write-Error "ERROR %ERRORLEVEL% while adding Oracle certificate to the trusted publishers" }

${drive}:\VBoxWindowsAdditions.exe /S
if { $? -ne 0) { Write-Error "ERROR %ERRORLEVEL% while installing Virtualbox Guest Additions" }
Dismount-DiskImage $disk.ImagePath
