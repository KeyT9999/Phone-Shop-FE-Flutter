import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
  });

  final String title;
  final IconData icon;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Icon(icon, size: 42, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
