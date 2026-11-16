import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomSoftCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const CustomSoftCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor = AppColors.surface,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);
    final effectiveBoxShadow = boxShadow ?? AppColors.softShadow;

    final container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveBorderRadius,
        border: border ?? Border.all(color: AppColors.outline.withValues(alpha: 0.8), width: 1),
        boxShadow: effectiveBoxShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: effectiveBorderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: effectiveBorderRadius is BorderRadius ? effectiveBorderRadius : BorderRadius.circular(16),
            child: Container(
              width: width,
              height: height,
              padding: padding ?? const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: effectiveBorderRadius,
                border: border ?? Border.all(color: AppColors.outline.withValues(alpha: 0.8), width: 1),
                boxShadow: effectiveBoxShadow,
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    return container;
  }
}
