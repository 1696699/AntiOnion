#!/usr/bin/env bash
set -euo pipefail

readonly VERSION="15.0.25"
readonly BASE_URL="https://dist.torproject.org/torbrowser/${VERSION}"
readonly ARCHIVE="tor-expert-bundle-linux-x86_64-${VERSION}.tar.gz"
readonly PRIMARY_FINGERPRINT="EF6E286DDA85EA2A4BA7DE684E2C6E8793298290"
readonly SIGNING_FINGERPRINT="022DA248432D2A0E0F54E65E316C1FACD62D07D9"
readonly INSTALL_ROOT="${HOME}/.local/share/anti-onion"
readonly INSTALL_DIR="${INSTALL_ROOT}/tor-expert-bundle-${VERSION}"

if [[ "$(uname -m)" != "x86_64" ]]; then
  printf 'Unsupported architecture: %s (this setup pins the x86_64 Tor bundle).\n' "$(uname -m)" >&2
  exit 1
fi

if [[ -x "${INSTALL_DIR}/tor/tor" ]]; then
  printf 'Tor Expert Bundle %s is already installed at %s\n' "$VERSION" "$INSTALL_DIR"
  exit 0
fi

temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT
export GNUPGHOME="${temporary_dir}/gnupg"
mkdir -m 700 -p "$GNUPGHOME"

curl --fail --location --silent --show-error \
  "${BASE_URL}/${ARCHIVE}" \
  --output "${temporary_dir}/${ARCHIVE}"
curl --fail --location --silent --show-error \
  "${BASE_URL}/${ARCHIVE}.asc" \
  --output "${temporary_dir}/${ARCHIVE}.asc"
curl --fail --location --silent --show-error \
  "https://keys.openpgp.org/vks/v1/by-fingerprint/${PRIMARY_FINGERPRINT}" \
  --output "${temporary_dir}/tor-browser-developers.asc"

gpg --batch --import "${temporary_dir}/tor-browser-developers.asc"
imported_fingerprint="$(gpg --batch --with-colons --fingerprint "$PRIMARY_FINGERPRINT" \
  | awk -F: '$1 == "fpr" { print $10; exit }')"
if [[ "$imported_fingerprint" != "$PRIMARY_FINGERPRINT" ]]; then
  printf 'Unexpected Tor signing key fingerprint: %s\n' "$imported_fingerprint" >&2
  exit 1
fi

if ! verification_status="$(gpg --batch --status-fd=1 --verify \
  "${temporary_dir}/${ARCHIVE}.asc" "${temporary_dir}/${ARCHIVE}" 2>"${temporary_dir}/gpg.log")"; then
  cat "${temporary_dir}/gpg.log" >&2
  exit 1
fi
if ! grep -Fq "[GNUPG:] VALIDSIG ${SIGNING_FINGERPRINT} " <<<"$verification_status"; then
  printf 'The archive signature is not from the pinned Tor Browser Developers signing key.\n' >&2
  cat "${temporary_dir}/gpg.log" >&2
  exit 1
fi

mkdir -p "${temporary_dir}/extract" "$INSTALL_ROOT"
tar -xzf "${temporary_dir}/${ARCHIVE}" -C "${temporary_dir}/extract"
if [[ -e "$INSTALL_DIR" ]]; then
  mv "$INSTALL_DIR" "${temporary_dir}/previous-install"
fi
mv "${temporary_dir}/extract" "$INSTALL_DIR"
printf 'Installed verified Tor Expert Bundle %s at %s\n' "$VERSION" "$INSTALL_DIR"