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
  # TODO: Use $HostShare
  if (Test-Path $env:USERPROFILE/share-daas-cache.info)
  {
    $ShareArgs = @{ PSProvider = 'FileSystem'; ErrorAction = 'Stop' }
    $ShareInfo = Get-Content $env:USERPROFILE/share-daas-cache.info -Raw | ConvertFrom-Json

    if ($ShareInfo.DriveLetter -ne $null)
    {
      if ($ShareInfo.User -ne $null)
      {
        if ($ShareInfo.Password -eq $null)
        {
          Throw "No password for $($ShareInfo.User) in $($env:USERPROFILE)/share-daas-cache.info"
          exit 1
        }
        $ShareArgs['Credential'] = New-Object System.Management.Automation.PSCredential($ShareInfo.User, (ConvertTo-SecureString -String $ShareInfo.Password -AsPlainText -Force))
      }
      $Drive     = New-PSDrive -Name $ShareInfo.DriveLetter -Root $ShareInfo.Path @ShareArgs -Persist -Scope Global
      $share_dir = $Drive.Root
    }
    else
    {
      $share_dir = $ShareInfo.Path
    }
    Write-Output "Using Share at $share_dir"
  }
  else
  {
    Write-Output "Share daas-cache information was not found"
    Write-Warning "No iso can be mounted"
    Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    exit
  }
  if ([string]::IsNullOrEmpty($share_dir))
  {
    Throw "No share to use from $($env:USERPROFILE)/share-daas-cache.info"
    exit 2
  }

  $pattern = ".*${Product}_"
  if ($PSBoundParameters.ContainsKey('Version'))   { $pattern += "${Version}"     } else { $pattern += '\d{4}' }
  if ($PSBoundParameters.ContainsKey('Release'))   { $pattern += "_R${Release}"   } else { $pattern += '_R\d+' }
  if ($LastPatch)                                  { $pattern += '_Patch\d+'      }
  elseif ($PSBoundParameters.ContainsKey('Patch'))
  {
    if ($Patch -eq 9999) { $pattern += '_Patch\d+' } else { $pattern += "_Patch${Patch}" }
  }
  $pattern += '\.iso$'
  Write-Verbose "Checking $share_dir for $Product Installation (Version: $Version, Release: $Release, Patch: $Patch)"
  Write-Verbose "Pattern: $pattern"
  $InstallISO = Get-ChildItem $share_dir -Name -Filter "${Product}_*.iso" | Where { $_ -match $pattern } | Sort -Descending | Select -First 1

  if ([string]::IsNullOrEmpty($InstallISO))
  {
    if ($LastPatch)
    {
      Write-Output "There is no patch available for Interaction Center in $share_dir"
      Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      exit 0
    }
    else
    {
      Throw "Could not find a suitable Interaction Center ISO in $share_dir"
      Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      exit 2
    }
  }
  Write-Verbose "Found: $InstallISO"

  While (! (Test-Path $share_dir))
  {
    Write-Output "Waiting for shars to be available"
    Start-Sleep 20
  }

  if ([string]::IsNullOrEmpty($DriveLetter))
  {
    Write-Verbose "Searching for the last unused drive letter"
    $DriveLetter = ls function:[D-T]: -n | ?{ !(Test-Path $_) } | Select -Last 1
  }

  Write-Output "Mounting Windows Share on Drive ${DriveLetter}"
  if ($PSCmdlet.ShouldProcess($DriveLetter, "Mounting ${share_dir}\${InstallISO}"))
  {
    imdisk -a -m $DriveLetter -f (Join-Path $share_dir $InstallISO)
    if (! $?)
    {
      Throw "Could not mount $share_dir on drive $DriveLetter"
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
