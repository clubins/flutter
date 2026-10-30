#!/usr/bin/env bash
set -euo pipefail

if (($# == 0)); then
  echo "No Nix store paths were provided for cache upload" >&2
  exit 1
fi

: "${ATTIC_TOKEN:?Missing Attic upload token}"

# Each upload gets its own client configuration, including concurrent CI jobs.
umask 077
client_config="$(mktemp -d "${RUNNER_TEMP:-/tmp}/attic-upload.XXXXXXXX")"
trap 'rm -rf -- "$client_config"' EXIT
export XDG_CONFIG_HOME="$client_config"
attic login clubins https://nix.clubins.de/ "$ATTIC_TOKEN"
unset ATTIC_TOKEN

# Attic computes closures and skips paths signed by configured upstream caches.
# Cache signing happens on the server; CI only holds a scoped upload token.
attic push clubins:cache "$@"

# Check each uploaded root through the unauthenticated public endpoint.
nix --extra-experimental-features nix-command path-info \
  --store https://nix.clubins.de/cache "$@"
