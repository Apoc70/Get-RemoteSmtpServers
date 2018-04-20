# Get-RemoteSmtpServers.ps1

Fetch all remote SMTP servers from Exchange receive connector logs

## Description

This scripts fetches remote SMTP servers by searching the Exchange receive connector logs for the EHLO string.
Fetched remote servers can be exported to a single CSV file for all receive connectors across Exchange Servers or exported to a separate CSV file per Exchange Server.

## Requirements

- Exchange Server 2010, Exchange Server 2013+

## Parameters

### Servers

List of Exchange servers, modern and legacy Exchange servers cannot be mixed

### Backend

Search backend transport (aka hub transport) log files, instead of frontend transport, which is the default

### LegacyExchange

Search legacy Exchange servers (Exchange 2010) log file location

### ToCsv

Export search results to a single CSV file for all servers

### ToCsvPerServer

Export search results to a separate CSV file per servers

### AddDays

File selection filter, -5 will select log files changed during the last five days. Default: -10

## Examples

``` PowerShell
.\Get-RemoteSmtpServers.ps1 -Servers SRV01,SRV02 -LegacyExchange -AddDays -4 -ToCsv
```

Search legacy Exchange servers SMTP receive log files for the last 4 days and save search results in a single CSV file

## Note

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

## TechNet Gallery

Download and vote at TechNet Gallery

* [https://gallery.technet.microsoft.com/Fetch-remote-SMTP-servers-9e72f1a3] (https://gallery.technet.microsoft.com/Fetch-remote-SMTP-servers-9e72f1a3)

## Credits

Written by: Thomas Stensitzki | MVP

Stay connected:

* My Blog: [http://justcantgetenough.granikos.eu](http://justcantgetenough.granikos.eu)
* Twitter: [https://twitter.com/stensitzki](https://twitter.com/stensitzki)
* LinkedIn: [http://de.linkedin.com/in/thomasstensitzki](http://de.linkedin.com/in/thomasstensitzki)
* Github: [https://github.com/Apoc70](https://github.com/Apoc70)

For more Office 365, Cloud Security, and Exchange Server stuff checkout services provided by Granikos

* Blog: [http://blog.granikos.eu](http://blog.granikos.eu)
* Website: [https://www.granikos.eu/en/](https://www.granikos.eu/en/)
* Twitter: [https://twitter.com/granikos_de](https://twitter.com/granikos_de)