########################################################################################################################################################################################################
########################################################################################################################################################################################################
# Copyright Stamatis Litinakis 2015/02/07
#
# opsviewctl_dowtime.ps1 v0.1
#
# using syntax: opsviewctl_dowtime.ps1 
# -server (ip or hostname)
# -user (Opsview Username)
# -user (Opsview Password)
# -action ( "POST", "GET", "DELETE")
# -hostname (Opsview hostname object)
# -hostgroup (Opsview hostgroup object)
# -start (Opsview downtime start time ("+1h" or "YYYY/MM/DD hh:mm:ss"))
# -end (Opsview downtime end time ("+1h" or "YYYY/MM/DD hh:mm:ss"))
# -comment (Opsview downtime comments)
#
# EXAMPLE1: .\opsviewctl_dowtime.ps1 -server 192.168.1.1 -user admin -pass mypassword -action "POST" -hostname SERVER1 -end "+15m" -comment "WEB RELEASE"
# EXAMPLE2: .\opsviewctl_dowtime.ps1 -server 192.168.1.1 -user admin -pass mypassword -action "GET"
# EXAMPLE3: .\opsviewctl_dowtime.ps1 -server 192.168.1.1 -user admin -pass mypassword -action "DELETE" -hostname SERVER1
#
# EXAMPLE4: .\opsviewctl_dowtime.ps1 -server 192.168.1.1 -user admin -pass mypassword -action "POST" -hostgroupname WEBSERVERS -end "+1m" -comment "This is a test"
# EXAMPLE5: .\opsviewctl_dowtime.ps1 -server 192.168.1.1 -user admin -pass mypassword -action "DELETE" -hostgroupname WEBSERVERS
#
# EXAMPLE4: .\opsviewctl_dowtime.ps1 -server 192.168.1.1 -user admin -pass mypassword -action "POST" -hostgroupname WEBSERVERS -start "2015/02/08 20:00:00" -end "+90m" -comment "This is a scheduled downtime of 90 minutes"
########################################################################################################################################################################################################
########################################################################################################################################################################################################

param (
    [string]$server = $args[0],
    [string]$user = $args[1],
    [string]$pass = $args[2],
    [string]$action = $args[3],
    [string]$hostname = $args[4],
    [string]$hostgroupname = $args[4],
    [string]$start = $args[5],
    [string]$end = $args[6],
    [string]$comment = $args[7]
 )

$urlauthenticate = "/rest/login"
$urldowntime = "/rest/downtime"
$credentials = '{"username":"' + $user + '","password":"' + $pass + '"}'

$bytes = [System.Text.Encoding]::ASCII.GetBytes($credentials)
$request = [System.Net.WebRequest]::Create("http://" + $server + $urlauthenticate)
$request.Method = "POST"
$request.ContentLength = $bytes.Length
$request.ContentType = "application/json"
$stream = $request.GetRequestStream()
$stream.Write($bytes,0,$bytes.Length)
$stream.Close()

$streamreader = New-Object System.IO.Streamreader -ArgumentList $request.GetResponse().GetResponseStream()
$token = $streamreader.ReadToEnd()
$streamreader.Close()

$token=$token.Replace("{`"token`":`"", "")
$token=$token.Replace("`"}", "")

if ($hostname)
{ $params = "?hst.hostname=$hostname"}
elseif ($hostgroupname)
{ $params = "?hg.hostgroupname=$hostgroupname"}

If ($action -eq "POST") 
{
  if ($start)
  {$hostdata = '{"starttime":"'+$start+'","endtime":"'+$end+'","comment":"'+$comment+'"}'}
  else
  {$hostdata = '{"starttime":"now","endtime":"'+$end+'","comment":"'+$comment+'"}'}
  $bytes = [System.Text.Encoding]::ASCII.GetBytes($hostdata)
  $request = [System.Net.WebRequest]::Create("http://$server$urldowntime$params")
  $request.Method = $action
  $request.ContentLength = $bytes.Length
  $request.ContentType = "application/json"
  $request.Headers.Add("X-Opsview-Username","$user")
  $request.Headers.Add("X-Opsview-Token",$token);
  $stream = $request.GetRequestStream()
  $stream.Write($bytes,0,$bytes.Length)
  $stream.Close()
}  

elseif ($action -eq "DELETE")
{
  $request = [System.Net.WebRequest]::Create("http://$server$urldowntime$params")
  $request.Method = $action
  $request.ContentType = "application/json"
  $request.Headers.Add("X-Opsview-Username","$user")
  $request.Headers.Add("X-Opsview-Token",$token);
}  

elseif ($action -eq "GET")
{
  $request = [System.Net.WebRequest]::Create("http://$server$urldowntime")
  $request.Method = $action
  $request.ContentType = "application/json"
  $request.Headers.Add("X-Opsview-Username","$user")
  $request.Headers.Add("X-Opsview-Token",$token);
}

$streamreader = New-Object System.IO.Streamreader -ArgumentList $request.GetResponse().GetResponseStream()
$streamreader.ReadToEnd()
$streamreader.Close()
