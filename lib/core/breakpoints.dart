import 'package:flutter/material.dart';

abstract final class Breakpoints {
  static const double phone = 360;
  static const double tablet = 768;
  static const double desktop = 1280;
  static const double wide = 1920;

  /// Максимальная ширина контента на больших экранах.
  static const double contentMax = 1400;
}

extension LayoutX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// < 768 — телефон: нижняя навигация, карточки.
  bool get isPhone => screenWidth < Breakpoints.tablet;

  /// ≥ 768 — боковая навигация.
  bool get isTabletOrUp => screenWidth >= Breakpoints.tablet;

  /// ≥ 1280 — таблицы и подписи у rail.
  bool get isDesktop => screenWidth >= Breakpoints.desktop;

  /// ≥ 1920 — ограничение ширины контента.
  bool get isWideDesktop => screenWidth >= Breakpoints.wide;

  /// Таблица вместо карточек.
  bool get useDataTable => isDesktop;
}
