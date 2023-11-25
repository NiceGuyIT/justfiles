#!/usr/bin/env nu

use std log
$env.NU_LOG_LEVEL = DEBUG

# get-github-assets will download the latest GitHub release JSON and return the assets as a record.
def get-github-assets [repo: string]: nothing -> table<record> {
	# TODO: Use this to skip the download and prevent hitting GitHub's rate limit.
	#http get $"https://api.github.com/repos/($repo)/releases/latest"
	open $"github-atuin.json"
		| get assets
		| select browser_download_url name content_type size
}

# filter_assets will filter the GitHub assets list by OS, ARCH and flavor until one asset is found.
def filter_assets [assets: record] {
	#log info "Asset list before filtering"
	#print ($assets | select name content_type size)

	# Filter out non-binary content types. This is the list of acceptable Content-Type values.
	let content_type_list = [
		"application/octet-stream",
		"application/zip",
		"application/x-gtar",
		"application/x-xz",
		"application/gzip",
	]
	log info $"Iterating over content_type_list: ($content_type_list)"
	let content_type_filtered = ($content_type_list | each {|ct|
		#log debug $"content_type_list: ($ct)"
		let content_type_filter = ($assets | each {|it|
			if $it.content_type =~ $ct {
				#log debug $"content_type_list: ($ct); found: ($it.content_type)"
				return $it
			}
		})
		#log info "content_type_filter:"
		#print $content_type_filter
		if ($content_type_filter | length) > 0 {
			#log debug $"content_type_list: ($ct); found: ($content_type_filter)"
			return $content_type_filter
		}
	} | flatten)
	#log info "content_type_filtered:"
	#print ($content_type_filtered | select name content_type size)
	if ($content_type_filtered | length) == 0 {
		log error "Could not filter assets by content type"
		log error $"Current list: ($assets)"
		print "Assets:"
		print $assets
		print "Content Type Filtered:"
		print $content_type_filtered
		return null
	} else if ($content_type_filtered | length) == 1 {
		log debug $"Found one asset filtered by Content Type: ($content_type_filtered)"
		return $content_type_filtered
	}

	# Filter out non-binary filenames such as .deb, .rpm, .sha256, .sha512, etc. by selecting only valid extensions.
	# This is the list of acceptable filename values.
	let filename_extension_list = [
		"tar.gz",
		"tar.xz",
		"zip",
	]
	log info $"Iterating over filename_extension_list: ($filename_extension_list)"
	let filename_extension_filtered = ($filename_extension_list | each {|fe|
		log debug $"filename_extension_list: ($fe)"
		let filename_extension_filter = ($content_type_filtered | each {|it|
			let $ext = ($it.name | file-extension)
			if ($it.name | file-extension) == $fe {
				log debug $"filename_extension_list: ($fe); found: ($it.name)"
				return $it
			} else {
				log debug $"filename_extension_list: ($fe); not found: ($it.name); extension: ($ext)"
			}
		})
		#log info "filename_extension_filter:"
		#print $filename_extension_filter
		if ($filename_extension_filter | length) > 0 {
			#log debug $"filename_extension_filter: ($fe); found: ($filename_extension_filter)"
			return $filename_extension_filter
		}
	} | flatten)
	log info "filename_extension_filtered:"
	print $filename_extension_filtered
	if ($filename_extension_filtered | length) == 0 {
		log error "Could not filter assets by filename extension"
		# log error $"Current list: ($content_type_filtered)"
		#print "content_type_filtered:"
		#print ($content_type_filtered | select name content_type size)
		print "Filename Extension Filtered:"
		print $filename_extension_filtered
		return null
	} else if ($filename_extension_filtered | length) == 1 {
		log debug $"Found one asset filtered by Filename Extension: ($filename_extension_filtered)"
		return $filename_extension_filtered
	}

	# Map the OS to possible OS values in the release names. This is mainly for Apple.
	let os_map = {
		linux: [
			linux,
			# micro uses "linux64" as the os and arch combined.
			# https://github.com/zyedidia/micro/releases
			#linux64,
		],
		darwin: [
			darwin,
			apple,
		],
		windows: [
			windows,
		],
	}
	let os_list = ( $os_map | get ($nu.os-info.name) )
	log info $"Iterating over os_list: ($os_list)"
	let os_filtered = ($os_list | each {|os|
		#log debug $"os: ($nu.os-info.name); os_list: ($os)"
		let os_filter = ($filename_extension_filtered | each {|it|
			if $it.name =~ $os {
				#log debug $"os: ($nu.os-info.name); os_list: ($os); found: ($it.name)"
				return $it
			}
		})
		log info "os_filter:"
		print $os_filter
		if ($os_filter | length) > 0 {
			#log debug $"os: ($nu.os-info.name); os_list: ($os); found: ($os_filter)"
			return $os_filter
		}
	} | flatten)
	log info "os_filtered:"
	print $os_filtered
	if ($os_filtered | length) == 0 {
		log error "Could not filter assets by OS"
		log error $"Current list: ($assets)"
		print "Assets:"
		print $assets
		print "OS Filtered:"
		print $os_filtered
		return null
	} else if ($os_filtered | length) == 1 {
		log debug $"Found one asset filtered by OS: ($os_filtered)"
		return $os_filtered
	}

	# Map the architecture to possible ARCH values in the release names.
	let arch_map = {
		x86_64: [
			x86_64,
			amd64,
		],
		aarch64: [
			arm64,
		],
		arm64: [
			arm64,
		],
	}
	let arch_list = ( $arch_map | get ($nu.os-info.arch) )
	log info $"Iterating over arch_list: ($arch_list)"
	let arch_filtered = ($arch_list | each {|arch|
		#log debug $"arch: ($nu.os-info.arch); arch_list: ($arch)"
		let arch_filter = ($os_filtered | each {|it|
			if $it.name =~ $arch {
				#log debug $"arch: ($nu.os-info.arch); arch_list: ($arch); found: ($it.name)"
				return $it
			}
		})
		if ($arch_filter | length) > 0 {
			#log debug $"arch: ($nu.os-info.arch); arch_list: ($arch); found: ($arch_filter)"
			return $arch_filter
		}
	} | flatten)
	log info "arch_filtered:"
	print $arch_filtered
	if ($arch_filtered | length) == 0 {
		log error "Could not filter assets by arch"
		log error $"Current list: ($os_filtered)"
		print "OS Filtered:"
		print $os_filtered
		print "ARCH Filtered:"
		print $arch_filtered
		return null
	} else if ($arch_filtered | length) == 1 {
		log debug $"Found one asset filtered by ARCH: ($arch_filtered)"
		return $arch_filtered
	}

	let flavor = "musl"
	let flavor_filtered = $arch_filtered | each {|it| if $it.name =~ $flavor {return $it} }
	if ($flavor_filtered | length) == 0 {
		log error "Could not filter assets by flavor"
		log error $"Current list: ($arch_filtered)"
		print "ARCH Filtered:"
		print $arch_filtered
		print "Flavor Filtered:"
		print $flavor_filtered
		return null
	} else if ($flavor_filtered | length) == 1 {
		log debug $"Found one asset filtered by flavor: ($flavor_filtered)"
		return $flavor_filtered
	}

	log error "Could not filter assets by OS, ARCH and flavor to result in one asset"
	log error $"Current list: ($flavor_filtered)"
	log info "flavor_filtered:"
	print $flavor_filtered
	return $flavor_filtered
}

