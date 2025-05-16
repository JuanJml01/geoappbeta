import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/Service/logger_service.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VerReporte extends StatefulWidget {
  const VerReporte({super.key});

  @override
  State<VerReporte> createState() => _VerReporteState();
}

class _VerReporteState extends State<VerReporte> {
  final _mapcontroller = MapController();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final args = ModalRoute.of(context)!.settings.arguments as Reporte;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: EcoPalette.sand.color,
        floatingActionButton: FloatingActionButton(
          elevation: 4,
          backgroundColor: EcoPalette.greenPrimary.color,
          foregroundColor: EcoPalette.white.color,
          onPressed: () {
            _mapcontroller.move(LatLng(args.latitud, args.longitud), 15);
          },
          child: Icon(Icons.my_location_rounded),
        ),
        appBar: AppBar(
          backgroundColor: EcoPalette.greenPrimary.color,
          foregroundColor: EcoPalette.white.color,
          elevation: 0,
          title: Text(
            'Detalle del reporte',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            labelStyle: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14
            ),
            indicatorColor: EcoPalette.white.color,
            labelColor: EcoPalette.white.color,
            unselectedLabelColor: EcoPalette.white.color.withOpacity(0.7),
            indicatorWeight: 3,
            tabs: [
              Tab(
                text: "Información",
                icon: Icon(Icons.info_outline),
              ),
              Tab(
                text: "Ubicación",
                icon: Icon(Icons.map_outlined),
              )
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña de información
            Container(
              color: EcoPalette.sand.color,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del reporte con Hero animation
                    Hero(
                      tag: 'reporte-${args.id}',
                      child: Container(
                        height: screenHeight * 0.3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: EcoPalette.black.color.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Semantics(
                            label: 'Imagen del reporte ${tipoReporteToString(args.tipo)}',
                            image: true,
                            child: CachedNetworkImage(
                              imageUrl: args.imagen,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => Container(
                                color: EcoPalette.grayLight.color,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: EcoPalette.greenPrimary.color,
                                    semanticsLabel: 'Cargando imagen',
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: EcoPalette.grayLight.color,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        color: EcoPalette.error.color,
                                        size: 48,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Error al cargar la imagen',
                                        style: TextStyle(
                                          color: EcoPalette.error.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Tipo y estado del reporte
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: EcoPalette.white.color,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: EcoPalette.black.color.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category,
                                  color: EcoPalette.greenPrimary.color,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  tipoReporteToString(args.tipo),
                                  style: TextStyle(
                                    color: EcoPalette.greenDark.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _getEstadoColor(estadoReporteToString(args.estado)).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: EcoPalette.black.color.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: _getEstadoColor(estadoReporteToString(args.estado)),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  estadoReporteToString(args.estado),
                                  style: TextStyle(
                                    color: _getEstadoColor(estadoReporteToString(args.estado)),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Información del reporte
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EcoPalette.white.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: EcoPalette.black.color.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fecha
                          Row(
                            children: [
                              Icon(Icons.calendar_today, 
                                size: 16, 
                                color: EcoPalette.greenPrimary.color
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Fecha: ${DateFormat('dd/MM/yyyy - HH:mm').format(args.createdAt)}',
                                style: TextStyle(
                                  color: EcoPalette.greenDark.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 12),
                          
                          // Correo del reportante
                          Row(
                            children: [
                              Icon(Icons.email, 
                                size: 16, 
                                color: EcoPalette.greenPrimary.color
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Reportado por:',
                                style: TextStyle(
                                  color: EcoPalette.greenDark.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 24),
                            child: Text(
                              args.email,
                              style: TextStyle(
                                color: EcoPalette.black.color,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Descripción
                          Row(
                            children: [
                              Icon(Icons.description, 
                                size: 16, 
                                color: EcoPalette.greenPrimary.color
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Descripción:',
                                style: TextStyle(
                                  color: EcoPalette.greenDark.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: EcoPalette.sand.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              args.descripcion,
                              style: TextStyle(
                                color: EcoPalette.black.color,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Coordenadas
                          Row(
                            children: [
                              Icon(Icons.location_on, 
                                size: 16, 
                                color: EcoPalette.greenPrimary.color
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Coordenadas:',
                                style: TextStyle(
                                  color: EcoPalette.greenDark.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 24),
                            child: Text(
                              'Latitud: ${args.latitud.toStringAsFixed(6)}\nLongitud: ${args.longitud.toStringAsFixed(6)}',
                              style: TextStyle(
                                color: EcoPalette.black.color,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Pestaña del mapa
            Semantics(
              label: 'Mapa con ubicación del reporte',
              child: FlutterMap(
                mapController: _mapcontroller,
                options: MapOptions(
                  initialZoom: 15,
                  minZoom: 4,
                  maxZoom: 18,
                  initialCenter: LatLng(args.latitud, args.longitud),
                  onMapReady: () {
                    LoggerService().logMapInteraction(
                      action: 'REPORT_MAP_READY',
                      details: {
                        'report_position': {
                          'lat': args.latitud,
                          'lng': args.longitud
                        }
                      },
                    );
                  }
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.geoapp.app',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      point: LatLng(
                        args.latitud,
                        args.longitud,
                      ),
                      child: Semantics(
                        label: 'Ubicación del reporte en el mapa',
                        child: Container(
                          decoration: BoxDecoration(
                            color: EcoPalette.greenPrimary.color.withOpacity(0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: EcoPalette.black.color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_pin,
                            color: EcoPalette.white.color,
                            size: 30,
                          ),
                        ),
                      ),
                    )
                  ]),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ]
              ),
            )
          ]
        ),
      )
    );
  }
  
  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return EcoPalette.warning.color;
      case 'en proceso':
        return EcoPalette.info.color;
      case 'resuelto':
        return EcoPalette.success.color;
      default:
        return EcoPalette.info.color;
    }
  }
}
