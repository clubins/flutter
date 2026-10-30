import 'package:shadcn_flutter/shadcn_flutter.dart';

/// The Clubins logo, used for splash/boot, app icon and in-app branding.
class ClubinsLogo extends StatelessWidget {
  const ClubinsLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.15),
      child: Image.asset(
        'assets/images/logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
