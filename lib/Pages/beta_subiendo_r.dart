// ignore_for_file:  use_build_context_synchronously

import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geoapptest/Model/reporteModel.dart';
import 'package:geoapptest/Provider/reporteProvider.dart';
import 'package:geoapptest/Provider/userProvider.dart';
import 'package:geoapptest/Service/error_service.dart';
import 'package:geoapptest/Service/tomarFoto.dart';
import 'package:geoapptest/Widgets/loading_dialog.dart';
import 'package:geoapptest/mocha.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class SubiendoReporte extends StatefulWidget {
  const SubiendoReporte({super.key});

  @override
  State<SubiendoReporte> createState() => _SubiendoReporteState();
}

enum Estado {
  iniciado,
  completado,
  error,
}

class _SubiendoReporteState extends State<SubiendoReporte> with SingleTickerProviderStateMixin {
  double x = 0;
  double carga = 0.0;
  final double k = 0.1;
  Estado _estado = Estado.iniciado;
  late AnimationController _animationController;
  String _errorMessage = "Ocurrió un error al subir el reporte.";
  bool _isTimeoutWarningVisible = false;
  Timer? _timeoutTimer;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
    
    // Iniciar un timer para mostrar una advertencia si tarda demasiado
    _timeoutTimer = Timer(Duration(seconds: 15), () {
      if (mounted && _estado == Estado.iniciado) {
        setState(() {
          _isTimeoutWarningVisible = true;
        });
      }
    });
    
