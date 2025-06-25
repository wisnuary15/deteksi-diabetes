import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool useGradient;
  final List<Color>? gradientColors;

  const ModernAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.useGradient = false,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final hasBackButton =
        showBackButton && (ModalRoute.of(context)?.canPop ?? false);

    if (useGradient) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                gradientColors ??
                [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AppBar(
          title: titleWidget ?? (title != null ? Text(title!) : null),
          centerTitle: centerTitle,
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ?? Colors.white,
          elevation: 0,
          leading:
              leading ?? (hasBackButton ? _buildBackButton(context) : null),
          actions: actions,
          automaticallyImplyLeading: false,
        ),
      );
    }

    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.surface,
      foregroundColor: foregroundColor ?? AppColors.textPrimary,
      elevation: elevation,
      leading: leading ?? (hasBackButton ? _buildBackButton(context) : null),
      actions: actions,
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
    );
  }

  Widget? _buildBackButton(BuildContext context) {
    return IconButton(
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (foregroundColor ?? AppColors.textPrimary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.arrow_back_ios,
          size: 16,
          color: foregroundColor ?? AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ModernSliverAppBar extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool pinned;
  final bool floating;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool useGradient;
  final List<Color>? gradientColors;

  const ModernSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight = 200,
    this.flexibleSpace,
    this.backgroundColor,
    this.foregroundColor,
    this.useGradient = false,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      centerTitle: centerTitle,
      pinned: pinned,
      floating: floating,
      expandedHeight: expandedHeight,
      backgroundColor: backgroundColor ?? AppColors.surface,
      foregroundColor: foregroundColor ?? AppColors.textPrimary,
      elevation: 0,
      leading: leading,
      actions: actions,
      surfaceTintColor: Colors.transparent,
      flexibleSpace:
          flexibleSpace ??
          (useGradient
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          gradientColors ??
                          [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                )
              : null),
    );
  }
}
