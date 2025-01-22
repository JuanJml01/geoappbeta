import 'dart:ui';

import 'package:flutter/material.dart';

enum Mocha {
  base(color: Color(0xFF1E1E2E)),
  rosewater(color: Color(0xFFF5E0DC)),
  blue(color: Color(0xFF89B4FA)),
  crust(color: Color(0xFF11111B)),
  flamingo(color: Color(0xFFF2CDCD)),
  green(color: Color(0xFFA6E3A1)),
  lavender(color: Color(0xFFB4BEFE)),
  mantle(color: Color(0xFF181825)),
  maroon(color: Color(0xFFEBA0AC)),
  mauve(color: Color(0xFFCBA6F7)),
  overlay0(color: Color(0xFF6C7086)),
  overlay1(color: Color(0xFF7F849C)),
  overlay2(color: Color(0xFF9399B2)),
  peach(color: Color(0xFFFAB387)),
  pink(color: Color(0xFFF5C2E7)),
  red(color: Color(0xFFF38BA8)),
  sapphire(color: Color(0xFF74C7EC)),
  sky(color: Color(0xFF89DCEB)),
  subtext0(color: Color(0xFFA6ADC8)),
  subtext1(color: Color(0xFFBAC2DE)),
  surface0(color: Color(0xFF313244)),
  surface1(color: Color(0xFF45475A)),
  surface2(color: Color(0xFF585B70)),
  teal(color: Color(0xFF94E2D5)),
  text(color: Color(0xFFCDD6F4)),
  yellow(color: Color(0xFFF9E2AF));

  final Color color;

  const Mocha({required this.color});
}
