import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class EnterpriseCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool showHoverEffect;
  final bool showPressAnimation;

  const EnterpriseCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradientColors,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.showHoverEffect = false,
    this.showPressAnimation = true,
  });

  @override
  State<EnterpriseCard> createState() => _EnterpriseCardState();
}

class _EnterpriseCardState extends State<EnterpriseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.showPressAnimation && widget.onTap != null) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.showPressAnimation && widget.onTap != null) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.showPressAnimation && widget.onTap != null) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.showPressAnimation ? _scaleAnimation.value : 1.0,
            child: GestureDetector(
              onTap: widget.onTap,
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: widget.padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: widget.gradientColors != null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.gradientColors!,
                        )
                      : null,
                  color: widget.gradientColors == null
                      ? (widget.backgroundColor ?? Colors.white)
                      : null,
                  borderRadius:
                      widget.borderRadius ?? BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isPressed ? 0.08 : 0.04),
                      blurRadius: _isPressed ? 8 : 12,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                    if (widget.showHoverEffect)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                  ],
                  border: Border.all(
                    color: AppColors.neutral200.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProfileStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ProfileStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EnterpriseCard(
      onTap: onTap,
      showHoverEffect: onTap != null,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ProfessionalSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final IconData? titleIcon;

  const ProfessionalSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.padding,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showBorder;

  const ActionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return EnterpriseCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
        ],
      ),
    );
  }
}
