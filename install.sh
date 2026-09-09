#!/bin/sh
set -eu

umask 077

repository='The-CodeCave/shipd-cli'
version=${SHIPD_VERSION:-latest}
case "$version" in
  v*) version=${version#v} ;;
esac
if [ "$version" != latest ] && ! printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo 'SHIPD_VERSION must be latest or have the form X.Y.Z' >&2
  exit 64
fi

if [ -n "${SHIPD_INSTALL_DIR:-}" ]; then
  install_directory=$SHIPD_INSTALL_DIR
elif [ -n "${HOME:-}" ]; then
  install_directory=$HOME/.local/bin
else
  echo 'HOME is unset; provide an absolute SHIPD_INSTALL_DIR' >&2
  exit 64
fi
case "$install_directory" in
  /*) ;;
  *) echo 'SHIPD_INSTALL_DIR must be an absolute path' >&2; exit 64 ;;
esac

system=$(uname -s)
machine=$(uname -m)
case "$system:$machine" in
  Darwin:arm64 | Darwin:aarch64) target=aarch64-apple-darwin ;;
  Darwin:x86_64) target=x86_64-apple-darwin ;;
  Linux:aarch64 | Linux:arm64) target=aarch64-unknown-linux-musl ;;
  Linux:x86_64 | Linux:amd64) target=x86_64-unknown-linux-musl ;;
  *) echo "unsupported platform: $system/$machine" >&2; exit 69 ;;
esac

archive="shipd-$target.tar.gz"
if [ "$version" = latest ]; then
  download_base="https://github.com/$repository/releases/latest/download"
else
  download_base="https://github.com/$repository/releases/download/v$version"
fi

temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/shipd-install.XXXXXX")
trap 'rm -rf -- "$temporary_directory"' EXIT HUP INT TERM

download() {
  shipd_download_destination=$1
  shipd_download_url=$2
  curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --output "$shipd_download_destination" "$shipd_download_url"
}

download "$temporary_directory/$archive" "$download_base/$archive"
download "$temporary_directory/SHA256SUMS" "$download_base/SHA256SUMS"

checksum_count=$(awk -v asset="$archive" '$2 == asset { count += 1 } END { print count + 0 }' "$temporary_directory/SHA256SUMS")
if [ "$checksum_count" -ne 1 ]; then
  echo "release checksum list does not contain exactly one entry for $archive" >&2
  exit 65
fi
expected_checksum=$(awk -v asset="$archive" '$2 == asset { print $1 }' "$temporary_directory/SHA256SUMS" | tr 'A-F' 'a-f')
if ! printf '%s\n' "$expected_checksum" | grep -Eq '^[0-9a-f]{64}$'; then
  echo "release checksum for $archive is malformed" >&2
  exit 65
fi
if command -v sha256sum >/dev/null 2>&1; then
  actual_checksum=$(sha256sum "$temporary_directory/$archive" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  actual_checksum=$(shasum -a 256 "$temporary_directory/$archive" | awk '{print $1}')
else
  echo 'sha256sum or shasum is required to verify the download' >&2
  exit 69
fi
actual_checksum=$(printf '%s' "$actual_checksum" | tr 'A-F' 'a-f')
if [ "$actual_checksum" != "$expected_checksum" ]; then
  echo "checksum verification failed for $archive" >&2
  exit 65
fi

mkdir "$temporary_directory/unpacked"
tar -tzf "$temporary_directory/$archive" | LC_ALL=C sort > "$temporary_directory/archive-files"
printf '%s\n' LICENSE README.md shipd | LC_ALL=C sort > "$temporary_directory/expected-files"
if ! cmp -s "$temporary_directory/expected-files" "$temporary_directory/archive-files"; then
  echo 'verified archive has an unexpected file layout' >&2
  exit 65
fi
tar -xzf "$temporary_directory/$archive" -C "$temporary_directory/unpacked"
if [ ! -f "$temporary_directory/unpacked/shipd" ] || [ -L "$temporary_directory/unpacked/shipd" ]; then
  echo 'verified archive does not contain shipd' >&2
  exit 65
fi

mkdir -p "$install_directory"
staged_binary=$(mktemp "$install_directory/.shipd.XXXXXX")
trap 'rm -f -- "$staged_binary"; rm -rf -- "$temporary_directory"' EXIT HUP INT TERM
cp "$temporary_directory/unpacked/shipd" "$staged_binary"
chmod 0755 "$staged_binary"
mv -f "$staged_binary" "$install_directory/shipd"
trap 'rm -rf -- "$temporary_directory"' EXIT HUP INT TERM

echo "Installed shipd to $install_directory/shipd"
# A piped installer cannot edit its parent's PATH. Give an executable setup
# command and an immediate auth fallback, quoting even unusual custom paths.
shell_quote() {
  printf "'"
  printf '%s' "$1" | sed "s/'/'\\\\''/g"
  printf "'"
}
case ":${PATH:-}:" in
  *":$install_directory:"*) echo 'In your project folder, run: shipd auth' ;;
  *)
    printf '\nRun this in your terminal to finish setup:\n\n  export PATH='
    shell_quote "$install_directory"
    # The user's current PATH expands when they run this printed command.
    # shellcheck disable=SC2016
    printf ':"$PATH"\n\nThen, in your project folder, run: shipd auth\n'
    printf '\nOr connect immediately from your project folder with:\n\n  '
    shell_quote "$install_directory/shipd"
    printf ' auth\n'
    ;;
esac