# download-github-assets downloads the GitHub asset and returns a list of files.
def download-github-asset [tmp_dir: string, asset_file: string, url: string]: nothing -> list {
	let tmp_file: string = ($tmp_dir | path join $asset_file)
	log debug $"tmp_dir: ($tmp_dir)"
	log debug $"tmp_file: ($tmp_file)"
	mkdir $tmp_dir
	http get $url | save $tmp_file
	#cd $tmp_dir
	ouch --yes --quiet --accessible decompress --dir $tmp_dir $tmp_file
	# ouch decompresses into exactly one directory
	let asset_dir = (ls $tmp_dir | where type == dir).name.0
	#cd $asset_dir
	return (ls $asset_dir | where size > 1mb | each {|it| ([ $tmp_dir $asset_dir $it.name ] | path join)})
}

# install-binaries will install the files into bin_dir
def install-binaries [bin_dir: string, files: list<string>] {
	if ($bin_dir | str length) == 0 or ($bin_dir | is-empty) {
		log error $"bin_dir is not defined: '($bin_dir)'"
		return null
	}
	$files | each {|it|
		log info $"installing '($it)' to '($bin_dir)'"
		print $"cp ($it) ($bin_dir)"
		cp $it $bin_dir
	}
}

# get-bin-dir will get the bin directory to install the binaries.
def get-bin-dir []: string -> string {
	mut bin_dir = ""
	if $nu.os-info.name == "windows" {
		$bin_dir = ""
	} else {
		# *nix (Linux, macOS, BSD)
		if $env.USER == "root" {
			$bin_dir = "/usr/local/bin"
		} else {
			$bin_dir = $"($env.HOME)/bin"
		}
	}
	return $bin_dir
}

# file-basename will return the basename of the filename.
def file-basename []: string -> string {
	split column '.' | get column1.0
}

# file-extension will return the extension of the filename.
def file-extension []: string -> string {
	str replace --regex '^[^\.]+\.' ''
}

# url-filename will extract the filename from the URL.
def url-filename []: string -> string {
	(url parse).path | path basename
}

