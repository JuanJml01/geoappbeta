import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geoapptest/Model/reporteModel.dart';
import 'package:geoapptest/Service/logger_service.dart';
import 'package:geoapptest/mocha.dart';

import 'package:latlong2/latlong.dart';

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
          floatingActionButton: FloatingActionButton.large(
            elevation: 20,
            backgroundColor: Mocha.base.color,
            foregroundColor: Mocha.blue.color,
            onPressed: () {
              _mapcontroller.move(LatLng(args.latitud, args.longitud), 15);
            },
            child: Icon(Icons.my_location_rounded),
          ),
          appBar: AppBar(
              foregroundColor: Mocha.green.color,
              backgroundColor: Mocha.base.color,
              bottom: TabBar(
                unselectedLabelStyle:
                    TextStyle(fontSize: (screenHeight + screenWidth) * 0.013),
                labelStyle:
                    TextStyle(fontSize: (screenHeight + screenWidth) * 0.017),
                indicatorColor: Mocha.overlay2.color,
                labelColor: Mocha.overlay2.color,
                unselectedLabelColor: Mocha.surface2.color,
                labelPadding:
                    EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                indicatorWeight: 5,
                tabAlignment: TabAlignment.center,
                isScrollable: true,
                tabs: [
                  Tab(
                    text: "Informacion",
                    icon: Icon(Icons.info),
                  ),
                  Tab(
                    text: "Mapa",
                    icon: Icon(Icons.map),
                  )
                ],
              )),
          body: Container(
            color: Mocha.base.color,
            child: TabBarView(children: [
              Container(
                  color: Mocha.base.color,
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: ListView(
                    children: [
                      SizedBox(
                        height: screenHeight * 0.05,
                      ),
                      Text(
                        "Correo: ${args.email}",
                        style: TextStyle(
                            fontSize: (screenHeight + screenWidth) * 0.014,
                            color: Mocha.text.color),
                      ),
                      SizedBox(
                        height: screenHeight * 0.02,
                      ),
                      Text(
                        "Descripcion: ${args.descripcion}",
                        style: TextStyle(
                            fontSize: (screenHeight + screenWidth) * 0.014,
                            color: Mocha.subtext0.color),
                      ),
                      SizedBox(
                        height: screenHeight * 0.02,
                      ),
                      Image.network(args.imagen)
                    ],
                  )),
              FlutterMap(
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
                      }),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    MarkerLayer(markers: [
                      Marker(
                          width: 100,
                          height: 100,
                          alignment: Alignment.center,
                          point: LatLng(
                            args.latitud,
                            args.longitud,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Mocha.green.color.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Mocha.base.color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_pin,
                              color: Mocha.crust.color,
                              size: (screenHeight + screenWidth) * 0.05,
                            ),
                          ))
                    ]),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ])
            ]),
          ),
        ));
  }
}
