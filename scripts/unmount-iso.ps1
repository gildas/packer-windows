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
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