    _subirReporte();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Stream<String> _timer() async* {
    int s = 0, h = 0, m = 0;
    while (_estado == Estado.iniciado) {
      await Future.delayed(Duration(seconds: 1));
      s++;
      if (s == 60) {
        s = 0;
        m++;
      }
      if (m == 60) {
        h++;
        m = 0;
      }
      yield "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    yield "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Future<void> _subirReporte() async {
    try {
      final position = await _position().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('No se pudo obtener la ubicación a tiempo.');
        },
      );
      
      // Recuperar argumentos que pueden ser un String o un Map
      final args = ModalRoute.of(context)?.settings.arguments;
      
      String descripcion = "";
      List<String> tipoTagIds = ['otro'];
      List<String> ubicacionTagIds = ['otro'];
      
      // Procesar argumentos según el tipo
      if (args is Map<String, dynamic>) {
        descripcion = args['descripcion'] ?? "";
        
        // Obtener tags de tipo
        if (args['tipoTags'] != null && args['tipoTags'] is List) {
          tipoTagIds = List<String>.from(args['tipoTags']);
        }
        
        // Obtener tags de ubicación
        if (args['ubicacionTags'] != null && args['ubicacionTags'] is List) {
          ubicacionTagIds = List<String>.from(args['ubicacionTags']);
        }
      } else if (args is String) {
        // Compatibilidad con el formato anterior
        descripcion = args;
      }
      
      final providerR = context.read<Reporteprovider>();
      final providerU = context.read<SessionProvider>();
      
      // Verificar si hay un usuario con sesión activa
      String email = "anonimo";
      if (providerU.user != null && providerU.user?.email != null && providerU.user!.email!.isNotEmpty) {
        email = providerU.user!.email!;
      }
      
      final fotoProvider = Provider.of<TomarFoto>(context, listen: false);
      if (fotoProvider.foto == null) {
        throw Exception('No se ha tomado ninguna foto.');
      }
      
      final reporte = Reporte(
        descripcion: descripcion,
        imagen: fotoProvider.foto!.path,
        email: email,
        longitud: position.longitude,
        latitud: position.latitude,
        tipoTagIds: tipoTagIds,
        ubicacionTagIds: ubicacionTagIds,
        tipo: tipoTagIds.isNotEmpty 
            ? tipoReporteFromString(tipoTagIds.first) 
            : TipoReporte.otro,
      );

      // Usar un timeout para la subida del reporte
      final success = await providerR.subirReporte(reporte, File(fotoProvider.foto!.path)).timeout(
        Duration(seconds: 60),
        onTimeout: () {
          return false;
        },
      );
      
      if (mounted) {
        setState(() {
          if (success) {
            _estado = Estado.completado;
            // Mostrar mensaje de éxito
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) {
                ErrorService.mostrarSnackBarExito(
                  context, 
                  'Tu reporte se ha subido correctamente'
                );
              }
            });
          } else {
            _estado = Estado.error;
            _errorMessage = "No se pudo subir el reporte. Verifica tu conexión a internet.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estado = Estado.error;
          
          // Usar el servicio de errores para obtener un mensaje amigable
          _errorMessage = ErrorService.obtenerMensajeError(e);
        });
      }
      debugPrint('Error en _subirReporte: $e');
    }
  }

  Stream<double> _carga() async* {
    int tiempo = 100;
    while (_estado == Estado.iniciado) {
      carga = x < 20 ? exp(k * (x - 20)) : 1.0;
      x++;
      await Future.delayed(Duration(milliseconds: tiempo));
      tiempo = tiempo < 300 ? tiempo + 50 : tiempo;
      yield carga;
    }
    yield _estado == Estado.completado ? 1.0 : 0.3; // 0.3 para error
  }

  Future<Position> _position() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están desactivados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Mostrar un diálogo explicativo cuando se deniegan los permisos
        if (mounted) {
          ErrorService.mostrarAdvertencia(
            context: context,
            titulo: 'Permisos de ubicación',
            mensaje: 'Necesitamos acceder a tu ubicación para poder reportar correctamente el problema ambiental. Por favor, activa los permisos de ubicación.',
            botonTexto: 'Entendido',
          );
        }
        return Future.error('Permisos de ubicación denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Mostrar un diálogo explicativo cuando se deniegan los permisos permanentemente
      if (mounted) {
        ErrorService.mostrarAdvertencia(
          context: context,
          titulo: 'Permisos de ubicación',
          mensaje: 'Los permisos de ubicación están permanentemente denegados. Por favor, actívalos en la configuración de tu dispositivo para poder usar esta función.',
          botonTexto: 'Ir a Configuración',
          onPressed: () {
            Geolocator.openAppSettings();
          },
        );
      }
      return Future.error('Los permisos de ubicación están permanentemente denegados.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        // Impedir que el usuario regrese mientras se está subiendo el reporte
        if (_estado == Estado.iniciado) {
          // Mostrar diálogo de confirmación
          final bool salir = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: EcoPalette.white.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                '¿Cancelar envío?',
                style: TextStyle(
                  color: EcoPalette.greenDark.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Si sales ahora, se cancelará la subida del reporte. ¿Estás seguro?',
                style: TextStyle(color: EcoPalette.black.color),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: EcoPalette.gray.color,
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Continuar subiendo'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EcoPalette.error.color,
                    foregroundColor: EcoPalette.white.color,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Cancelar subida'),
                ),
              ],
            ),
          );
          return salir;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: EcoPalette.sand.color,
        appBar: AppBar(
          title: Text("Subiendo reporte"),
          backgroundColor: EcoPalette.greenPrimary.color,
          foregroundColor: EcoPalette.white.color,
          automaticallyImplyLeading: _estado != Estado.iniciado,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEstadoWidget(screenWidth, screenHeight),
                SizedBox(height: 32),
                if (_estado == Estado.error)
                  _buildErrorWidget(screenWidth, screenHeight),
                if (_estado == Estado.completado)
                  _buildCompletadoWidget(screenWidth, screenHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoWidget(double screenWidth, double screenHeight) {
    switch (_estado) {
      case Estado.iniciado:
        return Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: EcoPalette.white.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: EcoPalette.black.color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: EcoPalette.greenPrimary.color,
                  strokeWidth: 4,
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Subiendo reporte...",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: EcoPalette.greenDark.color,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Por favor, espera mientras subimos tu reporte.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: EcoPalette.gray.color,
              ),
            ),
            SizedBox(height: 24),
            LinearProgressIndicator(
              backgroundColor: EcoPalette.grayLight.color,
              color: EcoPalette.greenPrimary.color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      case Estado.completado:
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: EcoPalette.success.color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: EcoPalette.success.color,
              width: 4,
            ),
          ),
          child: Icon(
            Icons.check,
            color: EcoPalette.success.color,
            size: 80,
          ),
        );
      case Estado.error:
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: EcoPalette.error.color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: EcoPalette.error.color,
              width: 4,
            ),
          ),
          child: Icon(
            Icons.error_outline,
            color: EcoPalette.error.color,
            size: 80,
          ),
        );
    }
  }

  Widget _buildErrorWidget(double screenWidth, double screenHeight) {
    return Column(
      children: [
        Text(
          "Error al subir el reporte",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: EcoPalette.error.color,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EcoPalette.white.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: EcoPalette.black.color.withOpacity(0.1),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: EcoPalette.black.color,
            ),
          ),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: EcoPalette.greenPrimary.color,
                foregroundColor: EcoPalette.white.color,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                setState(() {
                  _estado = Estado.iniciado;
                  _errorMessage = "";
                });
                _subirReporte();
              },
              icon: Icon(Icons.refresh),
              label: Text("Reintentar"),
            ),
            SizedBox(width: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: EcoPalette.gray.color,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
              label: Text("Volver"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletadoWidget(double screenWidth, double screenHeight) {
    return Column(
      children: [
        Text(
          "¡Reporte enviado!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: EcoPalette.success.color,
          ),
        ),
        SizedBox(height: 16),
        Text(
          "Tu reporte ha sido enviado correctamente. Gracias por contribuir al cuidado del medio ambiente.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: EcoPalette.gray.color,
          ),
        ),
        SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: EcoPalette.greenPrimary.color,
            foregroundColor: EcoPalette.white.color,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          },
          icon: Icon(Icons.home),
          label: Text("Volver al inicio"),
        ),
      ],
    );
  }
}
