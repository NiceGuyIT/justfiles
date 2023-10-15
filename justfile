set positional-arguments
set shell := ['nu', '-c']

# See this repo for a tool to perform ASN lookups.
# https://github.com/nitefood/asn#mapping-the-ipv4v6-address-space-of-specific-countries
ip-to-asn ip:
	#!/usr/bin/env nu
	#echo "IP: {{ip}}"
	let ip = http get --headers [ "Accept" "application/json" ] "https://ipinfo.io/{{ip}}"
	$ip
	#$ip | get org

# This repo has a list of all IPs per country.
# https://github.com/herrbischoff/country-ip-blocks
ip-to-asn-list ip:
	#!/usr/bin/env nu
	echo "TODO"
	#echo "IP: {{ip}}"
	#let ip_info = http post --content-type application/json --headers [ "Accept" "application/json" ] "https://traceroute-online.com/query" { Address: {{ip}} }
	#let ip_info = http post --headers [ Content-Type application/x-www-form-urlencoded ] "https://traceroute-online.com/query" 'target={{ip}},query_type=asn'
	#$ip_info
	# API exceeded
	# In the end, I used the repo above to block the entire country.
	http post --headers [ Content-Type application/x-www-form-urlencoded ] "https://traceroute-online.com/query" 'target={{ip}}&query_type=asn'
