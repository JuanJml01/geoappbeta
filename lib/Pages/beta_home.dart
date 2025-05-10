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

  @override
  void initState() {
    super.initState();
    _obtenerPosicionInicial();
    _inicializarDato();
  }

  Future<void> _obtenerPosicionInicial() async {
    try {
      final position = await _getPosition();
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
          ),
        );
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
      final provider = Provider.of<Reporteprovider>(context, listen: false);
      await provider.fetchReporte();

      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    }
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
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: EcoPalette.greenPrimary.color,
        foregroundColor: EcoPalette.white.color,
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
                    setState(() {
                      isMapLoading = false;
                    });
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
                            'lat': position.center!.latitude,
                            'lng': position.center!.longitude,
                            'zoom': position.zoom
                          }
                        },
                      );
                    }
                  }),
                mapController: _mapController,
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.geoapp.app',
                    tileProvider: NetworkTileProvider(),
                    errorImage: Image.asset('assets/map_placeholder.png').image,
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
              Container(
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
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
