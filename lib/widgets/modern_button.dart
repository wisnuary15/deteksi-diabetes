import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ModernButtonVariant { primary, secondary, outlined, text, danger, success }

enum ModernButtonSize { small, medium, large }

class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonVariant variant;
  final ModernButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final String? tooltip;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ModernButtonVariant.primary,
    this.size = ModernButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget button = _buildButton(theme);

    if (tooltip != null && onPressed != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildButton(ThemeData theme) {
    final colors = _getColors(theme);
    final dimensions = _getDimensions();

    if (variant == ModernButtonVariant.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: colors.foreground,
          padding: dimensions.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dimensions.borderRadius),
          ),
        ),
        child: _buildContent(colors, dimensions),
      );
    }

    if (variant == ModernButtonVariant.outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.foreground,
          side: BorderSide(
            color: colors.border ?? colors.foreground,
            width: 1.5,
          ),
          padding: dimensions.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dimensions.borderRadius),
          ),
        ),
        child: _buildContent(colors, dimensions),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        elevation: variant == ModernButtonVariant.secondary ? 0 : 2,
        shadowColor: colors.background.withOpacity(0.3),
        padding: dimensions.padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dimensions.borderRadius),
        ),
      ),
      child: _buildContent(colors, dimensions),
    );
  }

  Widget _buildContent(ButtonColors colors, ButtonDimensions dimensions) {
    if (isLoading) {
      return SizedBox(
        height: dimensions.iconSize,
        width: dimensions.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dimensions.iconSize),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: dimensions.fontSize)),
        ],
      );
    }

    return Text(text, style: TextStyle(fontSize: dimensions.fontSize));
  }

  ButtonColors _getColors(ThemeData theme) {
    switch (variant) {
      case ModernButtonVariant.primary:
        return ButtonColors(
          background: AppColors.primary,
          foreground: Colors.white,
        );
      case ModernButtonVariant.secondary:
        return ButtonColors(
          background: AppColors.surface,
          foreground: AppColors.textPrimary,
          border: AppColors.border,
        );
      case ModernButtonVariant.outlined:
        return ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.primary,
          border: AppColors.primary,
        );
      case ModernButtonVariant.text:
        return ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.primary,
        );
      case ModernButtonVariant.danger:
        return ButtonColors(
          background: AppColors.error,
          foreground: Colors.white,
        );
      case ModernButtonVariant.success:
        return ButtonColors(
          background: AppColors.success,
          foreground: Colors.white,
        );
    }
  }

  ButtonDimensions _getDimensions() {
    switch (size) {
      case ModernButtonSize.small:
        return ButtonDimensions(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          fontSize: 14,
          iconSize: 16,
          borderRadius: 8,
        );
      case ModernButtonSize.medium:
        return ButtonDimensions(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          fontSize: 16,
          iconSize: 18,
          borderRadius: 12,
        );
      case ModernButtonSize.large:
        return ButtonDimensions(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          fontSize: 18,
          iconSize: 20,
          borderRadius: 16,
        );
    }
  }
}

class ButtonColors {
  final Color background;
  final Color foreground;
  final Color? border;

  ButtonColors({
    required this.background,
    required this.foreground,
    this.border,
  });
}

class ButtonDimensions {
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;
  final double borderRadius;

  ButtonDimensions({
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.borderRadius,
  });
}
