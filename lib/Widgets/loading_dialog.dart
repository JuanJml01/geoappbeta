import 'package:flutter/material.dart';
import 'package:geoapptest/mocha.dart';

/// Muestra un diálogo de carga personalizado
class LoadingDialog extends StatelessWidget {
  final String mensaje;
  
  const LoadingDialog({
    Key? key, 
    this.mensaje = 'Cargando...',
  }) : super(key: key);

  /// Método estático para mostrar el diálogo de carga
  static Future<void> show(BuildContext context, {String mensaje = 'Cargando...'}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(mensaje: mensaje);
      },
    );
  }

  /// Método estático para ocultar el diálogo de carga
  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: EcoPalette.white.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: EcoPalette.black.color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: EcoPalette.greenPrimary.color,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              mensaje,
              style: TextStyle(
                color: EcoPalette.greenDark.color,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 