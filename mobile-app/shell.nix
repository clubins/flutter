{
  android ? false,
  ios ? false,
}:
let
  nixpkgsSource = (import ../system.nix).nixpkgsSource;
  pkgs = import nixpkgsSource {
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };
  buildToolsVersion = "34.0.0";
  flutter = import ./flutter.nix { inherit pkgs; };
  androidSdk =
    (pkgs.androidenv.composeAndroidPackages {
      toolsVersion = "26.1.1";
      platformToolsVersion = "35.0.2";
      buildToolsVersions = [
        buildToolsVersion
        "35.0.0"
      ];
      platformVersions = [
        "35"
        "36"
      ];
      includeNDK = true;
      ndkVersions = [ "28.2.13676358" ];
      cmakeVersions = [ "3.22.1" ];
    }).androidsdk;
  androidHome = "${androidSdk}/libexec/android-sdk";
in
assert !ios || pkgs.stdenv.isDarwin;
pkgs.mkShellNoCC (
  {
    packages = [
      flutter
      pkgs.git
      pkgs.rsync
    ]
    ++ pkgs.lib.optionals android [
      androidSdk
      pkgs.jdk17
    ];
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    # Xcode and simulator runtimes are installed by the developer, outside Nix.
    shellHook =
      pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
        export PATH="$PATH:/usr/bin:/bin:/usr/sbin:/sbin"
      ''
      + pkgs.lib.optionalString ios ''
        export DEVELOPER_DIR="''${DEVELOPER_DIR:-$(/usr/bin/xcode-select -p)}"
      '';
  }
  // pkgs.lib.optionalAttrs android {
    ANDROID_HOME = androidHome;
    ANDROID_SDK_ROOT = androidHome;
    ANDROID_NDK_ROOT = "${androidHome}/ndk/28.2.13676358";
    JAVA_HOME = "${pkgs.jdk17}";
    GRADLE_OPTS = "-Dorg.gradle.java.home=${pkgs.jdk17} -Dorg.gradle.project.android.aapt2FromMavenOverride=${androidHome}/build-tools/${buildToolsVersion}/aapt2";
  }
)
