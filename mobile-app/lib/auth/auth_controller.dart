import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';

const _discoveryUrl = String.fromEnvironment(
  'OIDC_DISCOVERY_URL',
  defaultValue: 'https://login.clubins.de/.well-known/openid-configuration',
);
const _clientId = String.fromEnvironment('OIDC_CLIENT_ID');

abstract class AuthController extends ChangeNotifier {
  bool get ready;
  bool get busy;
  String? get error;
  String? get idToken;

  Future<void> initialize();
  Future<void> signIn();
  Future<void> signOut();
}

class DexAuthController extends AuthController {
  DexAuthController() : _manager = _createManager();

  static OidcUserManager _createManager() => OidcUserManager.lazy(
    discoveryDocumentUri: Uri.parse(_discoveryUrl),
    clientCredentials: OidcClientAuthentication.none(
      clientId: _clientId.isNotEmpty
          ? _clientId
          : kIsWeb
          ? 'clubins-dashboard-web'
          : 'clubins-dashboard-android',
    ),
    store: kIsWeb
        ? OidcMemoryStore()
        : OidcDefaultStore(
            secureStorageInstance:
                OidcDefaultStore.createHardenedSecureStorage(),
          ),
    settings: OidcUserManagerSettings(
      initMode: OidcInitMode.blockingValidate,
      redirectUri: kIsWeb
          ? Uri.base.resolve('/oidc-callback.html')
          : Uri.parse('de.clubins.app:/oauth2redirect'),
      scope: kIsWeb
          ? const ['openid', 'profile', 'email']
          : const ['openid', 'profile', 'email', 'offline_access'],
      strictIssuerValidation: true,
      allowedIdTokenAlgorithms: const ['RS256'],
      options: const OidcPlatformSpecificOptions(
        web: OidcPlatformSpecificOptions_Web(
          navigationMode: OidcPlatformSpecificOptions_Web_NavigationMode.popup,
          flowTimeoutSeconds: 180,
        ),
      ),
    ),
  );

  OidcUserManager _manager;
  StreamSubscription<OidcUser?>? _userSubscription;
  Timer? _expiryTimer;
  OidcUser? _user;
  bool _signedOut = false;
  bool _ready = false;
  bool _busy = false;
  String? _error;

  @override
  bool get ready => _ready;
  @override
  bool get busy => _busy;
  @override
  String? get error => _error;

  @override
  String? get idToken {
    final user = _user;
    final expiry = user?.claims.expiry;
    if (user == null || expiry == null || !expiry.isAfter(DateTime.now())) {
      return null;
    }
    return user.idToken;
  }

  @override
  Future<void> initialize() async {
    if (_ready || _busy) return;
    _busy = true;
    notifyListeners();
    try {
      await _manager.init();
      _userSubscription ??= _manager.userChanges().listen(_setUser);
      _setUser(_manager.currentUser);
      _ready = true;
      _error = null;
    } catch (_) {
      try {
        await _manager.dispose();
      } catch (_) {
        // A failed manager is replaced even if cleanup also fails.
      }
      _manager = _createManager();
      _error = 'Could not connect to staff login. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> signIn() async {
    if (_busy) return;
    if (!_ready) {
      await initialize();
      if (!_ready) return;
    }
    _busy = true;
    _signedOut = false;
    _error = null;
    notifyListeners();
    try {
      final user = await _manager.loginAuthorizationCodeFlow(
        includeIdTokenHintFromCurrentUser: false,
      );
      _setUser(user);
      if (user == null) {
        _signedOut = true;
        _error = 'Login was not completed. Please try again.';
      }
    } catch (_) {
      _signedOut = true;
      _error = 'Login was not completed. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> signOut() async {
    _signedOut = true;
    _busy = true;
    _setUser(null); // Drop the dashboard and token before any async cleanup.
    _error = null;
    try {
      await _manager.forgetUser();
    } catch (_) {
      _error = 'Could not clear the saved login. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _setUser(OidcUser? user) {
    if (_signedOut && user != null) return;
    _expiryTimer?.cancel();
    _user = user;
    final expiry = user?.claims.expiry;
    if (expiry != null && expiry.isAfter(DateTime.now())) {
      _expiryTimer = Timer(expiry.difference(DateTime.now()), () {
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    unawaited(_userSubscription?.cancel());
    unawaited(_manager.dispose());
    super.dispose();
  }
}
