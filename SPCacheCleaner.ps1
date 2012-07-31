# Clear the SharePoint Timer Cache
#
# 2009 Mickey Kamp Parbst Jervin (mickeyjervin.wordpress.com)
# 2011 Adapted by Nick Hobbs (nickhobbs.wordpress.com) to work with SharePoint 2010,
# display more progress information, restart all timer services in the farm,
# and make reusable functions.
# 2012 Adapted by Dwayne Selsig (www.dwayneselsig.eu) to also work with SharePoint 2013. 
# Added loading of SharePoint Snapin for Powershell. Also this script only queries 
# the SharePoint servers.

# Output program information
Write-Host -foregroundcolor White ""
Write-Host -foregroundcolor White "Clear SharePoint Timer Cache"

#**************************************************************************************
# Constants
#**************************************************************************************
Set-Variable timerServiceName -option Constant -value "SPTimerV4"
Set-Variable timerServiceInstanceName -option Constant -value "Microsoft SharePoint Foundation Timer"

#**************************************************************************************
# Functions
#**************************************************************************************
#<summary>
# Loads the SharePoint Powershell Snapin.
#</summary>
Function Load-SharePoint-Powershell
{
	If ((Get-PsSnapin |?{$_.Name -eq "Microsoft.SharePoint.PowerShell"})-eq $null)
	{
    		Write-Host -ForegroundColor White " - Loading SharePoint Powershell Snapin"
		Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop
	}
}

#<summary>
# Stops the SharePoint Timer Service on each server in the SharePoint Farm.
#</summary>
#<param name="$farm">The SharePoint farm object.</param>
function StopSharePointTimerServicesInFarm($farm)
{
Write-Host ""

# Iterate through each server in the farm, and each service in each server
foreach($server in $farm)
{
foreach($instance in $server.ServiceInstances)
{
# If the server has the timer service then stop the service
if($instance.TypeName -eq $timerServiceInstanceName)
{
[string]$serverName = $server.Name

Write-Host -foregroundcolor DarkGray -NoNewline "Stop '$timerServiceName' service on server: "
Write-Host -foregroundcolor Gray $serverName

$service = Get-WmiObject -ComputerName $serverName Win32_Service -Filter "Name='$timerServiceName'"
sc.exe \\$serverName stop $timerServiceName > $null

# Wait until this service has actually stopped
WaitForServiceState $serverName $timerServiceName "Stopped"

break;
}
}
}

Write-Host ""
}

#<summary>
# Waits for the service on the server to reach the required service state.
# This can be used to wait for the "SharePoint 2010 Timer" service to stop or to start
#</summary>
#<param name="$serverName">The name of the server with the service to monitor.</param>
#<param name="$serviceName">The name of the service to monitor.</param>
#<param name="$serviceState">The service state to wait for, e.g. Stopped, or Running.</param>
function WaitForServiceState([string]$serverName, [string]$serviceName, [string]$serviceState)
{
Write-Host -foregroundcolor DarkGray -NoNewLine "Waiting for service '$serviceName' to change state to $serviceState on server $serverName"

do
{
Start-Sleep 1
Write-Host -foregroundcolor DarkGray -NoNewLine "."
$service = Get-WmiObject -ComputerName $serverName Win32_Service -Filter "Name='$serviceName'"
}
while ($service.State -ne $serviceState)

Write-Host -foregroundcolor DarkGray -NoNewLine " Service is "
Write-Host -foregroundcolor Gray $serviceState
}

#<summary>
# Starts the SharePoint Timer Service on each server in the SharePoint Farm.
#</summary>
#<param name="$farm">The SharePoint farm object.</param>
function StartSharePointTimerServicesInFarm($farm)
{
Write-Host ""

# Iterate through each server in the farm, and each service in each server
foreach($server in $farm)
{
foreach($instance in $server.ServiceInstances)
{
# If the server has the timer service then start the service
if($instance.TypeName -eq $timerServiceInstanceName)
{
[string]$serverName = $server.Name

Write-Host -foregroundcolor DarkGray -NoNewline "Start '$timerServiceName' service on server: "
Write-Host -foregroundcolor Gray $serverName

$service = Get-WmiObject -ComputerName $serverName Win32_Service -Filter "Name='$timerServiceName'"
sc.exe \\$serverName start $timerServiceName > $null

WaitForServiceState $serverName $timerServiceName "Running"

break;
}
}
}

Write-Host ""
}

#<summary>
# Removes all xml files recursive on an UNC path
#</summary>
#<param name="$farm">The SharePoint farm object.</param>
function DeleteXmlFilesFromConfigCache($farm)
{
Write-Host ""
Write-Host -foregroundcolor DarkGray "Delete xml files"

[string] $path = ""

# Iterate through each server in the farm, and each service in each server
foreach($server in $farm)
{
foreach($instance in $server.ServiceInstances)
{
# If the server has the timer service delete the XML files from the config cache
if($instance.TypeName -eq $timerServiceInstanceName)
{
[string]$serverName = $server.Name

Write-Host -foregroundcolor DarkGray -NoNewline "Deleting xml files from config cache on server: "
Write-Host -foregroundcolor Gray $serverName

# Remove all xml files recursive on an UNC path
$path = "\\" + $serverName + "\c$\ProgramData\Microsoft\SharePoint\Config\*-*\*.xml"
Remove-Item -path $path -Force

break
}
}
}

Write-Host ""
}

#<summary>
# Clears the SharePoint cache on an UNC path
#</summary>
#<param name="$farm">The SharePoint farm object.</param>
function ClearTimerCache($farm)
{
Write-Host ""
Write-Host -foregroundcolor DarkGray "Clear the cache"

[string] $path = ""

# Iterate through each server in the farm, and each service in each server
foreach($server in $farm)
{
foreach($instance in $server.ServiceInstances)
{
# If the server has the timer service then force the cache settings to be refreshed
if($instance.TypeName -eq $timerServiceInstanceName)
{
[string]$serverName = $server.Name

Write-Host -foregroundcolor DarkGray -NoNewline "Clearing timer cache on server: "
Write-Host -foregroundcolor Gray $serverName

# Clear the cache on an UNC path
# 1 = refresh all cache settings
$path = "\\" + $serverName + "\c$\ProgramData\Microsoft\SharePoint\Config\*-*\cache.ini"
Set-Content -path $path -Value "1"

break
}
}
}

Write-Host ""
}

#**************************************************************************************
# Main script block
#**************************************************************************************

# Load SharePoint Powershell Snapin
Load-SharePoint-Powershell

# Get the local farm instance
$farm = Get-SPServer | where {$_.Role -match "Application"}

# Stop the SharePoint Timer Service on each server in the farm
StopSharePointTimerServicesInFarm $farm

# Delete all xml files from cache config folder on each server in the farm
DeleteXmlFilesFromConfigCache $farm

# Clear the timer cache on each server in the farm
ClearTimerCache $farm

# Start the SharePoint Timer Service on each server in the farm
StartSharePointTimerServicesInFarm $farm
