import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class LapaktaniTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? labelTrailing;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;
  final String? helperText;
  final FocusNode? focusNode;

  const LapaktaniTextField({
    super.key,
    this.controller,
    this.label,
    this.labelTrailing,
    this.hintText,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.helperText,
    this.focusNode,
  });

  @override
  State<LapaktaniTextField> createState() => _LapaktaniTextFieldState();
}

class _LapaktaniTextFieldState extends State<LapaktaniTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  late TextEditingController _effectiveController;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _effectiveController = widget.controller ?? TextEditingController();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      initialValue: _effectiveController.text,
      builder: (FormFieldState<String> state) {
        final hasError = state.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (widget.labelTrailing != null)
                    Text(
                      widget.labelTrailing!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: hasError
                    ? Border.all(color: const Color(0xFFEF4444), width: 1.5)
                    : _isFocused
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: hasError
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          blurRadius: 0,
                          spreadRadius: 3,
                        ),
                      ]
                    : _isFocused
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              blurRadius: 0,
                              spreadRadius: 3,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
              ),
              child: Row(
                children: [
                  if (widget.prefix != null)
                    widget.prefix!
                  else if (widget.prefixIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, right: 6),
                      child: Icon(
                        widget.prefixIcon,
                        size: 19,
                        color: _isFocused
                            ? AppColors.primary
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _effectiveController,
                      focusNode: _focusNode,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      readOnly: widget.readOnly,
                      maxLength: widget.maxLength,
                      onTap: widget.onTap,
                      onChanged: (value) {
                        state.didChange(value);
                        widget.onChanged?.call(value);
                      },
                      onSubmitted: widget.onSubmitted,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                        counterText: '',
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: widget.prefixIcon == null &&
                                  widget.prefix == null
                              ? 16
                              : 4,
                        ),
                      ),
                    ),
                  ),
                  if (widget.suffixIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: widget.suffixIcon!,
                    ),
                ],
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 13,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.errorText ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: -0.2, end: 0, duration: 200.ms)
            else if (widget.helperText != null)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 6),
                child: Text(
                  widget.helperText!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
