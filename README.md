# Clubins staff app

Flutter web and Android dashboard for Clubins venue sensor data — live
decibel levels today, with per-venue insights (activity, threshold exposure,
busiest nights, sensor health) landing as the next feature.

This repository is the `mobile-app/` slice extracted from the
[clubins-hack monorepo](https://github.com/lifelikemaik/clubins-hack)
(seed = monorepo commit `3383e7b`). The layout mirrors the monorepo so the
pinned Nix toolchain, the CI workflow, and `just` recipes work unchanged.

## Development

Requires Nix. From the repository root:

```sh
just mobile check   # analyze (incl. Material/Cupertino ui-check) + full test suite
just mobile deps    # flutter pub get
just mobile android # debug APK
just mobile web     # production web build
```

The UI uses `ShadcnApp` and `shadcn_flutter` components (pinned 0.0.53 for the
Flutter 3.41.9 / Dart 3.11.5 toolchain — upgrade Flutter and the package
together). Charts use `fl_chart` with shared styling in
`mobile-app/lib/widgets/chart_style.dart`. `just mobile analyze` also checks
that application code and widget tests do not introduce Material/Cupertino
imports or their icon sets.

## Staff login and API

OIDC sign-in via Dex (`https://login.clubins.de`); web keeps the session in
memory, native in secure storage. The app sends Dex's signed ID token only to
`api.clubins.de` with redirects disabled; the API is still public (soft lock —
per-user venue grants are deferred to the Keycloak plan). See
[mobile-app/README.md](mobile-app/README.md) for OIDC clients, callbacks,
Android signing, and web deployment details.
