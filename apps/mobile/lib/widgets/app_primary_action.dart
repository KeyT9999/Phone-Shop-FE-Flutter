import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppPrimaryAction extends StatelessWidget {
  const AppPrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = Theme.of(context).colorScheme.onPrimary;
    final child = isLoading
        ? Semantics(
            label: 'Đang xử lý: $label',
            liveRegion: true,
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                color: foregroundColor,
                strokeWidth: 2,
              ),
            ),
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: AppSpacing.xs),
              Text(label),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(onPressed: onPressed, child: child),
    );
  }
}
