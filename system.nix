# Shared nixpkgs pin and NixOS entry point for every host in this repository.
# On a host <nixos-config> is /etc/nixos/configuration.nix, a symlink to the
# matching file in server-infra/hosts/. CI selects each host with
# -I nixos-config=server-infra/hosts/<host>.nix.
#
# Use only stable NixOS releases for this shared pin. To upgrade, find the
# latest release for the channel, then update the url and sha256 and rebuild.
#
#   1. List available releases (S3 listing, sorted by release number):
#        curl -s "https://nix-releases.s3.amazonaws.com/?list-type=2&prefix=nixos/26.05/&delimiter=/" \
#          | grep -oE 'nixos-26\.05\.[0-9]+\.[a-f0-9]+' | sort -Vu | tail
#      (releases.nixos.org itself renders its index client-side, so query the
#      backing S3 bucket directly.)
#   2. Prefetch the tarball to get its hash:
#        nix-prefetch-url --unpack <url of nixexprs.tar.xz>
#        nix --extra-experimental-features nix-command hash to-sri --type sha256 <base32 hash from the previous step>
#   3. Update url and sha256 below, then rebuild.
let
  nixpkgsSource = builtins.fetchTarball {
    url = "https://releases.nixos.org/nixos/26.05/nixos-26.05.12400.da6dc0e7b260/nixexprs.tar.xz";
    sha256 = "sha256-q1ku4ygV7tdmv5Q9QYwhVDsNMZRJcRYjVczoX5+XWBo=";
  };
in
(import "${nixpkgsSource}/nixos" {
  configuration = import <nixos-config>;
})
// {
  inherit nixpkgsSource;
}
