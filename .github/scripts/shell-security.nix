let
  pkgs = import (import ../../system.nix).nixpkgsSource { };
in
pkgs.mkShellNoCC {
  name = "security";
  packages = [
    pkgs.git
    pkgs.go_1_27
    pkgs.govulncheck
    pkgs.cargo-audit
    pkgs.osv-scanner
  ];
  # Unlike formatting, scanners make HTTPS requests inside the pure shell.
  # Supply trusted CAs explicitly because --pure removes the runner's CA settings.
  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  GOTOOLCHAIN = "local";
  GOFLAGS = "-mod=readonly";
}
