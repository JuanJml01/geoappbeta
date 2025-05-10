import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geoapptest/Provider/reporteProvider.dart';
import 'package:geoapptest/Service/logger_service.dart';
import 'package:geoapptest/mocha.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geoapptest/Model/reporteModel.dart';

// Envuelve el proveedor de tile estándar con reintentos automáticos
class RetryingNetworkTileProvider extends NetworkTileProvider {
  final int maxRetries;
  
  RetryingNetworkTileProvider({this.maxRetries = 3});
  
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return super.getImage(coordinates, options);
      } catch (e) {
        attempts++;
        debugPrint('Error al cargar tile ($attempts/$maxRetries): $e');
        
        if (attempts >= maxRetries) {
          // Si alcanzamos el máximo de reintentos, relanzar
          rethrow;
        }
        
        // Esperar antes de reintentar (backoff exponencial)
        Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
    
    // Este punto nunca debería alcanzarse, pero el compilador lo necesita
    throw Exception('Error inesperado al cargar mapa');
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MapController _mapController = MapController();
  Position? _positionInit;
  final _positionStream =
      const LocationMarkerDataStreamFactory().fromGeolocatorPositionStream(
          stream: Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50,
      timeLimit: Duration(minutes: 1),
    ),
  ));

  bool isInitialized = false;
  bool isMapLoading = true;
  bool hasMapError = false;
  String mapErrorMessage = "Error al cargar el mapa";

  @override
  void initState() {
    super.initState();
    _obtenerPosicionInicial();
    _inicializarDato();
  }

  Future<void> _obtenerPosicionInicial() async {
    try {
      final position = await _getPosition().timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("Tiempo de espera agotado al obtener ubicación");
        },
      );
      
      if (mounted) {
        setState(() {
          _positionInit = position;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al obtener la posición: $e"),
            backgroundColor: EcoPalette.error.color,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: EcoPalette.white.color,
              onPressed: () {
                _obtenerPosicionInicial();
              },
            ),
          ),
        );
        
        // Usar una ubicación predeterminada para no bloquear la app completamente
        setState(() {
          // Usar Madrid como ubicación predeterminada (o cualquier otra ubicación relevante)
          _positionInit = Position(
            longitude: -3.7038, 
            latitude: 40.4168,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        });
      }
    }
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: EcoPalette.white.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Ubicación desactivada',
                style: TextStyle(color: EcoPalette.greenDark.color, fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Para usar esta aplicación, necesitas activar los servicios de ubicación.',
                style: TextStyle(color: EcoPalette.black.color),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: EcoPalette.error.color),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EcoPalette.greenPrimary.color,
                    foregroundColor: EcoPalette.white.color,
                  ),
                  child: Text('Activar'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await Geolocator.openLocationSettings();
                  },
                ),
              ],
            );
          },
        );
      }
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _inicializarDato() async {
    if (!isInitialized) {
      try {
        final provider = Provider.of<Reporteprovider>(context, listen: false);
        await provider.fetchReporte().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            // No lanzar error, simplemente continuar con lo que tenemos
            debugPrint('Tiempo de espera agotado al obtener reportes');
          },
        );

        if (mounted) {
          setState(() {
            isInitialized = true;
          });
        }
      } catch (e) {
        debugPrint('Error al inicializar datos: $e');
        // No bloquear la inicialización aunque falle la carga
        if (mounted) {
          setState(() {
            isInitialized = true;
          });
        }
      }
    }
  }

  void _recargarMapa() {
    setState(() {
      isMapLoading = true;
      hasMapError = false;
      mapErrorMessage = "Error al cargar el mapa";
    });
    
    // Reintentar obtener posición y datos
    _obtenerPosicionInicial();
    _inicializarDato();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: EcoPalette.greenPrimary.color,
        foregroundColor: EcoPalette.white.color,
        elevation: 0,
        title: Text(
          'Mapa de Reportes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Añadir botón de recarga
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Recargar mapa',
            onPressed: _recargarMapa,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: EcoPalette.greenPrimary.color,
        foregroundColor: EcoPalette.white.color,
        tooltip: 'Ir a mi ubicación',
        onPressed: () {
          if (_positionInit != null) {
            _mapController.move(
                LatLng(_positionInit!.latitude, _positionInit!.longitude), 13);
          }
        },
        child: Icon(Icons.my_location_rounded),
      ),
      body:
          Consumer<Reporteprovider>(builder: (context, reporteprovider, child) {
        if (!isInitialized || _positionInit == null) {
          return Container(
              color: EcoPalette.sand.color,
              child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: EcoPalette.greenPrimary.color,
                        semanticsLabel: 'Indicador de carga',
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cargando mapa...',
                        style: TextStyle(
                          color: EcoPalette.greenDark.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )));
        }
        
        // Si hay un error en el mapa, mostrar mensaje de error con botón para reintentar
        if (hasMapError) {
          return Container(
            color: EcoPalette.sand.color,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: EcoPalette.error.color,
                  ),
                  SizedBox(height: 16),
                  Text(
                    mapErrorMessage,
                    style: TextStyle(
                      color: EcoPalette.error.color,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _recargarMapa,
                    icon: Icon(Icons.refresh),
                    label: Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoPalette.greenPrimary.color,
                      foregroundColor: EcoPalette.white.color,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        List<Marker> markers = [];

        markers.addAll(reporteprovider.reportes.map((item) {
          return Marker(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              point: LatLng(
                item.latitud,
                item.longitud,
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/verReporte',
                      arguments: item);
                },
                child: Semantics(
                  button: true,
                  enabled: true,
                  hint: 'Ver detalles del reporte',
                  label: 'Reporte de tipo ${tipoReporteToString(item.tipo)} en estado ${estadoReporteToString(item.estado)}',
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: EcoPalette.greenPrimary.color.withOpacity(0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: EcoPalette.black.color.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_pin,
                      color: EcoPalette.white.color,
                      size: 20,
                    ),
                  ),
                ),
              ));
        }));

        return Stack(
          children: [
            Container(
              color: EcoPalette.sand.color,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_positionInit!.latitude, _positionInit!.longitude),
                  initialZoom: 13,
                  minZoom: 4,
                  maxZoom: 18,
                  onMapReady: () {
                    if (mounted) {
                      setState(() {
                        isMapLoading = false;
                      });
                    }
                    LoggerService().logMapInteraction(
                      action: 'MAP_READY',
                      details: {
                        'initial_position': {
                          'lat': _positionInit!.latitude,
                          'lng': _positionInit!.longitude
                        }
                      },
                    );
                  },
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      LoggerService().logMapInteraction(
                        action: 'MAP_MOVED',
                        details: {
                          'new_position': {
                            'lat': position.center?.latitude,
                            'lng': position.center?.longitude,
                            'zoom': position.zoom
                          }
                        },
                      );
                    }
                  },
                  onTap: (tapPosition, point) {
                    // Si tocas el mapa, oculta cualquier mensaje o interfaz superpuesta
                    if (isMapLoading && mounted) {
                      setState(() {
                        isMapLoading = false;
                      });
                    }
                  },
                  // Manejar errores del mapa
                  onMapEvent: (event) {
                    if (event.runtimeType.toString().contains('Error')) {
                      debugPrint('Error en el mapa: ${event.toString()}');
                      if (mounted) {
                        setState(() {
                          hasMapError = true;
                          mapErrorMessage = "Error al cargar el mapa. Comprueba tu conexión a internet.";
                        });
                      }
                    }
                  },
                ),
                mapController: _mapController,
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.geoapp.app',
                    tileProvider: RetryingNetworkTileProvider(maxRetries: 3),
                    errorImage: AssetImage('assets/map_placeholder.png'),
                    evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
                    // Manejar errores de los tiles específicamente
                    errorTileCallback: (tile, error, stackTrace) {
                      debugPrint('Error al cargar tile: $error');
                      // Solo mostrar error si hay demasiados tiles fallidos
                      if (mounted && !hasMapError) {
                        setState(() {
                          hasMapError = true;
                          mapErrorMessage = "Problemas al cargar el mapa. Comprueba tu conexión a internet.";
                        });
                      }
                    },
                  ),
                  CurrentLocationLayer(
                    positionStream: _positionStream,
                    style: LocationMarkerStyle(
                      marker: DefaultLocationMarker(
                        color: EcoPalette.info.color,
                        child: Icon(
                          Icons.person,
                          color: EcoPalette.white.color,
                          size: 12,
                        ),
                      ),
                      markerSize: const Size(22, 22),
                      accuracyCircleColor: EcoPalette.info.color.withOpacity(0.3),
                      headingSectorColor: EcoPalette.info.color.withOpacity(0.8),
                      headingSectorRadius: 60,
                    ),
                  ),
                  MarkerLayer(markers: markers),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isMapLoading)
              Semantics(
                label: 'Cargando mapa de reportes',
                child: Container(
                  color: EcoPalette.sand.color.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: EcoPalette.greenPrimary.color,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cargando mapa...',
                          style: TextStyle(
                            color: EcoPalette.greenDark.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Mostrar opción para continuar sin esperar
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                isMapLoading = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EcoPalette.greenLight.color,
                            foregroundColor: EcoPalette.greenDark.color,
                          ),
                          child: Text('Continuar sin esperar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
