[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')] 
Param(
  [Parameter(Mandatory=$false)]
  [string] $DriveLetter,
  [Parameter(Mandatory=$false)]
  [string] $HostShare = 'daas-cache',
  [Parameter(Mandatory=$false)]
  [string] $Product='CIC',
  [Parameter(Mandatory=$false)]
  [int] $Version,
  [Parameter(Mandatory=$false)]
  [int] $Release,
  [Parameter(Mandatory=$false)]
  [int] $Patch,
  [Parameter(Mandatory=$false)]
  [switch] $LastPatch
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
    'hyperv-iso'
    {
      if ([string]::IsNullOrEmpty($env:SMBHOST))  { Write-Error "Environment variable SMBHOST is empty"  ; exit 1 }
      if ([string]::IsNullOrEmpty($env:SMBSHARE)) { Write-Error "Environment variable SMBSHARE is empty" ; exit 1 }
      if ([string]::IsNullOrEmpty($env:SMBUSER))  { Write-Error "Environment variable SMBUSER is empty"  ; exit 1 }
      if ([string]::IsNullOrEmpty($env:SMBPASS))  { Write-Error "Environment variable SMBPASS is empty"  ; exit 1 }
      $ShareDriveLetter = ls function:[D-Z]: -n | ?{ !(Test-Path $_) } | Select -Last 1
      Write-Output "Mounting $($env:SMBSHARE) from $($env:SMBHOST) on $ShareDriveLetter as $($env:SMBUSER)"
      $ShareDrive = New-PSDrive -Name $ShareDriveLetter.Substring(0,1) -PSProvider FileSystem -Root \\${env:SMBHOST}\${env:SMBSHARE} -Persist -Scope Global -Credential (New-Object System.Management.Automation.PSCredential("${env:SMBHOST}\${env:SMBUSER}", ($env:SMBPASS | ConvertTo-SecureString -AsPlainText -Force)))
      $PACKER_BUILDER_SHARE = $ShareDriveLetter
    }
    default
    {
      Throw [System.IO.FileNotFound] "packer_builder", "Unsupported Packer Builder: $($env:PACKER_BUILDER_TYPE)"
      exit 1
    }
  }
  $pattern = ".*${Product}_"
  if ($PSBoundParameters.ContainsKey('Version'))   { $pattern += "${Version}"     } else { $pattern += '\d{4}' }
  if ($PSBoundParameters.ContainsKey('Release'))   { $pattern += "_R${Release}"   } else { $pattern += '_R\d+' }
  if ($LastPatch)                                  { $pattern += '_Patch\d+'      }
  elseif ($PSBoundParameters.ContainsKey('Patch')) { $pattern += "_Patch${Patch}" }
  $pattern += '\.iso$'
  Write-Verbose "Checking $PACKER_BUILDER_SHARE for $Product Installation (Version: $Version, Release: $Release, Patch: $Patch)"
  Write-Verbose "Pattern: $pattern"
  $InstallISO = Get-ChildItem $PACKER_BUILDER_SHARE -Name -Filter "${Product}_*.iso" | Where { $_ -match $pattern } | Sort -Descending | Select -First 1

  if ([string]::IsNullOrEmpty($InstallISO))
  {
    if ($LastPatch)
    {
      Write-Output "There is no patch available for Interaction Center in $DAAS_SHARE"
      Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      exit 0
    }
    else
    {
      Throw "Could not find a suitable Interaction Center ISO in $DAAS_SHARE"
      Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      exit 2
    }
  }
  Write-Verbose "Found: $InstallISO"

  if ([string]::IsNullOrEmpty($DriveLetter))
  {
    Write-Verbose "Searching for the last unused drive letter"
    $DriveLetter = ls function:[D-Z]: -n | ?{ !(Test-Path $_) } | Select -Last 1
  }

  Write-Output "Mounting Windows Share on Drive ${DriveLetter}"
  if ($PSCmdlet.ShouldProcess($DriveLetter, "Mounting ${PACKER_BUILDER_SHARE}\${InstallISO}"))
  {
    imdisk -a -m $DriveLetter -f (Join-Path $PACKER_BUILDER_SHARE $InstallISO)
    if (! $?)
    {
      Throw "Could not mount $PACKER_BUILDER_SHARE on drive $DriveLetter"
      Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      exit 3
    }

    echo $DriveLetter > $env:USERPROFILE/mounted.info
  }
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
