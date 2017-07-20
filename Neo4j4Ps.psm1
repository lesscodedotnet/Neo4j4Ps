$nugetSource = "https://www.nuget.org/api/v2"
$libDir = "$PSScriptRoot\bin"
if (!(Test-Path $libDir\Neo4j.Driver.1.4.0\lib\net46\Neo4j.Driver.dll)) {
  Write-Host "Installing latest Neo4j.Driver from $nugetSource"
  & $libDir\nuget.exe install Neo4j.Driver -Out $libDir -Source $nugetSource
}

Import-Module $libDir\Neo4j.Driver.1.4.0\lib\net46\Neo4j.Driver.dll
Import-Module $libDir\System.Net.Sockets.4.1.0\lib\net46\System.Net.Sockets.dll
Import-Module $libDir\System.Net.Security.4.0.0\lib\net46\System.Net.Security.dll
Import-Module $libDir\System.Security.Cryptography.X509Certificates.4.1.0\lib\net46\System.Security.Cryptography.X509Certificates.dll
Import-Module $libDir\System.Net.NameResolution.4.0.0\lib\net46\System.Net.NameResolution.dll

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
      catch {
        $session.Dispose()
        throw
      }
    }
    catch {
      $driver.Dispose()
      throw
    }
  }
  catch {
    $_.Exception.ToString()
  }
}
