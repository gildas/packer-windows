<# # Documentation {{{
  .Synopsis
  Installs CIC
#> # }}}
[CmdletBinding()] 
Param(
  [Parameter(Mandatory=$false)]
  [int] $RunningMsiAllowed = 1,
  [Parameter(Mandatory=$false)]
  [int] $Sleep = 10
)
begin
{
  Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  $Product = 'Interaction Center Server'
}
process
{
  function Show-Elapsed([Diagnostics.StopWatch] $watch) # {{{
  {
    $elapsed = ''
        if ($watch.Elapsed.Days    -gt 1) { $elapsed += " $($watch.Elapsed.Days) days" }
    elseif ($watch.Elapsed.Days    -gt 0) { $elapsed += " $($watch.Elapsed.Days) day"  }
        if ($watch.Elapsed.Hours   -gt 1) { $elapsed += " $($watch.Elapsed.Hours) hours" }
    elseif ($watch.Elapsed.Hours   -gt 0) { $elapsed += " $($watch.Elapsed.Hours) hour"  }
        if ($watch.Elapsed.Minutes -gt 1) { $elapsed += " $($watch.Elapsed.Minutes) minutes" }
    elseif ($watch.Elapsed.Minutes -gt 0) { $elapsed += " $($watch.Elapsed.Minutes) minute"  }
        if ($watch.Elapsed.Seconds -gt 0) { $elapsed += " $($watch.Elapsed.Seconds) seconds" }
    return $elapsed
  } # }}}

function Test-MsiExecMutex # {{{
{
<# {{{2
    .SYNOPSIS
        Wait, up to a timeout, for the MSI installer service to become free.
    .DESCRIPTION
        The _MSIExecute mutex is used by the MSI installer service to serialize installations
        and prevent multiple MSI based installations happening at the same time.
        Wait, up to a timeout (default is 10 minutes), for the MSI installer service to become free
        by checking to see if the MSI mutex, "Global\\_MSIExecute", is available.
        Thanks to: https://psappdeploytoolkit.codeplex.com/discussions/554673
    .PARAMETER MsiExecWaitTime
        The length of time to wait for the MSI installer service to become available.
        This variable must be specified as a [timespan] variable type using the [New-TimeSpan] cmdlet.
        Example of specifying a [timespan] variable type: New-TimeSpan -Minutes 5
    .OUTPUTS
        Returns true for a successful wait, when the installer service has become free.
        Returns false when waiting for the installer service to become free has exceeded the timeout.
    .EXAMPLE
        Test-MsiExecMutex
    .EXAMPLE
        Test-MsiExecMutex -MsiExecWaitTime $(New-TimeSpan -Minutes 5)
    .EXAMPLE
        Test-MsiExecMutex -MsiExecWaitTime $(New-TimeSpan -Seconds 60)
    .LINK
        http://msdn.microsoft.com/en-us/library/aa372909(VS.85).aspx
#> # }}}2
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [timespan]$MsiExecWaitTime = $(New-TimeSpan -Minutes 10)
    )
    
    Begin
    {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters

        Write-Verbose "Function Start"
        if (-not [string]::IsNullOrEmpty($PSParameters))
        {
            Write-Verbose "Function invoked with bound parameters [$PSParameters]"
        }
        else
        {
            Write-Verbose "Function invoked without any bound parameters"
        }

        $IsMsiExecFreeSource = @"
        using System;
        using System.Threading;
        public class MsiExec
        {
            public static bool IsMsiExecFree(TimeSpan maxWaitTime)
            {
                /// <summary>
                /// Wait (up to a timeout) for the MSI installer service to become free.
                /// </summary>
                /// <returns>
                /// Returns true for a successful wait, when the installer service has become free.
                /// Returns false when waiting for the installer service has exceeded the timeout.
                /// </returns>

                // The _MSIExecute mutex is used by the MSI installer service to serialize installations
                // and prevent multiple MSI based installations happening at the same time.
                // For more info: http://msdn.microsoft.com/en-us/library/aa372909(VS.85).aspx
                const string installerServiceMutexName = "Global\\_MSIExecute";
                Mutex MSIExecuteMutex = null;
                var isMsiExecFree = false;

                try
                {
                    MSIExecuteMutex = Mutex.OpenExisting(installerServiceMutexName,
                                    System.Security.AccessControl.MutexRights.Synchronize);
                    isMsiExecFree = MSIExecuteMutex.WaitOne(maxWaitTime, false);
                }
                catch (WaitHandleCannotBeOpenedException)
                {
                    // Mutex doesn't exist, do nothing
                    isMsiExecFree = true;
                }
                catch (ObjectDisposedException)
                {
                    // Mutex was disposed between opening it and attempting to wait on it, do nothing
                    isMsiExecFree = true;
                }
                finally
                {
                    if (MSIExecuteMutex != null && isMsiExecFree)
                    MSIExecuteMutex.ReleaseMutex();
                }
                
                return isMsiExecFree;
            }
        }
"@

        If (-not ([System.Management.Automation.PSTypeName]'MsiExec').Type)
        {
            Add-Type -TypeDefinition $IsMsiExecFreeSource -Language CSharp
        }
    }
    Process
    {
        Try
        {
            If ($MsiExecWaitTime.TotalMinutes -gt 0)
            {
                [string]$WaitLogMsg = "$($MsiExecWaitTime.TotalMinutes) minutes"
            }
            Else
            {
                [string]$WaitLogMsg = "$($MsiExecWaitTime.TotalSeconds) seconds"
            }
            Write-Verbose "Check to see if the MSI installer service is available. Wait up to [$WaitLogMsg] for the installer service to become available."
            [boolean]$IsMsiExecInstallFree = [MsiExec]::IsMsiExecFree($MsiExecWaitTime)

            If ($IsMsiExecInstallFree)
            {
                Write-Verbose "The MSI installer service is available to start a new installation."
            }
            Else
            {
                Write-Verbose "The MSI installer service is not available because another installation is already in progress."
            }
            Return $IsMsiExecInstallFree
        }
        Catch
        {
            Write-Verbose "There was an error while attempting to check if the MSI installer service is available"
        }
    }
    End
    {
        Write-Verbose "Function End"
    }
} # }}}

  try
  {
#$MSI_available=Test-MSIExecMutex -MsiExecWaitTime $(New-TimeSpan -Minutes 5)
#if (-not $MSI_available)
#{
#  Write-Output "IC Server installation is not finished yet. This is bad news..."
#  exit 1618
#}

    $watch = [Diagnostics.StopWatch]::StartNew()
    do
    {
      Start-Sleep $Sleep
      $msiexec_count = @(Get-Process | where ProcessName -eq 'msiexec').Count
      $elapsed = Show-Elapsed($watch)
      Write-Output "Found ${msiexec_count} MSI installers running after $elapsed"
    }
    while ($msiexec_count -gt $RunningMsiAllowed)
    $watch.Stop()
    $elapsed = Show-Elapsed($watch)
    Write-Output "No more MSI installers running after $elapsed"

    if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "${Product}.*")
    {
      Write-Output "$Product is installed"
    }
    else
    {
      Write-Output "Failed to install $Product"
Write-Output "Manually backing up logs"

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

  $log_dir = (Join-Path $log_dir "${env:PACKER_BUILDER_TYPE}-${env:PACKER_BUILD_NAME}-$(Get-Date -Format 'yyyyMMddHHmmss')")
  if (! (Test-Path $log_dir)) { New-Item -ItemType Directory -Path $log_dir -ErrorAction Stop | Out-Null }

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
      #Write-Output "Backing up logs"
      #Backup-Logs.ps1
      exit 2
    }
  }
  finally
  {
    Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Start-Sleep 2
  }
}
