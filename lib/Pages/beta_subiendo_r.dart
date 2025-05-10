// ignore_for_file:  use_build_context_synchronously

import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geoapptest/Model/reporteModel.dart';
import 'package:geoapptest/Provider/reporteProvider.dart';
import 'package:geoapptest/Provider/userProvider.dart';
import 'package:geoapptest/Service/tomarFoto.dart';
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
      
      if (providerU.user?.email == null) {
        throw Exception('No hay un usuario con sesión activa.');
      }
      
      final fotoProvider = Provider.of<TomarFoto>(context, listen: false);
      if (fotoProvider.foto == null) {
        throw Exception('No se ha tomado ninguna foto.');
      }
      
      final reporte = Reporte(
        descripcion: descripcion,
        imagen: fotoProvider.foto!.path,
        email: providerU.user!.email!,
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
          
          // Personalizar el mensaje de error según el tipo
          if (e is TimeoutException) {
            _errorMessage = "La operación tardó demasiado tiempo. Verifica tu conexión a internet.";
          } else if (e is GeolocatorPlatform) {
            _errorMessage = "No se pudo acceder a la ubicación del dispositivo.";
          } else {
            _errorMessage = "Error: ${e.toString()}";
          }
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
        return Future.error('Permisos de ubicación denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Los permisos de ubicación están permanentemente denegados.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      floatingActionButton: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _getStateColor(),
          foregroundColor: EcoPalette.white.color,
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          if (_estado != Estado.iniciado) {
            Navigator.pop(context);
          } else {
            // Si aún está en proceso, preguntar si quiere cancelar
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: EcoPalette.white.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  '¿Cancelar envío?',
                  style: TextStyle(color: EcoPalette.greenDark.color, fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'El reporte aún se está subiendo. ¿Estás seguro que deseas cancelar?',
                  style: TextStyle(color: EcoPalette.black.color),
                ),
                actions: [
                  TextButton(
                    child: Text(
                      'Continuar subiendo',
                      style: TextStyle(color: EcoPalette.greenPrimary.color),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoPalette.error.color,
                      foregroundColor: EcoPalette.white.color,
                    ),
                    child: Text('Cancelar envío'),
                    onPressed: () {
                      Navigator.pop(context); // Cerrar el diálogo
                      Navigator.pop(context); // Volver a la pantalla anterior
                    },
                  ),
                ],
              ),
            );
          }
        },
        icon: Icon(
          _getStateIcon(),
          size: 24,
        ),
        label: Text(
          _getStateButtonText(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        foregroundColor: EcoPalette.white.color,
        backgroundColor: EcoPalette.greenPrimary.color,
        elevation: 0,
        title: Text(
          _getStateTitle(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: EcoPalette.white.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  '¿Cancelar envío?',
                  style: TextStyle(color: EcoPalette.greenDark.color, fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'Si sales ahora, se perderá el reporte que estás subiendo.',
                  style: TextStyle(color: EcoPalette.black.color),
                ),
                actions: [
                  TextButton(
                    child: Text(
                      'Continuar subiendo',
                      style: TextStyle(color: EcoPalette.greenPrimary.color),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoPalette.error.color,
                      foregroundColor: EcoPalette.white.color,
                    ),
                    child: Text('Cancelar envío'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: EcoPalette.sand.color,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono animado según el estado
                _buildStateIcon(),
                    
                SizedBox(height: 32),
                
                // Texto de estado
                Text(
                  _getStateText(),
                  style: TextStyle(
                    color: _getStateColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Descripción del estado
                Text(
                  _getStateDescription(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EcoPalette.black.color,
                    fontSize: 16,
                  ),
                ),
                
                // Advertencia de tiempo de espera
                if (_isTimeoutWarningVisible && _estado == Estado.iniciado)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: EcoPalette.warning.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, color: EcoPalette.warning.color),
                              SizedBox(width: 8),
                              Text(
                                "Está tardando más de lo esperado",
                                style: TextStyle(
                                  color: EcoPalette.warning.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "La subida puede tardar más tiempo dependiendo de tu conexión a internet.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: EcoPalette.black.color.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                SizedBox(height: 32),
                
                // Tiempo transcurrido
                if (_estado == Estado.iniciado)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: EcoPalette.white.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: EcoPalette.black.color.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: EcoPalette.greenPrimary.color,
                        ),
                        SizedBox(width: 8),
                        StreamBuilder<String>(
                          stream: _timer(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                "Tiempo: ${snapshot.data}",
                                style: TextStyle(
                                  color: EcoPalette.greenDark.color,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              );
                            } else {
                              return Text(
                                "Tiempo: 00:00:00",
                                style: TextStyle(
                                  color: EcoPalette.greenDark.color,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: 32),
                
                // Barra de progreso
                Container(
                  width: screenWidth * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: EcoPalette.black.color.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: StreamBuilder<double>(
                      stream: _carga(),
                      builder: (context, snapshot) {
                        return LinearProgressIndicator(
                          value: snapshot.data ?? 0.1,
                          minHeight: 10,
                          backgroundColor: EcoPalette.grayLight.color,
                          valueColor: AlwaysStoppedAnimation<Color>(_getStateColor()),
                        );
                      },
                    ),
                  ),
                ),
                
                // Botón para reintentar en caso de error
                if (_estado == Estado.error)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _estado = Estado.iniciado;
                          _isTimeoutWarningVisible = false;
                          _errorMessage = "Ocurrió un error al subir el reporte.";
                          x = 0;
                          carga = 0.0;
                        });
                        
                        // Reiniciar el timer
                        _timeoutTimer?.cancel();
                        _timeoutTimer = Timer(Duration(seconds: 15), () {
                          if (mounted && _estado == Estado.iniciado) {
                            setState(() {
                              _isTimeoutWarningVisible = true;
                            });
                          }
                        });
                        
                        // Reintentar
                        _subirReporte();
                      },
                      icon: Icon(Icons.refresh),
                      label: Text("Reintentar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EcoPalette.info.color,
                        foregroundColor: EcoPalette.white.color,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Métodos para obtener información según el estado
  Widget _buildStateIcon() {
    switch (_estado) {
      case Estado.completado:
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: EcoPalette.success.color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: EcoPalette.success.color,
            size: 64,
          ),
        );
      case Estado.error:
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: EcoPalette.error.color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error,
            color: EcoPalette.error.color,
            size: 64,
          ),
        );
      default: // Estado.iniciado
        return RotationTransition(
          turns: _animationController,
          child: Container(
            width: 100,
            height: 100,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EcoPalette.greenLight.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(EcoPalette.greenPrimary.color),
              strokeWidth: 3,
            ),
          ),
        );
    }
  }
  
  Color _getStateColor() {
    switch (_estado) {
      case Estado.completado:
        return EcoPalette.success.color;
      case Estado.error:
        return EcoPalette.error.color;
      default:
        return EcoPalette.greenLight.color;
    }
  }
  
  String _getStateText() {
    switch (_estado) {
      case Estado.completado:
        return "¡Reporte subido con éxito!";
      case Estado.error:
        return "Error al subir el reporte";
      default:
        return "Subiendo reporte...";
    }
  }
  
  String _getStateDescription() {
    switch (_estado) {
      case Estado.completado:
        return "Tu reporte ha sido enviado correctamente y será revisado por nuestro equipo.";
      case Estado.error:
        return _errorMessage;
      default:
        return "Estamos procesando y subiendo tu reporte ambiental.";
    }
  }
  
  String _getStateTitle() {
    switch (_estado) {
      case Estado.completado:
        return "Reporte completado";
      case Estado.error:
        return "Error en el reporte";
      default:
        return "Subiendo reporte";
    }
  }
  
  String _getStateButtonText() {
    switch (_estado) {
      case Estado.completado:
        return "Continuar";
      case Estado.error:
        return "Volver";
      default:
        return "Cancelar";
    }
  }
  
  IconData _getStateIcon() {
    switch (_estado) {
      case Estado.completado:
        return Icons.check_circle;
      case Estado.error:
        return Icons.arrow_back;
      default:
        return Icons.close;
    }
  }
}
