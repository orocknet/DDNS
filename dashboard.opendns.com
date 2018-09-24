# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# /system scheduler add interval=5m name=dashboard.opendns.com on-event="/system script run dashboard.opendns.com" start-time=00:00:00
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
:local odnsuser "user@mail.com"
:local odnspass "passwdlogin"
:local odnshost "Your-networks-LABEL"
:local inetinterface "ether-gateway/PPPoE-dialup"
:global previousIP;
:log info "Fetching current IP"
/tool fetch url="http://myip.dnsomatic.com/" mode=http dst-path=mypublicip.txt
:delay 3;
:local currentIP [/file get mypublicip.txt contents]
:log info "Fetched current IP as $currentIP"
:if ($currentIP != 1) do={
:log info "OpenDNS: Update needed"
:set previousIP $currentIP
:local url "https://updates.opendns.com/nic/update?hostname=$odnshost"
:log info "OpenDNS: Sending update for $odnshost"
/tool fetch url=($url) user=$odnsuser password=$odnspass mode=http dst-path=("/net_odns.txt")
:delay 2;
:local odnsReply [/file get net_odns.txt contents];
:log info "OpenDNS update complete."
:log info "OpenDNS reply was $odnsReply";
} else={
:log info "OpenDNS: Previous IP $previousIP and current IP equal, no update need"
}
