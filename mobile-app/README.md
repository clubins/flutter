# Clubins dashboards

A Flutter dashboard for Clubins venue sound levels, weather forecasts, and
reference exchange rates.

## Development

From the repository root:

```sh
just mobile check
just mobile android
just mobile web
just mobile ios --simulator --debug
```

For macOS prerequisites, physical iPhone signing, simulator selection, and the
full set of repository checks, see [Development](https://github.com/lifelikemaik/clubins-hack/blob/main/DEVELOPMENT.md).

The UI uses `ShadcnApp` and `shadcn_flutter` components, with the Clubins theme
in `lib/theme.dart`. Use Lucide icons and shadcn controls for new UI;
`just mobile analyze` also checks that application code and widget tests do not
introduce Material/Cupertino imports or their icon sets. Charts use `fl_chart`
with shared colors, axes, grids, and tooltips in `lib/widgets/chart_style.dart`.

`shadcn_flutter` is pinned to 0.0.53 for the repository's Flutter 3.41.9 /
Dart 3.11.5 toolchain. Versions 0.0.54 and 0.0.55 require Flutter 3.47 /
Dart 3.13. Upgrade the package and Flutter together, checking Android and the
Nix production web build. Version 0.0.53 and `fl_chart` use Material internally;
our app does not install a Material compatibility layer. The Material icon font
is retained for shadcn's internal refresh indicator. Flutter localizations
requires `intl` 0.20.2 on this toolchain.

The login screen is shown before any dashboard is created. After login, the
Decibel dashboard loads first; weather and currency remain lazy.

## Staff login

Dex at `https://login.clubins.de` offers Pocket ID at `https://staff.clubins.de`,
Microsoft Entra, and Google as sign-in options. Dex has two public clients with
no client secret:

| Client                      | Exact callback                                    |
| --------------------------- | ------------------------------------------------- |
| `clubins-dashboard-web`     | `https://dashboard.clubins.de/oidc-callback.html` |
| `clubins-dashboard-android` | `de.clubins.app:/oauth2redirect`                  |

The web app uses a popup and keeps its login only in memory; reloading the page
requires a new login. Native apps save their login in secure storage and request
`offline_access` so Dex can refresh it across app restarts. The Android Gradle
manifest placeholder registers the private `de.clubins.app` callback scheme
through the OIDC plugin. Another installed app can claim the same scheme and
intercept a callback. The Apple apps currently reuse this native client and
callback with `ASWebAuthenticationSession`; their app identifiers are separate
from the callback scheme. Move Android to a verified HTTPS App Link after the Play signing
certificate is available, then update the Dex callback and app together.

`OIDC_DISCOVERY_URL` is a compile-time Dart define that defaults to Dex at
`login.clubins.de`. Override it with `--dart-define=OIDC_DISCOVERY_URL=...`
for testing. The production Nix web build derives it from
`hostEnv.domains.login`. The URL must be the standard OIDC well-known URL so
the issuer can be checked. `OIDC_CLIENT_ID` can also be set at build time;
otherwise the web and Android client IDs above are used. The production Nix
web build takes its client ID from `hostEnv`, so it matches Dex. Public Flutter
clients have no client secret; Dex's upstream connector secrets are kept only
in `server-infra/secrets/dex.env` (SOPS). The Google OAuth client uses the exact redirect URI
`https://login.clubins.de/callback` and supplies `GOOGLE_CLIENT_ID` and
`GOOGLE_CLIENT_SECRET` through that file. Web callbacks use the origin serving
the app, so a local test Dex must register that local `/oidc-callback.html` URL
and allow its origin in CORS. The production Dex client accepts only the
production callback.

The app sends Dex's signed ID token only to `api.clubins.de`, with redirects
disabled for those requests. This is currently a UI soft lock: the API remains
public, and any authenticated staff member sees the current demo venue. API
token verification and per-user venue grants are deferred. Logging out clears
the app's local session and dashboard state; it does not end a Pocket ID browser
session.

## Web deployment

`web.nix` builds the web app from the pinned Flutter toolchain and
`pubspec.lock`; Nix converts the lockfile during evaluation. The NixOS
configuration serves that build at
`https://dashboard.clubins.de` through Caddy. A normal NixOS rebuild updates
the dashboard together with the rest of the server configuration.

The web build bundles its resources and does not install a service worker.

## Android release signing

Android release builds use the application ID `de.clubins.app` and are not
signed with Flutter's shared debug key. Create `android/key.properties` locally
with the release keystore settings before producing a distributable build:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=your-key-alias
storeFile=/absolute/path/to/your-upload-keystore.jks
```

The properties file and keystores are ignored by Git. Without this file,
release builds remain unsigned and must not be distributed.
