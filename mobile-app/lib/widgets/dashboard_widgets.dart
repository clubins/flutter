import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'clubins_logo.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.title, this.onRefresh});

  final String title;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ).large().semiBold(),
    leading: const [ClubinsLogo(size: 32)],
    trailing: [
      Tooltip(
        tooltip: (_) => const Text('Refresh'),
        child: Semantics(
          label: 'Refresh $title',
          button: true,
          child: IconButton.ghost(
            onPressed: onRefresh,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ),
      ),
    ],
  );
}

class DashboardErrorCard extends StatelessWidget {
  const DashboardErrorCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Basic(
          leading: const Icon(LucideIcons.circleAlert),
          title: Text(title),
          subtitle: Text(message),
        ),
        const SizedBox(height: 12),
        OutlineButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
