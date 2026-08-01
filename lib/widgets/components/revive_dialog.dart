import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'revive_button.dart';

/// Modal shell for the app. Built around one rule: on a dialog that carries
/// emergency-services messaging, that message is the visual focal point, not
/// a line of body text the user scrolls past to reach the dismiss button.
///
/// [emphasis] renders above the body in a bordered, accented block at title
/// weight, so "call emergency services first" cannot be skimmed over.
class ReviveDialog extends StatelessWidget {
  final IconData icon;
  final String title;

  /// The one sentence that must not be missed. Rendered large and accented,
  /// ahead of [body].
  final String? emphasis;
  final String body;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final String? dismissLabel;
  final VoidCallback? onDismiss;

  const ReviveDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.emphasis,
    this.onConfirm,
    this.dismissLabel,
    this.onDismiss,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget dialog,
    bool barrierDismissible = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => dialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xxl),
      child: Container(
        padding: AppSpacing.dialogPadding,
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: AppRadius.borderXl,
          border: Border.all(
            color: c.urgentAction.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: AppElevation.level3(isDark: context.isDarkMode),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: c.urgentActionSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: c.urgentAction, size: 36),
              ),
              AppSpacing.gapLg,
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.text.labelLarge?.copyWith(color: c.urgentAction),
              ),
              if (emphasis != null) ...[
                AppSpacing.gapLg,
                // The focal point. Accented block, title-weight type, its own
                // border — deliberately heavier than the body below it.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: c.urgentActionSubtle,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: c.urgentAction.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    emphasis!,
                    textAlign: TextAlign.center,
                    style: context.text.titleLarge?.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
              AppSpacing.gapLg,
              Text(
                body,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: c.textSecondary,
                ),
              ),
              AppSpacing.gapXl,
              ReviveButton(
                label: confirmLabel,
                onPressed: onConfirm ?? () => Navigator.of(context).pop(),
              ),
              if (dismissLabel != null) ...[
                AppSpacing.gapSm,
                ReviveButton(
                  label: dismissLabel!,
                  variant: ReviveButtonVariant.tertiary,
                  onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
