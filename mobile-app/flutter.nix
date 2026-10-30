{ pkgs }:

let
  # Keep Xcode's compiler and linker; expose only the older lipo command syntax.
  lipo = pkgs.runCommand "flutter-lipo" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.cctools}/bin/lipo $out/bin/lipo
  '';
in
if pkgs.stdenv.isDarwin && pkgs.lib.versionOlder pkgs.flutter.version "3.47.0" then
  pkgs.flutter.overrideAttrs (old: {
    # Xcode resets PATH in build phases, so select lipo each time Flutter starts.
    buildCommand = old.buildCommand + ''
      wrapProgram "$out/bin/flutter" --prefix PATH : "${lipo}/bin"
    '';
  })
else
  pkgs.flutter
