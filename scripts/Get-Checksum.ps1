<#
.SYNOPSIS
Compute and check SHA1/MD5 message digest

.DESCRIPTION
Print or check the checksum of the given file or the standard input.

.PARAMETER SHA1
Will compute an SHA1 (160-bit) checksum

.PARAMETER MD5
Will compute an MD5 checksum

.PARAMETER Path
Path of the file to compute

.PARAMETER eq
If present, the checksum will be compared to the value of the parameter.
The Cmdlet will return an error if both values do not match. This is case insensitive.

.EXAMPLE
sha1sum C:\windows\explorer.exe

.EXAMPLE
Get-ChildItem C:\windows\explorer.exe | sha1sum

.EXAMPLE This will return a success or filure error code:
sha1sum C:\windows\explorer.exe -eq '83e89fee77583097ddbb2648af43c097c62580fc'
#>
[CMdletBinding(DefaultParameterSet="SHA1")]
param(
  [Parameter(ParameterSetName="SHA1", Mandatory=$true)]
  [switch] $SHA1,
  [Parameter(ParameterSetName="MD5", Mandatory=$true)]
  [switch] $MD5,
  [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
  [string] $Path,
  [Parameter(Mandatory=$false)]
  [string] $eq
)
begin
{
  switch($cmdlet.ParameterShetName)
  {
    "SHA1" { $provider = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider }
    "MD5"  { $provider = New-Object System.Security.Cryptography.MD5CryptoServiceProvider  }
  }
}
process
{
  Get-Item $Path -Force | ForEach-Object {
    $hash   = New-Object System.Text.StringBuilder
    $stream = $_.OpenRead() 

    if ($stream)
    { 
      foreach ($byte in $provider.ComputeHash($stream))
      {
        [Void] $hash.Append($byte.ToString("X2"))
      } 
      $stream.Close() 
      $checksum = $hash.ToString()

      if ($eq -ne '')
      {

        Write-Verbose "Matching $checksum with $eq"
        if ($checksum -ieq $eq)
        {
          Write-Verbose 'matches'
          exit
        }
        else
        {
          Write-Error 'does not match'
          #Throw [System.IO.InvalidDataException]
          exit 1
        }
      }
      else
      {
        Write-Output $checksum
      }
    } 
  }
}
