import 'package:flutter/material.dart';

class AppSplash extends StatelessWidget {
  const AppSplash({
    super.key,
    this.debugStatus,
    this.elapsed,
    this.showDebug = false,
  });

  final String? debugStatus;
  final Duration? elapsed;
  final bool showDebug;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: SizedBox(
        width: 400,
        height: 400,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logos/logo2.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  'Please wait...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                if (showDebug && debugStatus != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${debugStatus!} (${elapsed?.inSeconds ?? 0}s)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
