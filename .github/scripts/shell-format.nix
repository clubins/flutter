let
  pkgs = import (import ../../system.nix).nixpkgsSource { };
  npmPackage =
    name: version: sha256:
    builtins.fetchTarball {
      url = "https://registry.npmjs.org/${name}/-/${name}-${version}.tgz";
      inherit sha256;
    };
  prettierPlugins = pkgs.runCommand "prettier-config-plugins" { } ''
    mkdir -p $out/node_modules
    cp -r ${
      npmPackage "prettier-plugin-properties" "0.3.1"
        "0g4h2mj9f0lr3bdmzl4ywk5x2j654ijv4zlyv8mb7bcxfnfa7k0i"
    } $out/properties
    cp -r ${
      npmPackage "prettier-plugin-ini" "1.3.0" "1py7mcx9csqmy57kn3dzyd74vpw6sl2i7zlkm4iv3zbj2krqgnp7"
    } $out/ini
    cp -r ${
      npmPackage "dot-properties" "1.1.0" "0bi473i8y488k31pckx5z390sdcv048kxvd7xm064l61wyrcifr3"
    } $out/node_modules/dot-properties
    ln -s ${pkgs.prettier}/lib/node_modules/prettier $out/node_modules/prettier
  '';
  prettier = pkgs.writeShellScriptBin "prettier" ''
    exec ${pkgs.prettier}/bin/prettier \
      --plugin ${prettierPlugins}/properties/index.js \
      --plugin ${prettierPlugins}/ini/src/plugin.js "$@"
  '';
  # dprint plugins for configuration, documentation, web files, Dockerfiles, and SQL.
  dprintConfig = pkgs.writeText "dprint.json" (
    builtins.toJSON {
      plugins =
        (pkgs.dprint-plugins.getPluginList (plugins: [
          plugins.dprint-plugin-typescript
          plugins.dprint-plugin-json
          plugins.dprint-plugin-markdown
          plugins.dprint-plugin-toml
          plugins.dprint-plugin-dockerfile
        ]))
        ++ [
          (pkgs.fetchurl {
            url = "https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm";
            sha256 = "40a2fdda7040317eb1b23520f3a00769a5571eedb049c4ca9175c1b9eeba01ae";
          })
          (pkgs.fetchurl {
            url = "https://plugins.dprint.dev/g-plane/malva-v0.16.0.wasm";
            sha256 = "1c1b31f972ef5aae052f97b6723aaf962e0175c5bbe4ba877e092512af354113";
          })
          (pkgs.fetchurl {
            url = "https://plugins.dprint.dev/bartlomieju/lax-markup-0.3.2.wasm";
            sha256 = "0f98d8034f86ecf56d2a50f99189d201caa5bf84f75d514723737bcf6fcadec1";
          })
          (pkgs.fetchurl {
            url = "https://plugins.dprint.dev/bartlomieju/lax-sql-0.3.0.wasm";
            sha256 = "c21281b3031d20182f34fed537d0695a4ffa7e705374c00ecb18d6194908da27";
          })
        ];
      indentWidth = 2;
      markdown.textWrap = "maintain";
      yaml.associations = [
        "*.yaml"
        "*.yml"
        "**/.metadata"
      ];
      dockerfile.associations = [ "**/Dockerfile.*" ];
    }
  );
  dprint = pkgs.writeShellScriptBin "dprint" ''
    exec ${pkgs.dprint}/bin/dprint "$@" --config ${dprintConfig}
  '';
in
pkgs.mkShellNoCC {
  name = "format";
  packages = [
    pkgs.git
    pkgs.just
    pkgs.go_1_27
    pkgs.nixfmt
    pkgs.flutter.dart
    pkgs.treefmt
    dprint
    (pkgs.caddy.overrideAttrs {
      # Formatting only needs caddy fmt; upstream tests can fail when their
      # fixed network ports are occupied, preventing the shell from building.
      doCheck = false;
    })
    pkgs.shfmt
    pkgs.ruff
    pkgs.clang-tools
    pkgs.buf
    pkgs.cmake-format
    pkgs.ktfmt
    pkgs.swift-format
    pkgs.libxml2
    prettier
    pkgs.gnused
    pkgs.dos2unix
    pkgs.rustfmt
  ];
}
