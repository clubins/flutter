{
  pkgs,
  oidcClientId ? "clubins-dashboard-web",
  oidcDiscoveryUrl ? "https://login.clubins.de/.well-known/openid-configuration",
}:

pkgs.flutter.buildFlutterApplication {
  pname = "clubins-dashboard";
  version = "0.0.1";
  src = pkgs.lib.cleanSourceWith {
    src = ./.;
    # Copy the mobile directory, excluding the top-level paths listed below.
    # Exclude native projects, build outputs, and local tool state so changes
    # to them do not trigger web rebuilds. New files elsewhere stay included.
    filter =
      path: type:
      pkgs.lib.cleanSourceFilter path type
      && !(builtins.elem (pkgs.lib.removePrefix "${toString ./.}/" path) [
        "android"
        "apple"
        "ios"
        "linux"
        "macos"
        "windows"
        "build"
        "coverage"
        ".dart_tool"
        ".pub-cache"
        ".pub"
        ".idea"
        ".flutter-plugins-dependencies"
        "app-debug.apk"
      ]);
  };
  targetFlutterPlatform = "web";
  autoPubspecLock = ./pubspec.lock;
  preBuild = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
    export PATH="$PATH:/usr/bin:/bin:/usr/sbin:/sbin"
  '';
  flutterBuildFlags = [
    "--no-web-resources-cdn"
    "--pwa-strategy=none"
    "--dart-define=OIDC_CLIENT_ID=${oidcClientId}"
    "--dart-define=OIDC_DISCOVERY_URL=${oidcDiscoveryUrl}"
  ];
}
