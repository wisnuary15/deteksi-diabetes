import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool elevated;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? customShadows;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevated = true,
    this.backgroundColor,
    this.borderRadius,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow:
            customShadows ??
            (elevated
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: onTap != null
              ? InkWell(onTap: onTap, child: _buildContent())
              : _buildContent(),
        ),
      ),
    );

    return card;
  }

  Widget _buildContent() {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

class ModernGradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;

  const ModernGradientCard({
    super.key,
    required this.child,
    required this.gradientColors,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: gradientBegin,
          end: gradientEnd,
        ),
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: onTap != null
              ? InkWell(onTap: onTap, child: _buildContent())
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

class ModernInfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;

  const ModernInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (value != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    value!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (showArrow && onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}
