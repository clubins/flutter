let
  pkgs = import (import ../../system.nix).nixpkgsSource { };
in
pkgs.mkShellNoCC {
  packages = [
    pkgs.attic-client
    pkgs.nix
  ];
  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
}
