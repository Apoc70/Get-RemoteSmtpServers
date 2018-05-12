<#
  .SYNOPSIS
  Fetch all remote SMTP servers from Exchange receive connector logs 
   
  Thomas Stensitzki

  THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
  RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
	
  Version 1.1, 2018-05-12

  Ideas, comments and suggestions to support@granikos.eu 
 
  .LINK  
  http://scripts.granikos.eu

  .DESCRIPTION
  This scripts fetches remote SMTP servers by searching the Exchange receive connector logs for the EHLO string.
  Fetched servers can be exported to a single CSV file for all receive connectors across Exchange Servers or
  exported to a separate CSV file per Exchange Server.
	
  .NOTES 
  Requirements 
  - Exchange Server 2010, Exchange Server 2013+  

  Revision History 
  -------------------------------------------------------------------------------- 
  1.0     Initial community release 
  1.1     Issue #2 fixed
	
  .PARAMETER Servers
  List of Exchange servers, modern and legacy Exchange servers cannot be mixed

  .PARAMETER Backend
  Search backend transport (aka hub transport) log files, instead of frontend transport, which is the default

  .PARAMETER LegacyExchange
  Search legacy Exchange servers (Exchange 2010) log file location

  .PARAMETER ToCsv
  Export search results to a single CSV file for all servers

  .PARAMETER ToCsvPerServer
  Export search results to a separate CSV file per servers

  .PARAMETER AddDays
  File selection filter, -5 will select log files changed during the last five days. Default: -10

  .EXAMPLE
  .\Get-RemoteSmtpServers.ps1 -Servers SRV01,SRV02 -LegacyExchange -AddDays -4 -ToCsv

  Search legacy Exchange servers SMTP receive log files for the last 4 days and save search results in a single CSV file
   
#>


[CmdletBinding()]
param(
  [string[]]$Servers = @('EX01','EX02'),
  [switch]$Backend,
  [switch]$LegacyExchange,
  [switch]$ToCsv,
  [switch]$ToCsvPerServer,
  [int]$AddDays = -10
)

$ScriptDir = Split-Path -Path $script:MyInvocation.MyCommand.Path

$CsvFileName = ('RemoteSMTPServers-%SERVER%-%ROLE%-{0}.csv' -f ((Get-Date).ToString("s").Replace(":","-")))

# ToDo: Update to Get-TransportServer/Get-TransportService 
# Currently pretty static
$LegacyExchangePath = '\\%SERVER%\c$\Program Files\Microsoft\Exchange Server\V14\TransportRoles\Logs\ProtocolLog\SmtpReceive'
$BackendPath = '\\%SERVER%\e$\Program Files\Microsoft\Exchange Server\V15\TransportRoles\Logs\Hub\ProtocolLog\SmtpReceive'
$FrontendPath = '\\%SERVER%\e$\Program Files\Microsoft\Exchange Server\V15\TransportRoles\Logs\FrontEnd\ProtocolLog\SmtpReceive'

# The SMTP receive log search pattern
$Pattern = "(.)*EHLO"

# An empty array for storing remote servers
$RemoteServers = @()

function Write-RemoteServers {
  [CmdletBinding()]
  param(
    [string]$FilePath = ''
  )

  # sort servers
  $RemoteServers = $RemoteServers | Select-Object -Unique | Sort-Object

  if(($RemoteServers| Measure-Object).Count -gt 0) {
    
    # Create an empty array
    $RemoteServersOutput = @()

    foreach($Server in $RemoteServers) { 
    
      if($Server.Trim() -ne '') { 
        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name 'Remote Server' -Value $Server
        $RemoteServersOutput += $obj
      }
    }

    if($ToCsv -or $ToCsvPerServer) {
      # save remote servers list as csv
      $null = $RemoteServersOutput | Export-Csv -Path $FilePath -Encoding UTF8 -NoTypeInformation -Force -Confirm:$false

      Write-Verbose -Message ('Remote server list written to: {0}' -f $FilePath)
    }

    $RemoteServersOutput
  
  }
  else {
    Write-Host 'No remote servers found!'
  }

}

## MAIN ###########################################
$LogPath = $FrontendPath

# Adjust CSV file name to reflect either HUB or FRONTEND transport
if($Backend) {
  $LogPath = $BackendPath
  $CsvFileName = $CsvFileName.Replace('%ROLE%','HUB')
}
elseif($LegacyExchange) { 
  $LogPath = $LegacyExchangePath
  $CsvFileName = $CsvFileName.Replace('%ROLE%','HUB')
}
else {
  $CsvFileName = $CsvFileName.Replace('%ROLE%','FE')
}

Write-Verbose -Message "CsvFileName: $($CsvFileName)"

# Fetch each Exchange Server server 
foreach($Server in $Servers) {
 
  $Server = $Server.ToUpper()

  $Path = $LogPath.Replace('%SERVER%', $Server)

  # fetching log files requires an account w/ administrative access to the target server
  $LogFiles = Get-ChildItem -Path $Path -File | Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays($AddDays)} #| Select-Object -First 2

  $LogFileCount = ($LogFiles | Measure-Object).Count
  $FileCount = 1

  foreach($File in $LogFiles) {

    Write-Progress -Activity ('{3} | File [{0}/{1}] : {2}' -f $FileCount, $LogFileCount, $File.Name, $Server) -PercentComplete(($FileCount/$LogFileCount)*100)

    # find results in selected log files
    $results = (Select-String -Path $File.FullName -Pattern $Pattern)

    Write-Verbose -Message ('Results {0} : {1}' -f $File.FullName, ($results | Measure-Object).Count)

    # Get remote server information from search string result
    foreach($record in $results) {
      $HostName = ($record.line -replace $Pattern,'').Replace(',','').Trim().ToUpper()
    
      if(-not $RemoteServers.Contains($HostName)) { 
        $RemoteServers += $HostName
      }
    }

    $FileCount++

  }

  if($ToCsvPerServer) {
   
    $CsvFile = $CsvFileName.Replace('%SERVER%',$Server)

    Write-Verbose $CsvFile

    Write-RemoteServers -FilePath $CsvFile
    
    $RemoteServers = @()
  }
}

if($ToCsv) { 
  $CsvFile = $CsvFileName.Replace('%SERVER%','ALL')

  Write-Verbose $CsvFile

  Write-RemoteServers -FilePath $CsvFile
}