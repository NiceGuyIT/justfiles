#!/usr/bin/env nu

use std log
$env.NU_LOG_LEVEL = DEBUG

# get_github_assets will download the latest GitHub release JSON.
def get_github_assets [repo: string] {
	let url = $"https://api.github.com/repos/($repo)/releases/latest"
	let latest = http get $url
	# TODO: Use this to skip the download and prevent hitting GitHub's rate limit.
	#let latest = open "github-starship.json"
	let assets = if "assets" in $latest {
		$latest.assets
	} else {
		null
	}
	return $assets
}

# filter_assets will filter the assets list from the latest GitHub release by OS, ARCH and flavor until one asset
# is found.
def filter_assets [assets: record] {
	log info "Asset list before filtering"
	print $assets

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
	log info "content_type_filtered:"
	print $content_type_filtered
	if ($content_type_filtered | length) == 0 {
		log error "Error: Could not filter assets by content type"
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
		let os_filter = ($content_type_filtered | each {|it|
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
		log error "Error: Could not filter assets by OS"
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
		log error "Error: Could not filter assets by arch"
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
		log error "Error: Could not filter assets by flavor"
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

	log error "Error: Could not filter assets by OS, ARCH and flavor to result in one asset"
	log error $"Current list: ($flavor_filtered)"
	log info "flavor_filtered:"
	print $flavor_filtered
	return $flavor_filtered
}

# download_github_assets downloads the GitHub asset and returns a list of files.
def download_github_asset [tmp_dir: string, asset_file: string, url: string] {
	let tmp_file = $tmp_dir | path join $asset_file
	log debug $"tmp_dir: ($tmp_dir)"
	log debug $"tmp_file: ($tmp_file)"
	mkdir $tmp_dir
	http get $url | save $tmp_file
	cd $tmp_dir
	ouch decompress $tmp_file
	# ouch decompresses into exactly one directory
	let asset_dir = (ls | where type == dir).name.0
	cd $asset_dir
	return (ls | where size > 1mb | each {|it| ([ $tmp_dir $asset_dir $it.name ] | path join)})
}

# install_binaries will install the files into bin_dir
def install_binaries [bin_dir: string, files: list<string>] {
	if ($bin_dir | str length) == 0 {
		log error $"bin_dir is not defined: '($bin_dir)'"
		return null
	}
	$files | each {|it|
		log info $"installing '($it)' to '($bin_dir)'"
		print $"cp ($it) ($bin_dir)"
		cp $it $bin_dir
	}
}

def get_bin_dir []: string -> string {
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

def main [repo: string] {
	log info $"Getting GitHub assets for '($repo)'"
	let assets = get_github_assets $repo
	let asset = filter_assets $assets
	if ($asset | length) > 1 {
		#log debug $"Filtered asset: ($asset)"
		log error $"Failed to extract a single asset. Perhaps you need to filter based on name?"
		print $asset
		return null
	}
	print ($asset | reject id node_id label uploader state download_count created_at updated_at)

	let tmp_dir = { parent: "/tmp", stem: $"package-(random uuid)" } | path join
	let files = download_github_asset $tmp_dir $asset.name.0 $asset.browser_download_url.0
	log info $"Files: ($files)"

	let bin_dir = get_bin_dir
	log debug $"bin_dir: ($bin_dir)"
	install_binaries $bin_dir $files
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
# watchexec/watchexec

# List of packages that need work:
# cloudflare/cfssl - Not compressed
# ryochack/peep - Not compressed
# starship/starship - Additional releases () need to be filtered

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
