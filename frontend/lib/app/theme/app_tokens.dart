import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.heroBlue,
    required this.navy,
    required this.success,
    required this.warning,
    required this.infoSurface,
    required this.radius,
    required this.pagePadding,
  });

  final Color heroBlue;
  final Color navy;
  final Color success;
  final Color warning;
  final Color infoSurface;
  final double radius;
  final double pagePadding;

  @override
  AppTokens copyWith({
    Color? heroBlue,
    Color? navy,
    Color? success,
    Color? warning,
    Color? infoSurface,
    double? radius,
    double? pagePadding,
  }) => AppTokens(
    heroBlue: heroBlue ?? this.heroBlue,
    navy: navy ?? this.navy,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    infoSurface: infoSurface ?? this.infoSurface,
    radius: radius ?? this.radius,
    pagePadding: pagePadding ?? this.pagePadding,
  );

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      heroBlue: Color.lerp(heroBlue, other.heroBlue, t)!,
      navy: Color.lerp(navy, other.navy, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      radius: lerpDouble(radius, other.radius, t),
      pagePadding: lerpDouble(pagePadding, other.pagePadding, t),
    );
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;
