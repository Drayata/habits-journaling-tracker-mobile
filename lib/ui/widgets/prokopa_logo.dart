import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProkopaLogo extends StatelessWidget {
  const ProkopaLogo({
    super.key,
    this.height = 40,
    this.width,
    this.isDarkMode,
  });

  final double height;
  final double? width;
  final bool? isDarkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode ?? (Theme.of(context).brightness == Brightness.dark);
    final asset = isDark
        ? 'assets/images/prokopa-darkmode.svg'
        : 'assets/images/prokopa.svg';

    return SvgPicture.asset(
      asset,
      height: height,
      width: width,
    );
  }
}
