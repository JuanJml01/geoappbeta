import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:geoappbeta/Service/tomarFoto.dart';
import 'package:geolocator/geolocator.dart';
import 'package:getwidget/components/progress_bar/gf_progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  double x = 1;
  double carga = 0.0;
  final double k = -9.0;
  Estado _estado = Estado.iniciado;
  //String _Tiempo = "";

  Stream<String> _Timer() async* {
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
    _Position().then((position) async {
      final providerR = context.read<Reporteprovider>();
      final providerU = context.read<SessionProvider>();
      late Reporte reporte;
      reporte = Reporte(
        imagen: Provider.of<TomarFoto>(context, listen: false).foto.path,
        nombre: providerU.user!.email!,
        longitud: position.longitude,
        latitud: position.latitude,
      );

      //return providerR.addReporte(reporte);
      print("lo hizo");
      await providerR.addReporte(reporte);
      print("lo hizo2");

      if (mounted) {
        setState(() {
          _estado = Estado.completado;
          _colorB = Colors.lightGreen;
        });
      }
    }); /* .then((_) {
      _estado = Estado.completado;
      _avanzar();
    }); */
  }

  Stream<double> _carga() async* {
    while (_estado != Estado.completado) {
      carga = 0.1 - (1 * exp(k * x));
      x = x + 1;
      await Future.delayed(Duration(milliseconds: 600));
      yield carga;
    }
    yield 1.0;
  }

  Future<Position> _Position() async {
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

  Color _colorB = Colors.grey;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    //final data = new Reporte(nombre: context.read<SessionProvider>().user?.email, imagen: imagen, longitud: longitud, latitud: latitud)
    print(Provider.of<TomarFoto>(context).foto.toString());
    print(Provider.of<TomarFoto>(context).aceptada.toString());
    return Scaffold(
      floatingActionButton: TextButton.icon(
        style: TextButton.styleFrom(backgroundColor: _colorB),
        onPressed: () => Navigator.pop(context),
        label: Text(
          "Continuar",
          style: TextStyle(
              fontSize: (screenHeight + screenWidth) * 0.015,
              color: Colors.white),
        ),
        icon: Icon(
          color: Colors.white,
          Icons.arrow_forward,
          size: (screenHeight + screenWidth) * 0.026,
        ),
        iconAlignment: IconAlignment.end,
      ),
      appBar: AppBar(
        title: Text(
          "Volver y cancelar",
          style: TextStyle(fontSize: (screenHeight + screenWidth) * 0.015),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(builder: (context) {
                  return StreamBuilder<String>(
                      stream: _Timer(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            "${snapshot.data}",
                            style: TextStyle(
                                fontSize: (screenHeight + screenWidth) * 0.013),
                          );
                        } else {
                          return CircularProgressIndicator();
                        }
                      });
                }),
                Text(
                  "Subiendo reporte",
                  style:
                      TextStyle(fontSize: (screenHeight + screenWidth) * 0.013),
                ),
              ],
            ),
            StreamBuilder<double>(
                stream: _carga(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return GFProgressBar(
                      percentage: snapshot.data!,
                      backgroundColor: Colors.black26,
                      progressBarColor: Colors.lightGreen,
                    );
                  } else {
                    return GFProgressBar(
                      percentage: 0.0,
                      backgroundColor: Colors.black26,
                      progressBarColor: Colors.lightGreen,
                    );
                  }
                })
          ],
        ),
      ),
    );
  }
}
