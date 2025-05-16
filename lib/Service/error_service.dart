import 'package:flutter/material.dart';
import 'package:geoappbeta/mocha.dart';

/// Servicio para manejar errores y mostrar mensajes amigables al usuario
class ErrorService {
  /// Muestra un diálogo de error personalizado
  static Future<void> mostrarError({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    String? botonTexto,
    VoidCallback? onPressed,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: EcoPalette.white.color,
          title: Row(
            children: [
              Icon(Icons.error_outline, color: EcoPalette.error.color),
              SizedBox(width: 10),
              Text(
                titulo,
                style: TextStyle(
                  color: EcoPalette.greenDark.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              mensaje,
              style: TextStyle(
                color: EcoPalette.black.color,
                fontSize: 16,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: EcoPalette.greenPrimary.color,
                foregroundColor: EcoPalette.white.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: onPressed ?? () {
                Navigator.of(context).pop();
              },
              child: Text(botonTexto ?? 'Entendido'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un mensaje de éxito personalizado
  static Future<void> mostrarExito({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    String? botonTexto,
    VoidCallback? onPressed,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: EcoPalette.white.color,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: EcoPalette.success.color),
              SizedBox(width: 10),
              Text(
                titulo,
                style: TextStyle(
                  color: EcoPalette.greenDark.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              mensaje,
              style: TextStyle(
                color: EcoPalette.black.color,
                fontSize: 16,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: EcoPalette.greenPrimary.color,
                foregroundColor: EcoPalette.white.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: onPressed ?? () {
                Navigator.of(context).pop();
              },
              child: Text(botonTexto ?? 'Aceptar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un mensaje de advertencia personalizado
  static Future<void> mostrarAdvertencia({
    required BuildContext context,
    required String titulo,
    required String mensaje,
    String? botonTexto,
    VoidCallback? onPressed,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: EcoPalette.white.color,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: EcoPalette.warning.color),
              SizedBox(width: 10),
              Text(
                titulo,
                style: TextStyle(
                  color: EcoPalette.greenDark.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              mensaje,
              style: TextStyle(
                color: EcoPalette.black.color,
                fontSize: 16,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: EcoPalette.warning.color,
                foregroundColor: EcoPalette.white.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: onPressed ?? () {
                Navigator.of(context).pop();
              },
              child: Text(botonTexto ?? 'Entendido'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un SnackBar personalizado para errores
  static void mostrarSnackBarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: EcoPalette.white.color),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(color: EcoPalette.white.color),
              ),
            ),
          ],
        ),
        backgroundColor: EcoPalette.error.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: EcoPalette.white.color,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Muestra un SnackBar personalizado para mensajes de éxito
  static void mostrarSnackBarExito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: EcoPalette.white.color),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(color: EcoPalette.white.color),
              ),
            ),
          ],
        ),
        backgroundColor: EcoPalette.success.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Traduce errores técnicos a mensajes amigables para el usuario
  static String obtenerMensajeError(dynamic error) {
    if (error == null) {
      return 'Ha ocurrido un error desconocido';
    }

    final String errorStr = error.toString().toLowerCase();
    
    // Errores de conexión
    if (errorStr.contains('socket') || 
        errorStr.contains('connection') || 
        errorStr.contains('network') ||
        errorStr.contains('timeout')) {
      return 'No se pudo conectar al servidor. Verifica tu conexión a internet e intenta nuevamente.';
    }
    
    // Errores de autenticación
    if (errorStr.contains('auth') || 
        errorStr.contains('login') || 
        errorStr.contains('password') ||
        errorStr.contains('credential')) {
      return 'Error de autenticación. Verifica tus credenciales e intenta nuevamente.';
    }
    
    // Errores de permisos
    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'No tienes permisos para realizar esta acción.';
    }
    
    // Errores de ubicación
    if (errorStr.contains('location') || errorStr.contains('gps')) {
      return 'No se pudo acceder a tu ubicación. Verifica que los permisos estén activados.';
    }
    
    // Errores de cámara
    if (errorStr.contains('camera')) {
      return 'No se pudo acceder a la cámara. Verifica que los permisos estén activados.';
    }
    
    // Errores de almacenamiento
    if (errorStr.contains('storage') || errorStr.contains('file')) {
      return 'Error al acceder al almacenamiento. Verifica que tengas espacio disponible.';
    }
    
    // Errores de formato
    if (errorStr.contains('format') || errorStr.contains('parse')) {
      return 'Error en el formato de los datos. Intenta nuevamente.';
    }
    
    // Error genérico
    return 'Ha ocurrido un error. Por favor, intenta nuevamente.';
  }
} 