import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Visual weight of a [ReviveButton].
enum ReviveButtonVariant {
  /// Filled coral. Reserved for the single most important action on a screen.
  /// More than one primary button per screen defeats the point.
  primary,

  /// Outlined. Supporting actions that sit alongside a primary.
  secondary,

  /// Text-only. Low-stakes, dismissive, or tertiary actions.
  tertiary,
}

/// Button size. [critical] exists for the live CPR screen, where controls are
/// hit one-handed, under stress, without looking directly at the target.
enum ReviveButtonSize { standard, critical }

/// The app's button. Theme-driven, with explicit disabled / pressed / loading
/// states rather than relying on Material's defaults.
///
/// Loading deliberately keeps the button's footprint fixed and swaps the label
/// for a spinner, so the layout does not jump while an action is in flight.
class ReviveButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ReviveButtonVariant variant;
  final ReviveButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  /// Overrides the semantic label announced by screen readers. Defaults to
  /// [label], which is usually right; set this when the visible text is an
  /// abbreviation or would read poorly aloud.
  final String? semanticLabel;

  const ReviveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ReviveButtonVariant.primary,
    this.size = ReviveButtonSize.standard,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.semanticLabel,
  });

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  State<ReviveButton> createState() => _ReviveButtonState();
}

class _ReviveButtonState extends State<ReviveButton> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  /// Enter and Space activate a focused button, matching the platform
  /// convention for keyboard and switch-access users. Without this the button
  /// can be reached by focus but never triggered.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget._isEnabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      widget.onPressed!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = ResolvedMotion.of(context);
    final enabled = widget._isEnabled;

    final double height = switch (widget.size) {
      ReviveButtonSize.standard => AppTouchTarget.comfortable,
      ReviveButtonSize.critical => AppTouchTarget.critical,
    };

    final Color background = switch (widget.variant) {
      ReviveButtonVariant.primary =>
        _pressed ? c.urgentActionPressed : c.urgentAction,
      ReviveButtonVariant.secondary =>
        _pressed ? c.surfaceOverlay : Colors.transparent,
      ReviveButtonVariant.tertiary =>
        _pressed ? c.surfaceOverlay : Colors.transparent,
    };

    final Color foreground = switch (widget.variant) {
      ReviveButtonVariant.primary => c.onUrgentAction,
      ReviveButtonVariant.secondary => c.textPrimary,
      ReviveButtonVariant.tertiary => c.urgentAction,
    };

    final BoxBorder? border = widget.variant == ReviveButtonVariant.secondary
        ? Border.all(
            color: enabled ? c.borderStrong : c.borderSubtle,
            width: 1.5,
          )
        : null;

    // Disabled state is communicated by fill, border AND text colour together,
    // not opacity alone, so it survives high-contrast and greyscale modes.
    final Color effectiveBackground = enabled
        ? background
        : (widget.variant == ReviveButtonVariant.primary
              ? c.noDataNeutral.withValues(alpha: 0.22)
              : Colors.transparent);
    final Color effectiveForeground = enabled ? foreground : c.textTertiary;

    final child = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveForeground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: effectiveForeground),
                AppSpacing.hGapSm,
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: context.text.labelLarge?.copyWith(
                    color: effectiveForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      // Communicates in-flight state to screen readers, which otherwise see an
      // unchanged button and no explanation for why nothing happened.
      hint: widget.isLoading ? 'Busy' : null,
      // Required: excludeSemantics drops the GestureDetector's own tap action,
      // and assistive tech activates controls by dispatching a *semantic* tap.
      // Without this the button is announced but cannot be pressed.
      onTap: enabled ? widget.onPressed : null,
      // Reachable by keyboard and switch access, not just touch. Deliberately
      // focusable even when disabled: a disabled control that is invisible to
      // a screen reader leaves the user unable to tell why the action is
      // missing. It is reached, and announced as disabled.
      focusable: true,
      focused: _focused,
      excludeSemantics: true,
      child: Focus(
        canRequestFocus: enabled,
        onKeyEvent: _handleKey,
        onFocusChange: (value) => setState(() => _focused = value),
        child: GestureDetector(
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: motion.duration(AppMotion.fast),
            curve: motion.curve(AppMotion.standard),
            height: height,
            width: widget.fullWidth ? double.infinity : null,
            padding: widget.fullWidth
                ? null
                : const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: effectiveBackground,
              borderRadius: AppRadius.borderMd,
              // A visible focus ring: a control that can be focused but does
              // not show it is only half accessible.
              border: _focused
                  ? Border.all(color: c.textPrimary, width: 2)
                  : border,
              boxShadow:
                  enabled &&
                      widget.variant == ReviveButtonVariant.primary &&
                      !_pressed
                  ? AppElevation.level1(isDark: context.isDarkMode)
                  : AppElevation.none,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
