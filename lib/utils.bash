#!/usr/bin/env bash

set -eo pipefail

test -n "$ASDF_INSTALL_VERSION" || {
	echo 'Missing ASDF_INSTALL_VERSION'
	exit 1
}

test -n "$ASDF_INSTALL_PATH" || {
	echo 'Missing ASDF_INSTALL_PATH'
	exit 1
}

_get_arch() {
  local arch; arch=$(uname -m)
  case $arch in
    armv*) arch="armv6hf";;
    aarch64 | arm64) arch="aarch64";;
    x86_64) arch="x86_64";;
  esac
  echo "$arch"
}

_get_platform() {
	uname | tr '[:upper:]' '[:lower:]'
}

_get_download_url() {
	local -r version="$1"
	local -r platform="$2"
	local -r arch="$3"

	echo "https://github.com/koalaman/shellcheck/releases/download/v${version}/shellcheck-v${version}.${platform}.${arch}.tar.xz"
}

install() {
	local -r version=$1
	local -r install_path=$2
	local -r bin_install_path="${install_path}/bin"

	download "${version}"

	mkdir -p "${bin_install_path}"
	mv "${ASDF_DOWNLOAD_PATH}/shellcheck" "${bin_install_path}"
}

download() {
	local version platform arch bin_path download_url
	version="${1}"
	mkdir -p "$ASDF_DOWNLOAD_PATH"
	platform="$(_get_platform)"
	arch="$(_get_arch)"

	# Shellcheck supports Darwin/ARM only starting from v0.10.0.
	# If the requested version is lower than v0.10.0, then fall back to the x86_64 version.
	local -r version_parts=("${version//./ }")
	if [ "${version_parts[0]}" -eq 0 ] && [ "${version_parts[1]}" -lt 10 ]; then
		test "$platform" == "darwin" && arch="x86_64"
	fi
	
	bin_path="${ASDF_DOWNLOAD_PATH}/shellcheck"
	download_url="$(_get_download_url "${version}" "${platform}" "${arch}")"

	echo "Downloading shellcheck from ${download_url} to ${ASDF_DOWNLOAD_PATH}"
	# curl to tar, without files on disk
	curl -Ls "${download_url}" \
		| tar -xJv --strip-components=1 -C \
			"${ASDF_DOWNLOAD_PATH}" "shellcheck-v${version}/shellcheck"
	chmod +x "${bin_path}"
}
