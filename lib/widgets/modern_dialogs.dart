import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'modern_button.dart';

class ModernSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    ModernSnackBarType type = ModernSnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool showCloseButton = true,
  }) {
    final config = _getSnackBarConfig(type);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(config.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            if (showCloseButton) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ],
        ),
        backgroundColor: config.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  static SnackBarConfig _getSnackBarConfig(ModernSnackBarType type) {
    switch (type) {
      case ModernSnackBarType.success:
        return SnackBarConfig(
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case ModernSnackBarType.error:
        return SnackBarConfig(
          backgroundColor: AppColors.error,
          icon: Icons.error_outline,
        );
      case ModernSnackBarType.warning:
        return SnackBarConfig(
          backgroundColor: AppColors.warning,
          icon: Icons.warning_amber_outlined,
        );
      case ModernSnackBarType.info:
        return SnackBarConfig(
          backgroundColor: AppColors.primary,
          icon: Icons.info_outline,
        );
    }
  }
}

enum ModernSnackBarType { success, error, warning, info }

class SnackBarConfig {
  final Color backgroundColor;
  final IconData icon;

  SnackBarConfig({required this.backgroundColor, required this.icon});
}

class ModernDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? content,
    Widget? contentWidget,
    List<ModernDialogAction>? actions,
    bool barrierDismissible = true,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ModernDialogWidget(
        title: title,
        content: content,
        contentWidget: contentWidget,
        actions: actions,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    ModernButtonVariant confirmVariant = ModernButtonVariant.primary,
    IconData? icon,
    Color? iconColor,
  }) {
    return show<bool>(
      context,
      title: title,
      content: content,
      icon: icon,
      iconColor: iconColor,
      actions: [
        ModernDialogAction(
          text: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
          variant: ModernButtonVariant.outlined,
        ),
        ModernDialogAction(
          text: confirmText,
          onPressed: () => Navigator.of(context).pop(true),
          variant: confirmVariant,
        ),
      ],
    );
  }
}

class ModernDialogWidget extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? contentWidget;
  final List<ModernDialogAction>? actions;
  final IconData? icon;
  final Color? iconColor;

  const ModernDialogWidget({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    this.actions,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: AppColors.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (content != null || contentWidget != null) ...[
              const SizedBox(height: 16),
              if (contentWidget != null)
                contentWidget!
              else
                Text(
                  content!,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  for (int i = 0; i < actions!.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ModernButton(
                        text: actions![i].text,
                        onPressed: actions![i].onPressed,
                        variant: actions![i].variant,
                        size: ModernButtonSize.medium,
                        fullWidth: true,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ModernDialogAction {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonVariant variant;

  ModernDialogAction({
    required this.text,
    this.onPressed,
    this.variant = ModernButtonVariant.primary,
  });
}

class ModernBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ModernBottomSheetWidget(title: title, height: height, child: child),
    );
  }
}

class ModernBottomSheetWidget extends StatelessWidget {
  final Widget child;
  final String? title;
  final double? height;

  const ModernBottomSheetWidget({
    super.key,
    required this.child,
    this.title,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Divider(color: AppColors.border, height: 1),
          ],
          Flexible(
            child: Padding(padding: const EdgeInsets.all(20), child: child),
          ),
        ],
      ),
    );
  }
}
