// ignore_for_file:  use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geoapptest/Model/reporteModel.dart';
import 'package:geoapptest/Provider/reporteProvider.dart';
import 'package:geoapptest/Provider/userProvider.dart';
import 'package:geoapptest/Service/tomarFoto.dart';
import 'package:geoapptest/mocha.dart';
import 'package:provider/provider.dart';

class SubirReporte extends StatefulWidget {
  const SubirReporte({super.key});

  @override
  State<SubirReporte> createState() => _SubirReporteState();
}

enum TipoUser { anonimo, email }

class _SubirReporteState extends State<SubirReporte> {
  bool isInitialized = false;
  TipoUser _tipoUser = TipoUser.email;
  @override
  void initState() {
    super.initState();
    _inicializarDato();
  }

  Future<void> _inicializarDato() async {
    if (!isInitialized) {
      String email = context.read<SessionProvider>().user!.email ?? "";
      if (email != "") {
        await context
            .read<Reporteprovider>()
            .fetchReporteForEmail(nombre: email);
      } else {
        context.read<Reporteprovider>().reportes.clear();
      }
      if (mounted) {
        setState(() {
          if (email != "") {
            isInitialized = true;
            _tipoUser = TipoUser.email;
          } else {
            isInitialized = true;
            _tipoUser = TipoUser.anonimo;
          }
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
        foregroundColor: Mocha.text.color,
        backgroundColor: Mocha.base.color,
        title: Text(
          "Mis reportes",
          style: TextStyle(color: Mocha.text.color),
        ),
      ),
      body:
          Consumer<Reporteprovider>(builder: (context, reporteprovider, child) {
        if (!isInitialized) {
          return DecoratedBox(
              decoration: BoxDecoration(color: Mocha.base.color),
              child: Center(
                  child: CircularProgressIndicator(
                color: Mocha.green.color,
              )));
        }

        if (_tipoUser == TipoUser.anonimo) {
          return DecoratedBox(
            decoration: BoxDecoration(color: Mocha.base.color),
            child: Center(
              child: Text(
                "Usuario Anonimo",
                style: TextStyle(
                  fontSize: (screenHeight + screenWidth) * 0.03,
                  color: Mocha.teal.color,
                ),
              ),
            ),
          );
        }
        if (reporteprovider.reportes.isEmpty) {
          return DecoratedBox(
            decoration: BoxDecoration(color: Mocha.base.color),
            child: Center(
              child: Text(
                "No hay reportes",
                style: TextStyle(
                  fontSize: (screenHeight + screenWidth) * 0.03,
                  color: Mocha.teal.color,
                ),
              ),
            ),
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(color: Mocha.base.color),
          child: GridView.builder(
              itemCount: reporteprovider.reportes.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisSpacing: (screenHeight + screenWidth) * 0.015,
                crossAxisCount: 2,
              ),
              itemBuilder: (context, index) {
                Reporte reporte = reporteprovider.reportes[index];
                return cardreport(
                    nombre: reporte.email,
                    descripcion: reporte.descripcion,
                    urlimage: reporte.imagen,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight);
              }),
        );
      }),
      floatingActionButton: BotonSubirReporte(
          screenWidth: screenWidth, screenHeight: screenHeight),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

enum Escaneo { cargando, completado }

class BotonSubirReporte extends StatelessWidget {
  BotonSubirReporte({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final TextEditingController _controllerText = TextEditingController();

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    SnackBar snackbar({required String texto, required Escaneo e}) {
      if (e == Escaneo.cargando) {
        return SnackBar(
            backgroundColor: Mocha.lavender.color,
            content: Row(
              spacing: screenWidth * 0.05,
              children: [
                Text(
                  texto,
                  style: TextStyle(color: Mocha.crust.color),
                ),
                CircularProgressIndicator(
                  color: Mocha.crust.color,
                )
              ],
            ));
      } else {
        return SnackBar(
            backgroundColor: Mocha.red.color,
            content: Text(
              texto,
              style: TextStyle(color: Mocha.crust.color),
            ));
      }
    }

    return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: Mocha.text.color,
            foregroundColor: Mocha.overlay2.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            minimumSize: Size(screenWidth * 0.40, screenHeight * 0.060)),
        onPressed: () async {
          final provider = Provider.of<TomarFoto>(context, listen: false);
          await provider.camara();

          await _pedirDescripcion(context);
          //print(_controllerText.text);

          ScaffoldMessenger.of(context).showSnackBar(
              snackbar(texto: "Escaneado Imagen", e: Escaneo.cargando));
          await provider.scanearFoto(foto: provider.foto!);

          /* if (provider.aceptada == FotoAceptada.no) {
            ScaffoldMessenger.of(context).showSnackBar(
                snackbar(texto: "Foto no aceptada", e: Escaneo.completado));
          } else {
            Navigator.pushNamed(context, '/subiendo',
                arguments: _controllerText.text);
          } */
          Navigator.pushNamed(context, '/subiendo',
              arguments: _controllerText.text);
        },
        label: Text(
          "Subir reporte",
          style: TextStyle(
              fontSize: (screenHeight + screenWidth) * 0.015,
              color: Mocha.mantle.color),
        ),
        icon: Icon(
          color: Mocha.mantle.color,
          Icons.add_a_photo,
          size: (screenHeight + screenWidth) * 0.025,
        ));
  }

  Future<dynamic> _pedirDescripcion(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Mocha.surface1.color,
            child: Container(
              height: screenHeight * 0.35,
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.060),
              color: Mocha.surface1.color,
              child: Column(
                children: [
                  TextField(
                    keyboardType: TextInputType.text,
                    onSubmitted: (value) => Navigator.pop(context),
                    controller: _controllerText,
                    cursorColor: Mocha.blue.color,
                    cursorWidth: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                        labelStyle: TextStyle(
                            color: Mocha.green.color,
                            fontSize: (screenWidth + screenHeight) * 0.023),
                        labelText: "Descripcion del reporte:"),
                    style: TextStyle(
                      fontSize: (screenHeight + screenWidth) * 0.019,
                      fontWeight: FontWeight.bold,
                      color: Mocha.blue.color,
                    ),
                    autofocus: true,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(),
                      IconButton(
                          iconSize: (screenHeight + screenWidth) * 0.045,
                          color: Mocha.green.color,
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.forward)),
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }
}

Widget cardreport(
    {required String nombre,
    required String descripcion,
    required urlimage,
    required double screenWidth,
    required double screenHeight}) {
  return Card(
    color: Mocha.overlay2.color,
    child: Column(
      children: [
        Image.network(
          urlimage,
          width: screenWidth * 0.3,
        ),
        Text(nombre,
            style: TextStyle(
              color: Mocha.text.color,
            ))
      ],
    ),
  );
}
