#!/usr/bin/env sh

# dra is a utility to download assets from GitHub without using the github CLI.
# https://github.com/devmatteini/dra
owner=devmatteini
repo=dra
binary=dra
echo "Installing ${binary}"
os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
version="0.4.7"
url="https://github.com/${owner}/${repo}/releases/download/${version}/${binary}-${version}-${arch}-unknown-${os}-musl.tar.gz"
tmp_dir=$(mktemp --directory)
curl --silent --location --output - "${url}" | tar --strip-components 1 --directory="${tmp_dir}" --extract --gzip --file -
sudo cp "${tmp_dir}/${binary}" "/usr/local/bin/${binary}"
sudo chmod a+rx,go-w "/usr/local/bin/${binary}"
sudo chown root:root "/usr/local/bin/${binary}"
rm -r "${tmp_dir}"
ls -la "/usr/local/bin/${binary}"
echo

# just is a command runner similar to make.
# https://github.com/casey/just
owner=casey
repo=just
binary=just
echo "Installing ${binary}"
os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
tmp_dir=$(mktemp --directory)
cd "${tmp_dir}" || exit 1
echo dra download --install --select "${binary}-{tag}-${arch}-unknown-${os}-musl.tar.gz" "${owner}/${repo}"
dra download --install --select "${binary}-{tag}-${arch}-unknown-${os}-musl.tar.gz" "${owner}/${repo}"
[[ ! -f "${tmp_dir}/${binary}" ]] && echo "Failed to download binary ${binary}" && rm -f "${tmp_dir}/${binary}" && exit 1
sudo cp "${tmp_dir}/${binary}" "/usr/local/bin/${binary}"
sudo chmod a+rx,go-w "/usr/local/bin/${binary}"
sudo chown root:root "/usr/local/bin/${binary}"
cd / || exit 1
rm -r "${tmp_dir}"
ls -la "/usr/local/bin/${binary}"
echo

# ouch makes decompression painless.
# https://github.com/ouch-org/ouch
binary=ouch
repo=ouch
owner=ouch-org
echo "Installing ${binary}"
os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
tmp_dir=$(mktemp --directory)
cd "${tmp_dir}" || exit 1
echo dra download --install --select "${binary}-${arch}-unknown-${os}-musl.tar.gz" "${owner}/${repo}"
dra download --install --select "${binary}-${arch}-unknown-${os}-musl.tar.gz" "${owner}/${repo}"
[[ ! -f "${tmp_dir}/${binary}" ]] && echo "Failed to download binary ${binary}" && rm -f "${tmp_dir}/${binary}" && exit 1
sudo cp "${tmp_dir}/${binary}" "/usr/local/bin/${binary}"
sudo chmod a+rx,go-w "/usr/local/bin/${binary}"
sudo chown root:root "/usr/local/bin/${binary}"
cd / || exit 1
rm -r "${tmp_dir}"
ls -la "/usr/local/bin/${binary}"
echo

# Nushell is a new kind of shell.
# https://github.com/nushell/nushell
# dra fails to detect the correct binary.
binary=nu
repo=nushell
owner=nushell
echo "Installing ${binary}"
os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
tmp_dir=$(mktemp --directory)
cd "${tmp_dir}" || exit 1
echo dra download --select "${binary}-{tag}-${arch}-unknown-${os}-musl.tar.gz" "${owner}/${repo}"
dra download --select "${binary}-{tag}-${arch}-unknown-${os}-musl.tar.gz" "${owner}/${repo}"
ouch decompress ${binary}-*-${arch}-unknown-${os}-musl.tar.gz
sudo cp ${binary}-*-${arch}-unknown-${os}-musl/${binary} "/usr/local/bin/${binary}"
sudo chmod a+rx,go-w "/usr/local/bin/${binary}"
sudo chown root:root "/usr/local/bin/${binary}"
cd / || exit 1
rm -r "${tmp_dir}"
ls -la "/usr/local/bin/${binary}"
echo
