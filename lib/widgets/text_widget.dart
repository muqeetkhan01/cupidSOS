import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class TextWidget extends StatelessWidget {
  final String text;
  final double size; // base size in sp
  final FontWeight weight;
  final Color color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final double? height;
  final TextDecoration decoration;

  const TextWidget({
    super.key,
    required this.text,
    this.size = 14,
    this.weight = FontWeight.w400,
    this.color = Colors.black,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.visible,
    this.height,
    this.decoration = TextDecoration.none,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: GoogleFonts.poppins(
        fontSize: size.sp,
        fontWeight: weight,
        color: color,
        height: height,
        decoration: decoration,
      ),
    );
  }
}