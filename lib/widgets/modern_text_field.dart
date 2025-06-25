import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ModernTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final bool autoFocus;
  final String? Function(String?)? validator;
  final bool readOnly;
  final Color? fillColor;

  const ModernTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.autoFocus = false,
    this.validator,
    this.readOnly = false,
    this.fillColor,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? AppColors.error
                  : _isFocused
                  ? AppColors.primary
                  : AppColors.border,
              width: _isFocused ? 2 : 1,
            ),
            color: widget.fillColor ?? AppColors.surface,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            autofocus: widget.autoFocus,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onEditingComplete: widget.onEditingComplete,
            validator: widget.validator,
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              counterText: '',
            ),
          ),
        ),
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText ?? widget.helperText!,
            style: TextStyle(
              fontSize: 12,
              color: widget.errorText != null
                  ? AppColors.error
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class ModernSearchField extends StatefulWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool showClearButton;
  final FocusNode? focusNode;

  const ModernSearchField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.showClearButton = true,
    this.focusNode,
  });

  @override
  State<ModernSearchField> createState() => _ModernSearchFieldState();
}

class _ModernSearchFieldState extends State<ModernSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showClear = _controller.text.isNotEmpty;
    });
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Cari...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: widget.showClearButton && _showClear
              ? GestureDetector(
                  onTap: _onClear,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
