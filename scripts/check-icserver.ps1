<# # Documentation {{{
  .Synopsis
  Installs CIC
#> # }}}
[CmdletBinding()] 
Param(
  [Parameter(Mandatory=$false)][string] $User          = 'vagrant',
  [Parameter(Mandatory=$false)][string] $Password      = 'vagrant',
  [Parameter(Mandatory=$false)][string] $InstallPath   = 'C:\I3\IC',
  [Parameter(Mandatory=$false)][string] $InstallSource,
  [Parameter(Mandatory=$false)][switch] $Reboot
)

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

Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Now = Get-Date -Format 'yyyyMMddHHmmss'

$Product = 'Interaction Center Server'

$MSI_available=Test-MSIExecMutex -MsiExecWaitTime $(New-TimeSpan -Minutes 5)
if (-not $MSI_available)
{
  Write-Output "IC Server installation is not finished yet. This is bad news..."
  return 1618
}

if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "${Product}.*")
{
  Write-Output "$Product is installed"
}
else
{
  #TODO: Should we return values or raise exceptions?
  Write-Output "Failed to install $Product"
  return -2
}
Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
