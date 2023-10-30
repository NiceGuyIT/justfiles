set positional-arguments
set shell := ['nu', '-c']

# default recipe to display help information
default:
	@just --list

# See this repo for a tool to perform ASN lookups.
# https://github.com/nitefood/asn#mapping-the-ipv4v6-address-space-of-specific-countries
ip-to-asn ip:
	#!/usr/bin/env nu
	let $whois = "/usr/bin/whois"
	let whois_path = $whois | path exists
	if not ($whois | path exists) {
		print "whois command not found"
		exit (1)
	}

	$"($whois) path exists: ($whois_path)"
	let ip = ^$whois -h whois.radb.net "{{ip}}"
	$ip


# This repo has a list of all IPs per country.
# https://github.com/herrbischoff/country-ip-blocks
# RADb query help: https://radb.net/query/help
# IP to ASN: /usr/bin/whois -h whois.radb.net 204.156.86.243
# ASN lookup: /usr/bin/whois -h whois.radb.net AS53007
# ASN to route info: /usr/bin/whois -h whois.radb.net -- '-i origin AS53007'
# Extract only the routes: /usr/bin/whois -h whois.radb.net -- '-i origin AS53007' | grep '^route:' | awk '{print $2}'
asn-list asn:
	#!/usr/bin/env nu
	let $whois = "/usr/bin/whois"
	let whois_path = $whois | path exists
	if not ($whois | path exists) {
		print "whois command not found"
		exit (1)
	}

	echo "ASN: {{asn}}"
	^$whois -h whois.radb.net -- '-i origin {{asn}}'
	#let ip_info = http post --content-type application/json --headers [ "Accept" "application/json" ] "https://traceroute-online.com/query" { Address: { {ip} } }
	#let ip_info = http post --headers [ Content-Type application/x-www-form-urlencoded ] "https://traceroute-online.com/query" 'target={ {ip} },query_type=asn'
	#$ip_info
	# API exceeded
	# In the end, I used the repo above to block the entire country.
	#http post --headers [ Content-Type application/x-www-form-urlencoded ] "https://traceroute-online.com/query" 'target={ {ip} }&query_type=asn'
