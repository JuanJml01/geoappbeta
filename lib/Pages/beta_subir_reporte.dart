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
        automaticallyImplyLeading: false,
        backgroundColor: EcoPalette.greenPrimary.color,
        foregroundColor: EcoPalette.white.color,
        elevation: 0,
        title: Text(
          "Mis reportes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<Reporteprovider>(builder: (context, reporteprovider, child) {
        if (!isInitialized) {
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
                    'Cargando reportes...',
                    style: TextStyle(
                      color: EcoPalette.greenDark.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (_tipoUser == TipoUser.anonimo) {
          return Container(
            color: EcoPalette.sand.color,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 64,
                    color: EcoPalette.gray.color,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Usuario Anónimo",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: EcoPalette.greenDark.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: Text(
                      "Inicia sesión con tu cuenta para ver tus reportes anteriores",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: EcoPalette.gray.color,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (reporteprovider.reportes.isEmpty) {
          return Container(
            color: EcoPalette.sand.color,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: EcoPalette.gray.color,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No hay reportes",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: EcoPalette.greenDark.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: Text(
                      "Tus reportes aparecerán aquí. Haz clic en el botón para crear uno nuevo.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: EcoPalette.gray.color,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Container(
          color: EcoPalette.sand.color,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 8, bottom: 16),
                child: Text(
                  "Tus reportes recientes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: EcoPalette.greenDark.color,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  itemCount: reporteprovider.reportes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    Reporte reporte = reporteprovider.reportes[index];
                    return ReporteCard(reporte: reporte);
                  },
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: BotonSubirReporte(
        screenWidth: screenWidth, 
        screenHeight: screenHeight
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ReporteCard extends StatelessWidget {
  final Reporte reporte;
  
  const ReporteCard({
    Key? key,
    required this.reporte,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/verReporte', arguments: reporte);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(reporte.imagen),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            // Información
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: EcoPalette.greenLight.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tipoReporteToString(reporte.tipo),
                          style: TextStyle(
                            color: EcoPalette.greenDark.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: EcoPalette.greenPrimary.color,
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    reporte.descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: EcoPalette.black.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
  final TextEditingController _tipoController = TextEditingController();
  TipoReporte _selectedTipo = TipoReporte.otro;

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: EcoPalette.greenPrimary.color,
        foregroundColor: EcoPalette.white.color,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: () async {
        final provider = Provider.of<TomarFoto>(context, listen: false);
        await provider.camara();
        
        if (provider.foto != null) {
          await _pedirDetallesReporte(context);
          
          if (_controllerText.text.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Text('Procesando imagen...'),
                    SizedBox(width: 16),
                    CircularProgressIndicator(
                      color: EcoPalette.white.color,
                      strokeWidth: 2,
                    ),
                  ],
                ),
                backgroundColor: EcoPalette.greenDark.color,
                duration: Duration(seconds: 2),
              ),
            );
            
            await provider.scanearFoto(foto: provider.foto!);
            
            Navigator.pushNamed(
              context, 
              '/subiendo',
              arguments: _controllerText.text,
            );
          }
        }
      },
      icon: Icon(
        Icons.add_a_photo,
        size: 24,
      ),
      label: Text(
        "Crear nuevo reporte",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _pedirDetallesReporte(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: EcoPalette.white.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: EcoPalette.greenPrimary.color),
                    SizedBox(width: 8),
                    Text(
                      'Detalles del reporte',
                      style: TextStyle(
                        color: EcoPalette.greenDark.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Tipo de reporte
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: EcoPalette.greenLight.color),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TipoReporte>(
                        hint: Text(
                          'Seleccionar tipo de reporte',
                          style: TextStyle(color: EcoPalette.gray.color),
                        ),
                        value: _selectedTipo,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: EcoPalette.greenPrimary.color),
                        items: TipoReporte.values.map((TipoReporte value) {
                          return DropdownMenuItem<TipoReporte>(
                            value: value,
                            child: Text(tipoReporteToString(value)),
                          );
                        }).toList(),
                        onChanged: (TipoReporte? newValue) {
                          if (newValue != null) {
                            _selectedTipo = newValue;
                          }
                        },
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Descripción
                TextField(
                  controller: _controllerText,
                  cursorColor: EcoPalette.greenPrimary.color,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Descripción del reporte',
                    labelStyle: TextStyle(
                      color: EcoPalette.gray.color,
                    ),
                    hintText: 'Describe el problema ambiental...',
                    hintStyle: TextStyle(
                      color: EcoPalette.gray.color.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: EcoPalette.greenLight.color),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: EcoPalette.greenPrimary.color, width: 2),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: EcoPalette.black.color,
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: EcoPalette.gray.color,
                      ),
                      child: Text('Cancelar'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_controllerText.text.isNotEmpty) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Por favor, ingresa una descripción'),
                              backgroundColor: EcoPalette.error.color,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EcoPalette.greenPrimary.color,
                        foregroundColor: EcoPalette.white.color,
                      ),
                      child: Text('Continuar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
