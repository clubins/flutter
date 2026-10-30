import 'package:shadcn_flutter/shadcn_flutter.dart';

final clubinsTheme = ThemeData(
  colorScheme: ColorSchemes.lightZinc.copyWith(
    primary: () => const Color(0xff2764a5),
    primaryForeground: () => const Color(0xffffffff),
    ring: () => const Color(0xff2764a5),
    chart1: () => const Color(0xff2764a5),
    chart2: () => const Color(0xff168577),
    chart3: () => const Color(0xffb65824),
  ),
  radius: 0.75,
);
