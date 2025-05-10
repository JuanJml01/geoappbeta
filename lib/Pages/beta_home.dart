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
      throw ("Error obteniendo posición: $e");
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
              backgroundColor: Mocha.base.color,
              title: Text(
                'Ubicación desactivada',
                style: TextStyle(color: Mocha.text.color),
              ),
              content: Text(
                'Para usar esta aplicación, necesitas activar los servicios de ubicación.',
                style: TextStyle(color: Mocha.text.color),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Mocha.red.color),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    'Activar',
                    style: TextStyle(color: Mocha.green.color),
                  ),
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
      floatingActionButton: FloatingActionButton.large(
        elevation: 20,
        backgroundColor: Mocha.base.color,
        foregroundColor: Mocha.blue.color,
        onPressed: () {
          _mapController.move(
              LatLng(_positionInit!.latitude, _positionInit!.longitude), 13);
        },
        child: Icon(Icons.my_location_rounded),
      ),
      body:
          Consumer<Reporteprovider>(builder: (context, reporteprovider, child) {
        if (!isInitialized || _positionInit == null) {
          return DecoratedBox(
              decoration: BoxDecoration(color: Mocha.base.color),
              child: Center(
                  child: CircularProgressIndicator(
                color: Mocha.green.color,
              )));
        }

        List<Marker> markers = [];

        markers.addAll(reporteprovider.reportes.map((item) {
          return Marker(
              width: 100,
              height: 100,
              alignment: Alignment.center,
              point: LatLng(
                item.latitud,
                item.longitud,
              ),
              child: IconButton(
                  highlightColor: Mocha.overlay0.color,
                  color: Mocha.green.color,
                  alignment: Alignment.center,
                  iconSize: (screenHeight + screenWidth) * 0.05,
                  onPressed: () {
                    Navigator.pushNamed(context, '/verReporte',
                        arguments: item);
                  },
                  icon: Icon(
                    shadows: [
                      Shadow(
                          color: Mocha.base.color,
                          offset: Offset.fromDirection(290, 3))
                    ],
                    Icons.location_pin,
                  )));
        }));

        return FlutterMap(
          options: MapOptions(
              initialCenter: LatLng(_positionInit!.latitude, _positionInit!.longitude),
              initialZoom: 13,
              minZoom: 4,
              maxZoom: 18,
              onMapReady: () {
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
              backgroundColor: Mocha.base.color,
              tileBuilder: (context, tileWidget, tile) {
                return ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Mocha.surface0.color.withOpacity(0.1),
                    BlendMode.srcOver,
                  ),
                  child: tileWidget,
                );
              },
            ),
            CurrentLocationLayer(
              style: LocationMarkerStyle(
                headingSectorRadius: (screenHeight * screenWidth) * 0.0003,
                headingSectorColor: Mocha.blue.color.withOpacity(0.8),
                accuracyCircleColor: Mocha.blue.color.withOpacity(0.3),
                markerSize: Size.square((screenHeight + screenWidth) * 0.025),
                marker: const DefaultLocationMarker(
                  child: Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              positionStream: _positionStream,
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
        );
      }),
    );
  }
}
