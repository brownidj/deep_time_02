import 'package:flutter/material.dart';
import 'package:deep_time_2/app/app_debug.dart';

class TimelineLoadingView extends StatelessWidget {
  const TimelineLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class TimelineErrorView extends StatelessWidget {
  const TimelineErrorView({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load timeline data.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (AppDebug.enabled) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TimelineEmptyView extends StatelessWidget {
  const TimelineEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'No timeline data available.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
