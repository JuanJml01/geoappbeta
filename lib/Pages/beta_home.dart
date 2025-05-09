import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geoapptest/Provider/reporteProvider.dart';
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
              initialCenter:
                  LatLng(_positionInit!.latitude, _positionInit!.longitude)),
          mapController: _mapController,
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            CurrentLocationLayer(
              style: LocationMarkerStyle(
                  headingSectorRadius: (screenHeight * screenWidth) * 0.0003,
                  headingSectorColor: Mocha.blue.color,
                  accuracyCircleColor: Mocha.blue.color,
                  markerSize:
                      Size.square((screenHeight + screenWidth) * 0.025)),
              positionStream: _positionStream,
            ),
            MarkerLayer(markers: markers)
          ],
        );
      }),
    );
  }
}
