[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')] 
Param(
  [Parameter(Mandatory=$false)]
  [string] $DriveLetter,
  [Parameter(Mandatory=$false)]
  [string] $Server,
  [Parameter(Mandatory=$false)]
  [string] $Share,
  [Parameter(Mandatory=$false)]
  [string] $User,
  [Parameter(Mandatory=$false)]
  [string] $Password
)
begin
{
  Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  if ([string]::IsNullOrEmpty($Server))      { $Server      = $env:SMBHOST     }
  if ([string]::IsNullOrEmpty($Share))       { $Share       = $env:SMBSHARE    }
  if ([string]::IsNullOrEmpty($User))        { $User        = $env:SMBUSER     }
  if ([string]::IsNullOrEmpty($Password))    { $Password    = $env:SMBPASSWORD }
  if ([string]::IsNullOrEmpty($DriveLetter)) { $DriveLetter = $env:SMBDRIVE    }

  if ([string]::IsNullOrEmpty($Share))  { Write-Error "Cannot connect to empty Share" ; exit 1 }
  $ShareInfo = @{ Name = $Share }
}
process
{
  switch ($env:PACKER_BUILDER_TYPE)
  {
    'parallels-iso'  { $ShareInfo['Path'] = "\\psf\${Share}" }
    'virtualbox-iso' { $ShareInfo['Path'] = "\\vboxsrv\${Share}" }
    'vmware-iso    ' { $ShareInfo['Path'] = "\\vmware-host\Shared Folders\${Share}" }
    #'hyperv-iso'
    default
    {
      if ([string]::IsNullOrEmpty($Server))   { Write-Error "No Server to connect to"  ; exit 1 }
      if ([string]::IsNullOrEmpty($User))     { Write-Error "No User to connect with"  ; exit 1 }
      if ([string]::IsNullOrEmpty($Password)) { Write-Error "No Password to connect with"  ; exit 1 }
      if ([string]::IsNullOrEmpty($DriveLetter))
      {
        do
        {
          $DriveLetter = Get-ChildItem function:[D-Z]: -Name | Where { !(Test-Path $_) } | Select -Last 1
        } while (Get-PSDrive | Where Name -eq $DriveLetter.Substring(0,1))
      }
      if ($DriveLetter -match '^[a-z]:$') { $DriveLetter = $DriveLetter.Substring(0, 1) }        

      Write-Output "$Share from $Server will be used with $DriveLetter and connected as $User"
      if ($PSCmdlet.ShouldProcess($DriveLetter, "Mounting ${Server}\${Share}"))
      {
        Write-Verbose "Testing connection information"
        $Drive = New-PSDrive -Name $DriveLetter -PSProvider FileSystem -Root \\${Server}\${Share} -Credential (New-Object System.Management.Automation.PSCredential("${Server}\${User}", (ConvertTo-SecureString -String $Password -AsPlainText -Force))) -ErrorAction Stop
        $ShareInfo['DriveLetter'] = $DriveLetter
        $ShareInfo['Path']        = "\\${Server}\${Share}"
        $ShareInfo['User']        = "${Server}\${User}";
        $ShareInfo['Password']    = $Password
      }
    }
  }
  ConvertTo-Json $ShareInfo > $env:USERPROFILE/share-$Share.info
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
