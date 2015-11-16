[CmdletBinding()] 
Param(
  [Parameter(Mandatory=$false)]
  [string] $DriveLetter
)
begin
{
  Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
process
{
  if ([string]::IsNullOrEmpty($DriveLetter))
  {
    if (Test-Path $env:USERPROFILE/mounted.info)
    {
      $DriveLetter = Get-Content $env:USERPROFILE/mounted.info
      Remove-Item $env:USERPROFILE/mounted.info
    }
    else
    {
      Write-Output "No drive was mounted"
      Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      exit
    }
  }

  Write-Output "Unmounting drive $DriveLetter"
  imdisk -d -m $DriveLetter

  switch ($env:PACKER_BUILDER_TYPE)
  {
    'hyperv-iso'
    {
      if ([string]::IsNullOrEmpty($env:SMBHOST))  { Write-Error "Environment variable SMBHOST is empty"  ; exit 1 }
      if ([string]::IsNullOrEmpty($env:SMBSHARE)) { Write-Error "Environment variable SMBSHARE is empty" ; exit 1 }
      if ([string]::IsNullOrEmpty($env:SMBUSER))  { Write-Error "Environment variable SMBUSER is empty"  ; exit 1 }
      if ([string]::IsNullOrEmpty($env:SMBPASS))  { Write-Error "Environment variable SMBPASS is empty"  ; exit 1 }
      Write-Output "Unmounting $($env:SMBSHARE) from $($env:SMBHOST)"
      Get-PSDrive | Where Root -eq "\\${env:SMBHOST}\${env:SMBSHARE}" | Select -ExpandProperty Name | Remove-PSDrive
    }
  }
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