# filter-os will filter out binaries that do not match the current OS
def filter-os []: table<record> -> table<record> {
	let input: table = $in
	# Map the OS to possible OS values in the release names. This is mainly for Apple.
	# os_map: record<linux: list<string>, darwin: list<string>, windows: list<string>>
	let os_map = {
		linux: [
			linux,
			# micro uses "linux64" as the os and arch combined.
			# https://github.com/zyedidia/micro/releases
			#linux64,
		],
		darwin: [
			darwin,
			apple,
		],
		windows: [
			windows,
		],
	}
	let os_list = ($os_map | get ($nu.os-info.name))
	# FIXME: $in throws "Input type not supported."
	$input | where ($os_list | any {|os| $it.name =~ $os })
}

# filter-arch will filter out binaries that do not match the current archtecture
def filter-arch []: table<record> -> table<record> {
	let input: table = $in
	# Map the architecture to possible ARCH values in the release names.
	# arch_map: record<x86_64: list<string>, aarch64: list<string>, arm64: list<string>>
	let arch_map = {
		x86_64: [
			x86_64,
			amd64,
		],
		aarch64: [
			arm64,
		],
		arm64: [
			arm64,
		],
	}
	let arch_list = ($arch_map | get ($nu.os-info.arch))
	# FIXME: $in throws "Input type not supported."
	$input | where ($arch_list | any {|arch| $it.name =~ $arch })
}

# filter-content-type will filter out non-binary content types.
def filter-content-type []: table<record> -> table<record> {
	let input: table = $in
	# List of acceptable Content-Type values.
	let content_type_list: list<string> = [
		"application/octet-stream",
		"application/zip",
		"application/x-gtar",
		"application/x-xz",
		"application/gzip",
	]
	$input | where ($content_type_list | any {|ct| $it.content_type == $ct})
}

# filter-extension will filter out non-binary filenames such as .deb, .rpm, .sha256, .sha512, etc. by selecting only
# valid extensions.
def filter-extension []: table<record> -> table<record> {
	let input: table = $in
	# List of acceptable extensions
	let extension_list: list<string> = [
		"tar.gz",
		"tar.xz",
		"zip",
	]
	let filtered: table = (
		$input | where ($extension_list | any {|ext| $it.name | str ends-with $ext})
	)
	return $filtered
}

# has-flavor will return true if any of the assets have different flavor binaries.
def has-flavor []: table<record> -> bool {
	let input: table = $in
	let flavor_list = [
		"musl",
		"gnu"
	]
	let filtered: table = (
		$input | where ($flavor_list | any {|f| $it.name =~ $"\\b($f)\\b" })
	)
	return (not ($filtered | length) == 0)
}

# filter-flavor will filter records based on the binary flavor (musl, gnu, etc.) or the given name.
def filter-flavor [flavor: string = "musl"]: table<record> -> table<record> {
	let input: table = $in
	let filtered: table = (
		$input | where $it.name =~ $"\\b($flavor)\\b"
	)

	if ($filtered | length) == 0 {
		log error "Filtering by flavor resulted in 0 assets"
		print ($filtered)
		return $filtered
	} else if ($filtered | length) == 1 {
		return $filtered
	} else {
		log error "Filtering by flavor resulted in more than 1 asset"
		print ($filtered)
		return $filtered
	}
}

# download-compressed will filter the assets, download, decompress and install it.
def dl-compressed [
	--name (-n): string		# Binary name to install. Default: "repo" in "owner/repo"
	--filter (-f): string	# Filter the results if a single release can't be determined
]: table<record> -> table<record> {
	mut input: table<record: any> = $in
	mut filtered: table<record: any> = $input

	if ($input | length) > 1 {
		# Compressed assets need to be filtered by extension.
		$filtered = ($input | filter-extension)
		match ($filtered | length) {
			0 => {
				log error $"Filtering by extension resulted in 0 assets"
				return $filtered
			}
			1 => {
				log info $"Filtering by extension resulted in 1 asset"
				# No additional filtering needed
				$input = $filtered
			}
			_ => {
				log error $"Filtering by extension resulted in 2 or more assets"
				return $filtered
			}
		}
	}

	# $input has exactly 1 record
	let tmp_dir: string = ({ parent: "/tmp", stem: $"package-(random uuid)" } | path join)
	let files = download-github-asset $tmp_dir $input.name.0 $input.browser_download_url.0
	log info $"Files: ($files)"

	let bin_dir = get-bin-dir
	log debug $"bin_dir: ($bin_dir)"
	install-binaries $bin_dir $files

	return $input
}

