import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppPageHeading extends StatelessWidget {
  const AppPageHeading({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.textAlign = TextAlign.start,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            textAlign: textAlign,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          title,
          textAlign: textAlign,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.12,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class AppSectionHeading extends StatelessWidget {
  const AppSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: clipBehavior,
    child: Padding(padding: padding, child: child),
  );
}
