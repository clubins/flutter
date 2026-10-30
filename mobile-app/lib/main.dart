import 'dart:async';

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'auth/auth_controller.dart';
import 'pages/dashboard_shell.dart';
import 'theme.dart';

void main() {
  runApp(const ClubinsApp());
}

class ClubinsApp extends StatefulWidget {
  const ClubinsApp({super.key, this.authController});

  final AuthController? authController;

  @override
  State<ClubinsApp> createState() => _ClubinsAppState();
}

class _ClubinsAppState extends State<ClubinsApp> {
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = widget.authController ?? DexAuthController();
    _auth.addListener(_onAuthChanged);
    unawaited(_auth.initialize());
  }

  void _onAuthChanged() => setState(() {});

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    if (widget.authController == null) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'Clubins dashboards',
      debugShowCheckedModeBanner: false,
      theme: clubinsTheme,
      home: _auth.idToken == null
          ? _LoginScreen(auth: _auth)
          : DashboardShell(
              idToken: () => _auth.idToken,
              onLogout: _auth.signOut,
            ),
    );
  }
}

class _LoginScreen extends StatelessWidget {
  const _LoginScreen({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Clubins staff',
                      style: Theme.of(context).typography.h2,
                    ),
                    const SizedBox(height: 12),
                    const Text('Sign in to view the dashboards.'),
                    const SizedBox(height: 24),
                    if (auth.error != null) ...[
                      Text(auth.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                    ],
                    PrimaryButton(
                      onPressed: auth.busy ? null : auth.signIn,
                      child: const Text('Sign in with staff account'),
                    ),
                    if (auth.busy) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
