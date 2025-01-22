import 'package:flutter/material.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:geoappbeta/Service/tomarFoto.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:getwidget/components/list_tile/gf_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubirReporte extends StatefulWidget {
  const SubirReporte({super.key});

  @override
  State<SubirReporte> createState() => _SubirReporteState();
}

enum tipoUser { anonimo, email }

class _SubirReporteState extends State<SubirReporte> {
  bool isInitialized = false;
  tipoUser _tipoUser = tipoUser.email;
  @override
  void initState() {
    super.initState();
    _inicializarDato();
  }

  Future<void> _inicializarDato() async {
    if (!isInitialized) {
      final provider = Provider.of<Reporteprovider>(context, listen: false);
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
            _tipoUser = tipoUser.email;
          } else {
            isInitialized = true;
            _tipoUser = tipoUser.anonimo;
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

        if (_tipoUser == tipoUser.anonimo) {
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
                    nombre: reporte.nombre,
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

class BotonSubirReporte extends StatelessWidget {
  const BotonSubirReporte({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    final snackbar = SnackBar(content: Text("Foto no aceptada"));

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
          //await provider.scanearFoto(foto: provider.foto);

          /* if (provider.aceptada == FotoAceptada.no) {
            ScaffoldMessenger.of(context).showSnackBar(snackbar);
            print(provider.aceptada);
          } else {
            Navigator.pushNamed(context, '/subiendo');
          } */
          if (provider.foto != null) {
            Navigator.pushNamed(context, '/subiendo');
          }
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
