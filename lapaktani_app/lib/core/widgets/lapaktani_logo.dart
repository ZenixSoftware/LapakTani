import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LapaktaniLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const LapaktaniLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo_lapaktani.svg',
      width: width,
      height: height,
      fit: fit,
    );
  }
}
