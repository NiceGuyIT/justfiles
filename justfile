set positional-arguments
set shell := ['nu', '-c']

ip-to-asn ip:
	#!/usr/bin/env nu
	#echo "IP: {{ip}}"
	let ip = http get --headers [ "Accept" "application/json" ] "https://ipinfo.io/{{ip}}"
	$ip
	#$ip | get org

ip-to-asn-to-iplist:
	#!/usr/bin/env nu
	echo "TODO"
	#echo "IP: {{ip}}"
	let ip = http get --headers [ "Accept" "application/json" ] "https://ipinfo.io/{{ip}}"
	$ip | get org
