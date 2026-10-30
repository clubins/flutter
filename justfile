set shell := ["bash", "-euo", "pipefail", "-c"]

mod server 'server-infra/justfile'
mod mobile 'mobile-app/justfile'
mod firmware 'hardware-firmware/justfile'

# List root commands and component commands without requiring Nix.
[default]
default:
    @{{ just_executable() }} --list --list-submodules

# Run component analysis and tests; formatting and database integration are explicit.
check:
    {{ just_executable() }} server check
    {{ just_executable() }} mobile check
    {{ just_executable() }} firmware check

# Scan component dependencies for known vulnerabilities.
audit:
    {{ just_executable() }} server audit
    {{ just_executable() }} firmware audit
    {{ just_executable() }} mobile audit

# Build a NixOS host without deploying it.
[arg('host', pattern='[a-zA-Z0-9_-]+')]
build host='prod':
    {{ just_executable() }} server build '{{ host }}'

# Remove component build outputs, preserving shared caches and Nix roots.
clean:
    {{ just_executable() }} server clean
    {{ just_executable() }} mobile clean
    {{ just_executable() }} firmware clean

# Format the repository, or only the given paths, using its central treefmt environment.
[positional-arguments]
fmt *paths:
    nix-shell .github/scripts/shell-format.nix --pure --run "treefmt --config-file treefmt.toml ${*:+$(printf '%q ' "$@")}"

# Format without the cache and fail if tracked files differ.
fmt-check:
    nix-shell .github/scripts/shell-format.nix --pure --run 'treefmt --config-file treefmt.toml --no-cache && git diff --exit-code'
