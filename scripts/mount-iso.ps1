[CmdletBinding()] 
Param(
  [Parameter(Mandatory=$false)]
  [string] $DriveLetter,
  [Parameter(Mandatory=$false)]
  [string] $HostShare = 'daas-cache'
)
begin
{
  Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
process
{
  switch ($env:PACKER_BUILDER_TYPE)
  {
    'parallels-iso'
    {
      $PACKER_BUILDER_SHARE="\\psf\$HostShare"
    }
    'virtualbox-iso'
    {
      $PACKER_BUILDER_SHARE="\\vboxsrv\$HostShare"
    }
    'vmware-iso'
    {
      $PACKER_BUILDER_SHARE="\\vmware-host\Shared Folders\$HostShare"
    }
    default
    {
      Throw [System.IO.FileNotFound] "packer_builder", "Unsupported Packer Builder: $($env:PACKER_BUILDER_TYPE)"
    }
  }
  Write-Verbose "Checking $PACKER_BUILDER_SHARE for CIC Installation"
  $InstallISO = Get-ChildItem $PACKER_BUILDER_SHARE -Name -Filter 'CIC_*.iso' | Where { $_ -match '.*R\d+\.iso$' } | Sort -Descending | Select -First 1

  if ([string]::IsNullOrEmpty($InstallISO))
  {
    Throw [System.IO.FileNotFound] "ISO", "Could not find a suitable Interaction Center ISO in $DAAS_SHARE"
  }

  if ([string]::IsNullOrEmpty($DriveLetter))
  {
    Write-Verbose "Searching for the last unused drive letter"
    $DriveLetter = ls function:[d-z]: -n | ?{ !(Test-Path $_) } | Select -Last 1
  }

  Write-Output "Mounting Windows Share on Drive ${DriveLetter}"
  imdisk -a -m $DriveLetter -f (Join-Path $PACKER_BUILDER_SHARE $InstallISO)
  if (! $?) { Throw "Could not mount $PACKER_BUILDER_SHARE on drive $DriveLetter" }

  echo $DriveLetter > $env:USERPROFILE/mounted.info
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
