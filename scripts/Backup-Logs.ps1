[CmdletBinding(SupportsShouldProcess=$true)] 
Param(
)
begin
{
  Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
process
{
  if (Test-Path $env:USERPROFILE/share-log.info)
  {
    $ShareArgs = @{ PSProvider = 'FileSystem'; ErrorAction = 'Stop' }
    $ShareInfo = Get-Content $env:USERPROFILE/share-log.info -Raw | ConvertFrom-Json

    if ($ShareInfo.DriveLetter -ne $null)
    {
      if ($ShareInfo.User -ne $null)
      {
        if ($ShareInfo.Password -eq $null)
        {
          Throw "No password for $($ShareInfo.User) in $($env:USERPROFILE)/share-log.info"
          exit 1
        }
        $ShareArgs['Credential'] = New-Object System.Management.Automation.PSCredential($ShareInfo.User, (ConvertTo-SecureString -String $ShareInfo.Password -AsPlainText -Force))
      }
      $Drive   = New-PSDrive -Name $ShareInfo.DriveLetter -Root $ShareInfo.Path @ShareArgs
      $log_dir = $Drive.Root
    }
    else
    {
      $log_dir = $ShareInfo.Path
    }
    Write-Output "Using Share at $log_dir"
  }
  else
  {
    Write-Output "Share log information was not found"
    Write-Warning "No log will be backed up"
    Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    exit
  }
  if ([string]::IsNullOrEmpty($log_dir))
  {
    Throw "No share to use from $($env:USERPROFILE)/share-log.info"
    exit 2
  }

  While (! (Test-Path $log_dir))
  {
    Write-Output "Waiting for shares to be available"
    Start-Sleep 20
  }
  $log_dir = Join-Path $log_dir "${env:PACKER_BUILDER_TYPE}-${env:PACKER_BUILD_NAME}-$(Get-Date -Format 'yyyyMMddHHmmss')"
  if (! (Test-Path $log_dir)) { New-Item -ItemType Directory -Path $log_dir -ErrorAction Stop | Out-Null }

  Write-Output "Backing up logs in $log_dir"
  if (Test-Path "C:\ProgramData\chocolatey\logs\chocolatey.log")
  {
    if ($PSCmdlet.ShouldProcess("chocolatey.log", "Backing up"))
    {
      Copy-Item C:\ProgramData\chocolatey\logs\chocolatey.log $log_dir
    }
  }

  Get-ChildItem "C:\Windows\Logs\*.log" | ForEach {
    if ($PSCmdlet.ShouldProcess((Split-Path $_ -Leaf), "Backing up"))
    {
      Copy-Item $_ $log_dir
    }
  }

  Get-ChildItem "C:\Windows\Logs\*.txt" | ForEach {
    if ($PSCmdlet.ShouldProcess((Split-Path $_ -Leaf), "Backing up"))
    {
      Copy-Item $_ $log_dir
    }
  }

  Start-Sleep 5
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
