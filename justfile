set positional-arguments
set shell := ['nu', '-c']

# List the justfiles available.
list:
	just --list

# https://github.com/nitefood/asn#mapping-the-ipv4v6-address-space-of-specific-countries
# See this repo for a tool to perform ASN lookups.
ip-to-asn ip:
	#!/usr/bin/env nu
	#echo "IP: {{ip}}"
	let ip = http get --headers [ "Accept" "application/json" ] "https://ipinfo.io/{{ip}}"
	$ip
	#$ip | get org

# https://github.com/herrbischoff/country-ip-blocks
# This repo has a list of all IPs per country.
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

install-binary package:
	#!/usr/bin/env nu
	let packages = {
		age: {
			linux: "age-v{tag}-linux-amd64.tar.gz",
			mac: "age-v{tag}-darwin-arm64.tar.gz",
			windows: "age-v{tag}-windows-amd64.zip",
			repo: "FiloSottile/age"
		}
	}
	let os = $nu.os-info.name
	let pattern = ($packages.{{package}} | get $os)
	let repo = ($packages.{{package}} | get "repo")
	print $"Downloading '($pattern)' from '($repo)'"
	dra download --select $pattern $repo
