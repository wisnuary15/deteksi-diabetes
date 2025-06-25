import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ModernLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;
  final bool showMessage;

  const ModernLoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
    this.message,
    this.showMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size * 0.08,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
      ),
    );

    if (showMessage && message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 12),
          Text(
            message!,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }
}

class ModernShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ModernShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ModernShimmerLoading> createState() => _ModernShimmerLoadingState();
}

class _ModernShimmerLoadingState extends State<ModernShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.border,
                AppColors.border.withOpacity(0.3),
                AppColors.border,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ModernStatusBadge extends StatelessWidget {
  final String text;
  final ModernStatusType type;
  final IconData? icon;
  final bool showIcon;

  const ModernStatusBadge({
    super.key,
    required this.text,
    required this.type,
    this.icon,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon ?? config.icon, size: 16, color: config.textColor),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  StatusConfig _getStatusConfig(ModernStatusType type) {
    switch (type) {
      case ModernStatusType.success:
        return StatusConfig(
          backgroundColor: AppColors.success.withOpacity(0.1),
          borderColor: AppColors.success.withOpacity(0.3),
          textColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case ModernStatusType.warning:
        return StatusConfig(
          backgroundColor: AppColors.warning.withOpacity(0.1),
          borderColor: AppColors.warning.withOpacity(0.3),
          textColor: AppColors.warning,
          icon: Icons.warning_amber_outlined,
        );
      case ModernStatusType.error:
        return StatusConfig(
          backgroundColor: AppColors.error.withOpacity(0.1),
          borderColor: AppColors.error.withOpacity(0.3),
          textColor: AppColors.error,
          icon: Icons.error_outline,
        );
      case ModernStatusType.info:
        return StatusConfig(
          backgroundColor: AppColors.secondary.withOpacity(0.1),
          borderColor: AppColors.secondary.withOpacity(0.3),
          textColor: AppColors.secondary,
          icon: Icons.info_outline,
        );
      case ModernStatusType.neutral:
        return StatusConfig(
          backgroundColor: AppColors.textSecondary.withOpacity(0.1),
          borderColor: AppColors.textSecondary.withOpacity(0.3),
          textColor: AppColors.textSecondary,
          icon: Icons.circle_outlined,
        );
    }
  }
}

enum ModernStatusType { success, warning, error, info, neutral }

class StatusConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;

  StatusConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });
}

class ModernProgressIndicator extends StatelessWidget {
  final double progress;
  final String? label;
  final Color? color;
  final double height;
  final bool showPercentage;

  const ModernProgressIndicator({
    super.key,
    required this.progress,
    this.label,
    this.color,
    this.height = 8,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (showPercentage)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ModernPulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  const ModernPulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minOpacity = 0.5,
    this.maxOpacity = 1.0,
  });

  @override
  State<ModernPulseAnimation> createState() => _ModernPulseAnimationState();
}

class _ModernPulseAnimationState extends State<ModernPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(opacity: _animation.value, child: widget.child);
      },
    );
  }
}
