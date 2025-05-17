import 'dart:ui';

import 'package:flutter/material.dart';

enum EcoPalette {
  // Colores principales
  greenPrimary(color: Color(0xFF2E8B57)),    // Verde esmeralda más profundo
  greenLight(color: Color(0xFF8FBC8F)),      // Verde claro más suave
  greenDark(color: Color(0xFF1B5E20)),       // Verde oscuro más elegante
  
  // Colores de acento
  accent(color: Color(0xFF66BB6A)),          // Verde acento más vibrante
  accentLight(color: Color(0xFFA5D6A7)),     // Verde acento claro
  amber(color: Color(0xFFFFC107)),           // Ámbar para calificaciones
  blue(color: Color(0xFF2196F3)),            // Azul para seguimiento
  
  // Colores neutros
  beige(color: Color(0xFFF5F5DC)),           // Beige
  sand(color: Color(0xFFF9F6F0)),            // Arena más clara y elegante
  brown(color: Color(0xFF795548)),           // Marrón más oscuro
  
  // Colores base
  white(color: Color(0xFFFFFFFF)),           // Blanco
  black(color: Color(0xFF212121)),           // Negro
  gray(color: Color(0xFFBDBDBD)),            // Gris
  grayLight(color: Color(0xFFEEEEEE)),       // Gris claro
  
  // Colores de estado
  success(color: Color(0xFF4CAF50)),         // Verde éxito
  warning(color: Color(0xFFFFB74D)),         // Naranja advertencia
  error(color: Color(0xFFE57373)),           // Rojo error
  info(color: Color(0xFF64B5F6));            // Azul información

  final Color color;
  const EcoPalette({required this.color});
}

// Definición de la paleta de colores Mocha
enum Mocha {
  // Colores base
  rosewater(color: Color(0xFFF5E0DC)),
  flamingo(color: Color(0xFFF2CDCD)),
  pink(color: Color(0xFFF5C2E7)),
  mauve(color: Color(0xFFCBA6F7)),
  red(color: Color(0xFFF38BA8)),
  maroon(color: Color(0xFFEBA0AC)),
  peach(color: Color(0xFFFAB387)),
  yellow(color: Color(0xFFF9E2AF)),
  green(color: Color(0xFFA6E3A1)),
  teal(color: Color(0xFF94E2D5)),
  sky(color: Color(0xFF89DCEB)),
  sapphire(color: Color(0xFF74C7EC)),
  blue(color: Color(0xFF89B4FA)),
  lavender(color: Color(0xFFB4BEFE)),
  
  // Fondos y superficies
  text(color: Color(0xFFCDD6F4)),
  subtext1(color: Color(0xFFBAC2DE)),
  subtext0(color: Color(0xFFA6ADC8)),
  overlay2(color: Color(0xFF9399B2)),
  overlay1(color: Color(0xFF7F849C)),
  overlay0(color: Color(0xFF6C7086)),
  surface2(color: Color(0xFF585B70)),
  surface1(color: Color(0xFF45475A)),
  surface0(color: Color(0xFF313244)),
  base(color: Color(0xFF1E1E2E)),
  mantle(color: Color(0xFF181825)),
  crust(color: Color(0xFF11111B));
  
  final Color color;
  const Mocha({required this.color});
  
  // Obtener todos los colores como un mapa
  static Map<String, Color> get colorsMap {
    return {
      for (var value in Mocha.values) value.name: value.color,
    };
  }
  
  // ColorScheme para tema claro basado en Mocha
  static ColorScheme get lightColorScheme {
    return ColorScheme(
      primary: Mocha.green.color,
      onPrimary: Colors.white,
      secondary: Mocha.teal.color,
      onSecondary: Colors.white,
      tertiary: Mocha.mauve.color,
      onTertiary: Colors.white,
      error: Mocha.red.color,
      onError: Colors.white,
      background: Mocha.rosewater.color.withOpacity(0.2),
      onBackground: Mocha.base.color,
      surface: Colors.white,
      onSurface: Mocha.base.color,
      surfaceTint: Mocha.green.color.withOpacity(0.1),
      brightness: Brightness.light,
    );
  }
  
  // ColorScheme para tema oscuro basado en Mocha
  static ColorScheme get darkColorScheme {
    return ColorScheme(
      primary: Mocha.green.color,
      onPrimary: Mocha.crust.color,
      secondary: Mocha.teal.color,
      onSecondary: Mocha.crust.color,
      tertiary: Mocha.mauve.color,
      onTertiary: Mocha.crust.color,
      error: Mocha.red.color,
      onError: Mocha.crust.color,
      background: Mocha.base.color,
      onBackground: Mocha.text.color,
      surface: Mocha.mantle.color,
      onSurface: Mocha.text.color,
      surfaceTint: Mocha.green.color.withOpacity(0.2),
      brightness: Brightness.dark,
    );
  }
}
