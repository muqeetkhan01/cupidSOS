import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

enum ButtonVariant { solid, outline, gradient }

class ButtonWidget extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final double height;
  final double width;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? padding;
  final bool enableShadow;
  final List<Color>? gradient;
  final ButtonVariant variant;
  final Color borderColor;

  // ✅ NEW
  final String? iconAsset;
  final IconData? icon;
  final Color? iconColor;

  const ButtonWidget({
    super.key,
    required this.text,
    required this.onTap,
    this.height = 6.5,
    this.width = 100,
    this.radius = 32,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.padding,
    this.enableShadow = true,
    this.gradient,
    this.variant = ButtonVariant.solid,
    this.borderColor = Colors.transparent,
    this.iconAsset, // ✅ NEW
    this.icon,
    this.iconColor,
  });

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = widget.backgroundColor ?? scheme.onSurface;
    final textColor = widget.textColor ??
        (widget.variant == ButtonVariant.outline
            ? scheme.onSurface
            : scheme.onPrimary);
    final borderColor = widget.borderColor == Colors.transparent
        ? scheme.outlineVariant
        : widget.borderColor;
    final shadowColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withOpacity(0.28)
        : Colors.black.withOpacity(0.12);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: widget.height.h,
          width: widget.width.w,
          padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            color:
                widget.variant == ButtonVariant.solid ? backgroundColor : null,
            gradient: widget.variant == ButtonVariant.gradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.gradient!,
                  )
                : null,
            border: widget.variant == ButtonVariant.outline
                ? Border.all(color: borderColor, width: 1.5)
                : null,
            boxShadow: widget.enableShadow
                ? [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.iconAsset != null) ...[
                Image.asset(
                  widget.iconAsset!,
                  width: 5.w,
                  height: 5.w,
                ),
                SizedBox(width: 3.w),
              ] else if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 5.w,
                  color: widget.iconColor ?? textColor,
                ),
                SizedBox(width: 3.w),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.fontSize.sp,
                  fontWeight: widget.fontWeight,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
