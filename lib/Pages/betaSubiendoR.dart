// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:geoappbeta/Service/tomarFoto.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:geolocator/geolocator.dart';
import 'package:getwidget/components/progress_bar/gf_progress_bar.dart';
import 'package:provider/provider.dart';

class SubiendoReporte extends StatefulWidget {
  const SubiendoReporte({super.key});

  @override
  State<SubiendoReporte> createState() => _SubiendoReporteState();
}

enum Estado {
  iniciado,
  completado,
}

class _SubiendoReporteState extends State<SubiendoReporte> {
  double x = 0;
  double carga = 0.0;
  final double k = 0.1;
  Estado _estado = Estado.iniciado;
  //String _Tiempo = "";

  Stream<String> _timer() async* {
    int s = 0, h = 0, m = 0;
    while (_estado != Estado.completado) {
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
      yield "0$h:0$m:0$s";
    }
    yield "0$h:0$m:0$s";
  }

  @override
  void initState() {
    super.initState();
    _subirReporte();
  }

  Future<void> _subirReporte() async {
    _position().then((position) async {
      final providerR = context.read<Reporteprovider>();
      final providerU = context.read<SessionProvider>();
      late Reporte reporte;
      reporte = Reporte(
        imagen: Provider.of<TomarFoto>(context, listen: false).foto!.path,
        nombre: providerU.user!.email!,
        longitud: position.longitude,
        latitud: position.latitude,
      );

      //return providerR.addReporte(reporte);

      await providerR.addReporte(reporte);

      if (mounted) {
        setState(() {
          _estado = Estado.completado;
          _colorB = Mocha.green.color;
        });
      }
    });
  }

  Stream<double> _carga() async* {
    int tiempo = 100;
    while (_estado != Estado.completado) {
      carga = x < 20 ? exp(k * (x - 20)) : 1.0;
      x++;
      await Future.delayed(Duration(milliseconds: tiempo));
      tiempo += tiempo;
      yield carga;
    }
    yield 1.0;
  }

  Future<Position> _position() async {
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

  Color _colorB = Mocha.overlay2.color;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    //final data = new Reporte(nombre: context.read<SessionProvider>().user?.email, imagen: imagen, longitud: longitud, latitud: latitud)

    return Scaffold(
      floatingActionButton: TextButton.icon(
        style: TextButton.styleFrom(
            elevation: 10,
            shadowColor: Mocha.mantle.color,
            backgroundColor: _colorB),
        onPressed: () {
          if (_estado == Estado.completado) {
            Navigator.pop(context);
          }
        },
        label: Text(
          "Continuar",
          style: TextStyle(
              fontSize: (screenHeight + screenWidth) * 0.015,
              color: Mocha.crust.color),
        ),
        icon: Icon(
          color: Mocha.crust.color,
          Icons.arrow_forward,
          size: (screenHeight + screenWidth) * 0.026,
        ),
        iconAlignment: IconAlignment.end,
      ),
      appBar: AppBar(
        foregroundColor: Mocha.lavender.color,
        backgroundColor: Mocha.base.color,
        title: Text(
          "Volver y cancelar",
          style: TextStyle(
              color: Mocha.lavender.color,
              fontSize: (screenHeight + screenWidth) * 0.015),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(color: Mocha.base.color),
        child: Center(
          child: Column(
            children: [
              Row(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Builder(builder: (context) {
                    return StreamBuilder<String>(
                        stream: _timer(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              "${snapshot.data}",
                              style: TextStyle(
                                  color: Mocha.subtext1.color,
                                  fontSize:
                                      (screenHeight + screenWidth) * 0.013),
                            );
                          } else {
                            return CircularProgressIndicator();
                          }
                        });
                  }),
                  SizedBox(
                    height: screenHeight * 0.1,
                  ),
                  Text(
                    "Subiendo reporte",
                    style: TextStyle(
                        color: Mocha.subtext1.color,
                        fontSize: (screenHeight + screenWidth) * 0.013),
                  ),
                ],
              ),
              StreamBuilder<double>(
                  stream: _carga(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return GFProgressBar(
                        percentage: snapshot.data!,
                        backgroundColor: Mocha.overlay1.color,
                        progressBarColor: Mocha.green.color,
                      );
                    } else {
                      return GFProgressBar(
                        percentage: 0.0,
                        backgroundColor: Mocha.overlay1.color,
                        progressBarColor: Mocha.green.color,
                      );
                    }
                  })
            ],
          ),
        ),
      ),
    );
  }
}