# download-uncompressed will download the uncompressed file and install it.
def dl-uncompressed [
	--name (-n): string		# Binary name to install. Default: "repo" in "owner/repo"
	--filter (-f): string	# Filter the results if a single release can't be determined
]: table<record> -> table<record> {
	let input: table = $in

	if ($input | length) > 1 {
		log error $"Uncompressed assets has 2 or more assets"
		return $input
	}

	# $input has exactly 1 record
	let tmp_dir: string = ({ parent: "/tmp", stem: $"package-(random uuid)" } | path join)
	let files = download-github-asset $tmp_dir $input.name.0 $input.browser_download_url.0
	log info $"Files: ($files)"

	return $input
}

# dl-gh will return the download URL for the given repo.
def dl-gh [
	repo: string			# GitHub repo name in owner/repo format
	--name (-n): string		# Binary name to install. Default: "repo" in "owner/repo"
	--filter (-f): string	# Filter the results if a single release can't be determined
]: nothing -> string {
	mut assets: table<record: any> = (get-github-assets $repo
		| filter-content-type
		| filter-os
		| filter-arch
	)
	#print ($assets)
	if ($assets | length) == 0 {
		log error $"Filtering by content type, OS and architecture resulted in 0 assets"
		return $assets
	}

	# Check if the asset names use flavors, i.e. musl, gnu, etc., and filter them
	mut flavor: table<record: any> = $assets
	if ($assets | has-flavor) {
		$flavor = ($assets | filter-flavor)
	}
	if ($flavor | length) == 0 {
		log error "Filtering on flavor resulted in 0 assets. Resetting to previous asset list"
		$flavor = $assets
	}
	$assets = $flavor
	print ($assets)
	
	# The content_type uniqueness determines if the assets are compressed. If all of them are
	# "application/octet-stream", the assets are uncompressed.
	let ct_count = $assets | get content_type | uniq --count
	print ($ct_count)
	if ($ct_count | length) == 1 and ($ct_count.value.0 == "application/octet-stream") {
		log info "Uncompressed assets"
		let results = ($assets | dl-uncompressed --name $name --filter $filter)
		#print ($results)
		return $results
	} else {
		log info  "Compressed assets"
		# Compressed assets need to be filtered by extension.
		let results = ($assets | dl-compressed --name $name --filter $filter)
		#print ($results)
		return $results
	}
	return
}

def main [
	repo: string			# GitHub repo name in owner/repo format
	--name (-n): string		# Binary name to install. Default: "repo" in "owner/repo"
	--filter (-f): string	# Filter the results if a single release can't be determined
]: nothing -> nothing {
	# Separator for REPL
	print "=============================="
	if not ($name | is-empty) {
		print $"Name: ($name)"
	}
	if not ($filter | is-empty) {
		print $"Filter: ($filter)"
	}
	print (dl-gh --name $name --filter $filter $repo)
	return null

	#log info $"Getting GitHub assets for '($repo)'"
	#let assets = get-github-assets $repo
	#let asset = filter_assets $assets
	#if ($asset | length) > 1 {
	#	#log debug $"Filtered asset: ($asset)"
	#	log error $"Failed to extract a single asset. Perhaps you need to filter based on name?"
	#	print $asset
	#	return null
	#}
	## print ($asset | reject id node_id label uploader state download_count created_at updated_at)
	#print $asset
	#return null
	#
	#let tmp_dir = { parent: "/tmp", stem: $"package-(random uuid)" } | path join
	#let files = download-github-asset $tmp_dir $asset.name.0 $asset.browser_download_url.0
	#log info $"Files: ($files)"
	#
	#let bin_dir = get_bin_dir
	#log debug $"bin_dir: ($bin_dir)"
	#install_binaries $bin_dir $files
}

# List of packages that work:
# FiloSottile/age
# ellie/atuin
# docker/compose
# mr-karan/doggo
# sharkdp/fd
# go-acme/lego
# ouch-org/ouch
# BurntSushi/ripgrep
# rclone/rclone
# mozilla/sops
# junegunn/fzf - Not compressed
# casey/just

# List of packages that need work:
# cloudflare/cfssl - Not compressed
# ryochack/peep - Not compressed
# starship/starship - Additional releases () need to be filtered
# watchexec/watchexec - filter out checksums

# List of packages that do not work:
# alacritty/alacritty - https://github.com/alacritty/alacritty/blob/master/INSTALL.md#opensuse
#   Alacritty does not provide binaries for Linux
# zyedidia/micro - https://github.com/zyedidia/micro/releases
#   Micro mixes OS and ARCH in the release name, making detection of the real release very hard.


# This is from a discord conversation.
# Nushell does not really use exit to stop a script, the way to go imo is to use
#   - return to return a value
#   - errors to stop
#
# def main [] {
#     if something {
#         error make { ... }
#     }
#
#     ...
#
#     if some_other_thing {
#         return $early
#     }
#
#     ...
#
#     $output_value
# }
