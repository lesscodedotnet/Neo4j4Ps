$nugetSource = "https://www.nuget.org/api/v2"
$binDir = "$PSScriptRoot\bin"
$pkgDir = "$binDir\packages"
if (!(Test-Path $pkgDir\Neo4j.Driver.1.4.0\lib\net46\Neo4j.Driver.dll)) {
  Write-Host "Installing Neo4j.Driver v1.4.0 from $nugetSource"
  & $binDir\nuget.exe install Neo4j.Driver -Version 1.4.0 -Out $pkgDir -Source $nugetSource
}

Import-Module $pkgDir\Neo4j.Driver.1.4.0\lib\net46\Neo4j.Driver.dll
Import-Module $pkgDir\System.Net.Sockets.4.1.0\lib\net46\System.Net.Sockets.dll
Import-Module $pkgDir\System.Net.Security.4.0.0\lib\net46\System.Net.Security.dll
Import-Module $pkgDir\System.Security.Cryptography.X509Certificates.4.1.0\lib\net46\System.Security.Cryptography.X509Certificates.dll
Import-Module $pkgDir\System.Net.NameResolution.4.0.0\lib\net46\System.Net.NameResolution.dll

function Invoke-Cypher() {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][Uri] $Uri,
    [Parameter(Mandatory=$true)][string] $Cypher,
    [Parameter(Mandatory=$false)][HashTable] $Params,
    [Parameter(Mandatory=$false)][PSCredential] $Credential
  )

  if (!$Credential) {
    $Credential = Get-Credential -Message "Enter Neo4 credentials"
  }

  $cypherParams = New-Object "System.Collections.Generic.Dictionary[[string],[object]]"
  if ($Params) {
    $Params.Keys | ForEach-Object {
      $cypherParams[$_] = $Params[$_]
    }
  }

  $username = $Credential.UserName
  $password = $Credential.GetNetworkCredential().Password
  try {
    Write-Verbose "Connecting to $uri as $username"
    $driver = [Neo4j.Driver.V1.GraphDatabase]::Driver($Uri, [Neo4j.Driver.V1.AuthTokens]::Basic($username, $password))
    try {
      Write-Verbose "Opening a session"
      $session = $driver.Session()
      try {
        Write-Verbose "=> $Cypher"
        if ($cypherParams.Count -gt 0) {
          $cypherParams.Keys | ForEach-Object {
            Write-Verbose ("{0}: {1}" -f $_, $cypherParams[$_])
          }
        }
        $session.Run($Cypher, $cypherParams)
      }
      finally {
        $session.Dispose()
      }
    }
    finally {
      $driver.Dispose()
    }
  }
  catch {
    $_.Exception.ToString()
  }
}
