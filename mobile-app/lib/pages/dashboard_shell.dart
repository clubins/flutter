import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../services/clubins_api_service.dart';
import '../widgets/clubins_logo.dart';
import 'currency_page.dart';
import 'decibel_page.dart';
import 'weather_page.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.idToken,
    required this.onLogout,
  });

  final String? Function() idToken;
  final Future<void> Function() onLogout;
  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;
  late final ClubinsApiService _api;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _api = ClubinsApiService(idToken: widget.idToken);
    _pages = [DecibelPage(service: _api), null, null];
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  List<Widget> get _destinations => [
    const NavigationItem(
      key: ValueKey(0),
      label: Text('Decibel'),
      child: Icon(LucideIcons.audioLines),
    ),
    const NavigationItem(
      key: ValueKey(1),
      label: Text('Weather'),
      child: Icon(LucideIcons.cloud),
    ),
    const NavigationItem(
      key: ValueKey(2),
      label: Text('Currencies'),
      child: Icon(LucideIcons.arrowLeftRight),
    ),
    NavigationItem(
      key: const ValueKey(3),
      selected: false,
      label: const Text('Log out'),
      child: const Icon(LucideIcons.logOut),
    ),
  ];

  List<Widget> get _pageStack => [
    for (final page in _pages) page ?? const SizedBox.shrink(),
  ];

  void _selectPage(int value) {
    if (value == 3) {
      widget.onLogout();
      return;
    }
    setState(() {
      _index = value;
      _pages[value] ??= switch (value) {
        1 => const WeatherPage(),
        2 => const CurrencyPage(),
        _ => DecibelPage(service: _api),
      };
    });
  }

  void _selectDestination(Key? key) {
    if (key is ValueKey<int>) _selectPage(key.value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        return Scaffold(
          footers: wide
              ? const []
              : [
                  SafeArea(
                    top: false,
                    child: NavigationBar(
                      alignment: NavigationBarAlignment.spaceBetween,
                      selectedKey: ValueKey(_index),
                      onSelected: _selectDestination,
                      children: _destinations,
                    ),
                  ),
                ],
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                NavigationRail(
                  labelType: NavigationLabelType.all,
                  selectedKey: ValueKey(_index),
                  onSelected: _selectDestination,
                  header: const [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: ClubinsLogo(size: 40),
                    ),
                  ],
                  children: _destinations,
                ),
              if (wide) const VerticalDivider(),
              Expanded(
                key: const ValueKey('dashboard-pages'),
                child: IndexedStack(index: _index, children: _pageStack),
              ),
            ],
          ),
        );
      },
    );
  }
}
