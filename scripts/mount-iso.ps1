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
    Throw [System.IO.FileNotFound] "ISO", "Could not find a suitable Interaction Center ISO in $DAAS_SHARE"
    exit 2
  }

  if ([string]::IsNullOrEmpty($DriveLetter))
  {
    Write-Verbose "Searching for the last unused drive letter"
    $DriveLetter = ls function:[d-z]: -n | ?{ !(Test-Path $_) } | Select -Last 1
  }

  Write-Output "Mounting Windows Share on Drive ${DriveLetter}"
  if ($PSCmdlet.ShouldProcess($DriveLetter, "Mounting ${PACKER_BUILDER_SHARE}\${InstallISO}"))
  {
    imdisk -a -m $DriveLetter -f (Join-Path $PACKER_BUILDER_SHARE $InstallISO)
    if (! $?)
    {
      Throw "Could not mount $PACKER_BUILDER_SHARE on drive $DriveLetter"
      exit 3
    }

    echo $DriveLetter > $env:USERPROFILE/mounted.info
  }
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
