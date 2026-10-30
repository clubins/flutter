import 'package:clubins/auth/auth_controller.dart';
import 'package:clubins/main.dart';
import 'package:clubins/pages/currency_page.dart';
import 'package:clubins/pages/dashboard_shell.dart';
import 'package:clubins/pages/decibel_page.dart';
import 'package:clubins/pages/weather_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('dashboard is created only after login and removed on logout', (
    tester,
  ) async {
    final auth = _FakeAuth();
    final requests = <http.Request>[];
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(
      () async {
        await tester.pumpWidget(ClubinsApp(authController: auth));
        expect(find.text('Sign in with staff account'), findsOneWidget);
        expect(find.byType(DashboardShell), findsNothing);
        expect(find.byType(DecibelPage), findsNothing);
        expect(find.byType(WeatherPage), findsNothing);
        expect(find.byType(CurrencyPage), findsNothing);
        expect(requests, isEmpty);

        await tester.tap(find.text('Sign in with staff account'));
        await tester.pump();
        expect(find.byType(DecibelPage), findsOneWidget);
        expect(find.byType(WeatherPage), findsNothing);
        expect(find.byType(CurrencyPage), findsNothing);
        await tester.pump();
        expect(requests, isNotEmpty);

        final decibelState = tester.state(find.byType(DecibelPage));
        await tester.tap(find.text('7D'));
        await tester.pump();
        tester.view.physicalSize = const Size(390, 844);
        await tester.pump();
        expect(tester.state(find.byType(DecibelPage)), same(decibelState));
        expect(
          tester
              .widgetList<Toggle>(find.byType(Toggle))
              .singleWhere((toggle) => toggle.value)
              .child,
          isA<Text>().having((text) => text.data, 'selected range', '7D'),
        );

        await tester.tap(find.text('Weather').last);
        await tester.pump();
        expect(find.byType(WeatherPage), findsOneWidget);
        expect(find.byType(CurrencyPage), findsNothing);
        await tester.tap(find.text('Decibel').last);
        await tester.pump();
        expect(tester.state(find.byType(DecibelPage)), same(decibelState));
        tester.view.physicalSize = const Size(1100, 900);
        await tester.pump();
        expect(tester.state(find.byType(DecibelPage)), same(decibelState));

        await tester.tap(find.text('Log out').last);
        await tester.pump();
        expect(auth.idToken, isNull);
        expect(find.byType(DashboardShell), findsNothing);
        expect(find.byType(DecibelPage), findsNothing);
        expect(find.text('Sign in with staff account'), findsOneWidget);
      },
      () => MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/sensors')) {
          return http.Response('{"sensors":[]}', 200);
        }
        return http.Response(
          '{"from":"2026-01-01T00:00:00Z","to":"2026-01-01T00:00:00Z","points":0,"sensors":[]}',
          200,
        );
      }),
    );
  });

  testWidgets('login fits a narrow screen with large text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(ClubinsApp(authController: _FakeAuth()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Sign in with staff account'), findsOneWidget);
  });

  testWidgets('failed login stays locked and shows an error', (tester) async {
    final auth = _FakeAuth(failLogin: true);
    await tester.pumpWidget(ClubinsApp(authController: auth));
    await tester.tap(find.text('Sign in with staff account'));
    await tester.pump();
    expect(
      find.text('Login was not completed. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(DashboardShell), findsNothing);
  });
}

class _FakeAuth extends AuthController {
  _FakeAuth({this.failLogin = false});

  final bool failLogin;
  String? token;
  String? message;

  @override
  bool get ready => true;
  @override
  bool get busy => false;
  @override
  String? get error => message;
  @override
  String? get idToken => token;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> signIn() async {
    if (failLogin) {
      message = 'Login was not completed. Please try again.';
    } else {
      token = 'test-id-token';
    }
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    token = null;
    notifyListeners();
  }
}
