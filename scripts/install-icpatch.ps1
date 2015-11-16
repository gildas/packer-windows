<# # Documentation {{{
  .Synopsis
  Installs CIC
#> # }}}
[CmdletBinding(SupportsShouldProcess=$true)]
Param(
  [Parameter(Mandatory=$false)]
  [ValidateNotNullOrEmpty()]
  [string] $SourceDriveLetter,
  [Parameter(Mandatory=$false)]
  [ValidateNotNullOrEmpty()]
  [Alias('Product')]
  [string] $ProductName,
  [Parameter(Mandatory=$false)]
  [switch] $AsJob,
  [Parameter(Mandatory=$false)]
  [ValidateNotNullOrEmpty()]
  [string] $JobName,
  [Parameter(Mandatory=$false)]
  [switch] $Reboot
)
begin
{
  Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  $Now = Get-Date -Format 'yyyyMMddHHmmss'
  $product_key = "HKLM:\SOFTWARE\Wow6432Node\Interactive Intelligence\Installed\Products\*"
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

# Prerequisites: {{{
# Prerequisite: Powershell 3 {{{2
  if($PSVersionTable.PSVersion.Major -lt 3)
  {
      Write-Error "Powershell version 3 or more recent is required"
      Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      Start-Sleep 2
      exit 1
  }
# 2}}}

# Prerequisite: Find the source! {{{2
  if ([string]::IsNullOrEmpty($SourceDriveLetter))
  {
    if (Test-Path $env:USERPROFILE/mounted.info)
    {
      $SourceDriveLetter = Get-Content $env:USERPROFILE/mounted.info
    }
    else
    {
      $SourceDriveLetter = ls function:[d-z]: -n | ?{ Test-Path "$_\Installs\ServerComponents" } | Select -First 1
      if ([string]::IsNullOrEmpty($SourceDriveLetter))
      {
        Write-Output "No drive containing patches for $Product was mounted"
        Write-Output "No action will be taken"
        exit 0
      }
    }
  }
  Write-Verbose "Patches will be run from $SourceDriveLetter"
# 2}}}
# Prerequisites }}}

  $want_reboot = $false
  if ($PSBoundParameters.ContainsKey('ProductName'))
  {
    $products = Get-ItemProperty $product_key | Where { $_.ProductName -like "*${ProductName}*" }
  }
  else
  {
    $products = Get-ItemProperty $product_key | Where { $_.ProductName -ne $null }
  }
  $jobs = @()
  $products | ForEach {
    Write-Output "Checking $($_.ProductName)"

    if ($product_info = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -eq $_.ProductName)
    {
      Write-Output "  version $($product_info.DisplayVersion) is installed"
    }
    elseif ($product_info = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -eq $_.ProductName)
    {
      Write-Output "  version $($product_info.DisplayVersion) is installed"
    }
    else
    {
      Write-Error "$Product is not installed properly, aborting."
      return # aka continue (We are in a foreack ScriptBlock!)
    }

         if ($_.ProductName -match '^Interaction Center Server.*') { $msi_prefix = 'icserver'}
    elseif  ($_.ProductName -match '^Interaction Firmware.*')      { $msi_prefix = 'InteractionFirmware' }
    else
    {
      Write-Error "Patching $($_.ProductName) is not yet supported. Please report this to the DaaS team"
      return # aka continue (We are in a foreack ScriptBlock!)
    }
    Write-Verbose " MSI Prefix: $msi_prefix"

    $InstallSource = (Get-ChildItem -Path "${SourceDriveLetter}\Installs\ServerComponents" -Filter "${msi_prefix}_*.msp").FullName
    if ([string]::IsNullOrEmpty($InstallSource) -or ! (Test-Path $InstallSource))
    {
      Write-Error "$Product Patch not found in $SourceDriveLetter"
      return # aka continue (We are in a foreack ScriptBlock!)
    }

    if ($InstallSource -match '.*Patch([0-9]+)\.msp') { $Patch = $matches[1] }
    if ((Split-Path $InstallSource -Leaf) -le "${msi_prefix}_$($_.SU).msp")
    {
      Write-Output "  already patched to $($_.SU) (Patch $Patch)"
      return # aka continue (We are in a foreack ScriptBlock!)
    }
    Write-Output  "Patching $($_.ProductName) to Patch $Patch..."
    Write-Verbose "  from $InstallSource"
    $Log = "C:\Windows\Logs\${msi_prefix}-patch-${Now}.log"
    $parms  = '/update',"${InstallSource}"
    $parms += 'STARTEDBYEXEORIUPDATE=1'
    $parms += 'REBOOT=ReallySuppress'
    $parms += '/l*v'
    $parms += $Log
    $parms += '/qn'
    $parms += '/norestart'
    Write-Verbose "Arguments: $($parms -join ',')"

    if ($PSCmdlet.ShouldProcess($_.ProductName, "Running msiexec /update"))
    {
      if ($AsJob)
      {
        #$job_parms = @{}
        #if (! [string]::IsNullOrEmpty($JobName)) { $job_parms['Name'] = $JobName }
        #$job = Start-Job @job_parms -ScriptBlock { &msiexec.exe $args } -ArgumentList $parms
        #Write-Verbose "Job Created: $Job"
        #$jobs += $job
        $process = Start-Process -FilePath msiexec -ArgumentList $parms -PassThru
        Write-Output "$Product is pactching (process: $($process.Id))"
      }
      else
      {
        $watch   = [Diagnostics.StopWatch]::StartNew()
        $process = Start-Process -FilePath msiexec -ArgumentList $parms -Wait -PassThru
        $watch.Stop()
        $elapsed = Show-Elapsed($watch)

        if ($process.ExitCode -eq 0)
        {
          Write-Output "$Product patched successfully in $elapsed!"
          $exit_code = 0
        }
        elseif ($process.ExitCode -eq 3010)
        {
          Write-Output "$($_.ProductName) patched successfully in $elapsed!"
          Write-Warning "Rebooting is needed before using $($_.ProductName)"
          $want_reboot = $true
          $exit_code = 0
        }
        else
        {
          Write-Error "Failure: Error= $($process.ExitCode), Logs=$Log, Execution time=$elapsed"
          $exit_code = $process.ExitCode
        }
      }
    }
  }
  if ($want_reboot -and $Reboot)
  {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Reboot'))
    {
      Write-Output "Restarting..."
      Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      Restart-Computer
      Start-Sleep 30
    }
  }
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
#  return $jobs
  Start-Sleep 2
  exit $exit_code
}
