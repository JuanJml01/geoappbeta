// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:geoapptest/Model/reporteModel.dart';
import 'package:geoapptest/Provider/reporteProvider.dart';
import 'package:geoapptest/Provider/usuarioProvider.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class DetallesReportePage extends StatefulWidget {
  final Reporte reporte;

  const DetallesReportePage({Key? key, required this.reporte}) : super(key: key);

  @override
  State<DetallesReportePage> createState() => _DetallesReportePageState();
}

class _DetallesReportePageState extends State<DetallesReportePage> with SingleTickerProviderStateMixin {
  // Controlador para las pestañas
  late TabController _tabController;
  
  // Estado para la calificación
  int _calificacionSeleccionada = 0;
  String _comentario = '';
  bool _enviandoCalificacion = false;
  
  // Estado para el mapa
  late MapController _mapController;
  LatLng? _userLocation;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mapController = MapController();
    
    // Incrementar contador de vistas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Reporteprovider>().incrementarVistas(widget.reporte.id);
      _obtenerUbicacionUsuario();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }
  
  // Obtener ubicación del usuario para mostrar en el mapa
  Future<void> _obtenerUbicacionUsuario() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Ignorar errores, simplemente no mostrará la ubicación del usuario
    }
  }
  
  // Enviar calificación
  Future<void> _enviarCalificacion() async {
    if (_calificacionSeleccionada == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una calificación'))
      );
      return;
    }
    
    setState(() {
      _enviandoCalificacion = true;
    });
    
    final reporteProvider = context.read<Reporteprovider>();
    final usuarioProvider = context.read<UsuarioProvider>();
    
    final result = await reporteProvider.calificarReporte(
      widget.reporte.id,
      _calificacionSeleccionada,
      comentario: _comentario.isNotEmpty ? _comentario : null,
      email: usuarioProvider.usuarioActual?.nombre ?? 'Usuario Anónimo',
      userId: usuarioProvider.modoAnonimo ? null : usuarioProvider.usuarioActual?.id,
    );
    
    setState(() {
      _enviandoCalificacion = false;
    });
    
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tu valoración!'))
      );
      // Limpiar campos
      setState(() {
        _calificacionSeleccionada = 0;
        _comentario = '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar la valoración. Inténtalo de nuevo.'))
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.reporte.tipoTags.map((tag) => tag.nombre).join(', '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3.0,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'reporte_image_${widget.reporte.id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.reporte.imagen,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SpinKitPulse(color: Colors.white70, size: 50.0),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, size: 50, color: Colors.red),
                        ),
                      ),
                    ),
                    // Degradado para mejorar visibilidad del texto
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black54,
                          ],
                          stops: [0.7, 1.0],
                        ),
                      ),
                    ),
                    // Indicadores de prioridad y estadísticas
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (widget.reporte.prioridadComunidad)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.priority_high, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'PRIORITARIO',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.remove_red_eye, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.reporte.vistas}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(icon: Icon(Icons.description), text: 'Detalles'),
                  Tab(icon: Icon(Icons.map), text: 'Ubicación'),
                  Tab(icon: Icon(Icons.star), text: 'Valorar'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab de Detalles
            _buildDetallesTab(),
            
            // Tab de Ubicación
            _buildMapaTab(),
            
            // Tab de Valoración
            _buildValoracionTab(),
          ],
        ),
      ),
    );
  }
  
  // Construir el tab de detalles
  Widget _buildDetallesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen rápido con calificación y etiquetas
          _buildResumenRapido(),
          const Divider(height: 32),
          
          // Descripción
          const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            widget.reporte.descripcion.isNotEmpty 
                ? widget.reporte.descripcion 
                : 'No hay descripción disponible.',
            style: TextStyle(
              fontSize: 16, 
              color: widget.reporte.descripcion.isEmpty ? Colors.grey : null
            ),
          ),
          const SizedBox(height: 24),
          
          // Información adicional
          const Text('Información adicional:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          _buildInfoItem(Icons.calendar_today, 'Fecha', 
              '${widget.reporte.createdAt.day}/${widget.reporte.createdAt.month}/${widget.reporte.createdAt.year}'),
          _buildInfoItem(Icons.email, 'Reportado por', widget.reporte.email),
          _buildInfoItem(Icons.assessment, 'Estado', 
              widget.reporte.estado == EstadoReporte.pendiente 
                  ? 'Pendiente de revisión' 
                  : widget.reporte.estado == EstadoReporte.enProceso 
                      ? 'En proceso de solución' 
                      : 'Resuelto'),
          
          const SizedBox(height: 24),
          // Etiquetas
          const Text('Etiquetas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...widget.reporte.tipoTags.map((tag) => _buildChip(tag.nombre, tag.icono, Colors.blue)),
              ...widget.reporte.ubicacionTags.map((tag) => _buildChip(tag.nombre, tag.icono, Colors.green)),
            ],
          ),
          
          // Espacio adicional al final
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  // Construir el tab de mapa
  Widget _buildMapaTab() {
    final latLng = LatLng(widget.reporte.latitud, widget.reporte.longitud);
    
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: latLng,
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.geoapptest.app',
            ),
            MarkerLayer(
              markers: [
                // Marcador del reporte
                Marker(
                  point: latLng,
                  width: 80,
                  height: 80,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.reporte.tipoTags.first.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ],
                  ),
                ),
                
                // Marcador de la ubicación del usuario si está disponible
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        
        // Botones de control para el mapa
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'zoom_in',
                mini: true,
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoom_out',
                mini: true,
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              if (_userLocation != null)
                FloatingActionButton(
                  heroTag: 'directions',
                  onPressed: () {
                    // Aquí se podría agregar la función para obtener direcciones
                    // entre la ubicación del usuario y el reporte
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función de navegación en desarrollo'))
                    );
                  },
                  child: const Icon(Icons.directions),
                ),
            ],
          ),
        ),
        
        // Información de coordenadas
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latitud: ${widget.reporte.latitud.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12)),
                Text('Longitud: ${widget.reporte.longitud.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Construir el tab de valoración
  Widget _buildValoracionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '¿Te ha parecido importante este reporte?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Estrellas para calificar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                iconSize: 40,
                onPressed: () {
                  setState(() {
                    _calificacionSeleccionada = value;
                  });
                },
                icon: Icon(
                  _calificacionSeleccionada >= value 
                      ? Icons.star 
                      : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _calificacionSeleccionadaTexto(),
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 32),
          
          // Campo de comentario opcional
          TextField(
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              border: OutlineInputBorder(),
              hintText: 'Comparte tu opinión sobre este problema ambiental',
            ),
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                _comentario = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          // Botón de enviar valoración
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _enviandoCalificacion ? null : _enviarCalificacion,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _enviandoCalificacion
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ENVIAR VALORACIÓN', style: TextStyle(fontSize: 16)),
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          
          // Valoraciones existentes
          if (widget.reporte.calificaciones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Aún no hay valoraciones para este reporte. ¡Sé el primero en opinar!',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Valoraciones',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.reporte.calificaciones.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Aquí se mostrarían las valoraciones existentes
                // Por ahora solo mostramos un resumen de la calificación promedio
                if (widget.reporte.calificacionPromedio > 0)
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.amber,
                            radius: 24,
                            child: Text(
                              widget.reporte.calificacionPromedio.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Valoración promedio',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Basado en ${widget.reporte.calificaciones.length} opiniones',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < widget.reporte.calificacionPromedio.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
  
  // Resumen rápido con calificación y etiquetas principales
  Widget _buildResumenRapido() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calificación promedio
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getCalificacionColor(widget.reporte.calificacionPromedio),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.reporte.calificacionPromedio.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Puntuación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Información principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo principal
              Row(
                children: [
                  Icon(
                    widget.reporte.tipoTags.isNotEmpty 
                        ? widget.reporte.tipoTags.first.icono 
                        : Icons.help_outline,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.reporte.tipoTags.isNotEmpty 
                          ? widget.reporte.tipoTags.first.nombre 
                          : 'Tipo desconocido',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Ubicación principal
              Row(
                children: [
                  Icon(
                    widget.reporte.ubicacionTags.isNotEmpty 
                        ? widget.reporte.ubicacionTags.first.icono 
                        : Icons.place,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.reporte.ubicacionTags.isNotEmpty 
                          ? widget.reporte.ubicacionTags.first.nombre 
                          : 'Ubicación no especificada',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Importancia
              if (widget.reporte.importancia > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        widget.reporte.importancia > 7 
                            ? Icons.priority_high 
                            : (widget.reporte.importancia > 3 
                                ? Icons.trending_up 
                                : Icons.trending_flat),
                        color: _getImportanciaColor(widget.reporte.importancia),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getImportanciaText(widget.reporte.importancia),
                        style: TextStyle(
                          color: _getImportanciaColor(widget.reporte.importancia),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Item de información con icono y texto
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Chip para etiquetas
  Widget _buildChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
  
  // Obtener color según calificación
  Color _getCalificacionColor(double calificacion) {
    if (calificacion >= 4) return Colors.green;
    if (calificacion >= 3) return Colors.orange;
    if (calificacion > 0) return Colors.red;
    return Colors.grey; // Sin calificación
  }
  
  // Obtener color según importancia
  Color _getImportanciaColor(int importancia) {
    if (importancia >= 8) return Colors.red;
    if (importancia >= 5) return Colors.orange;
    if (importancia >= 3) return Colors.blue;
    return Colors.grey;
  }
  
  // Obtener texto según importancia
  String _getImportanciaText(int importancia) {
    if (importancia >= 8) return 'Alta prioridad';
    if (importancia >= 5) return 'Prioridad media';
    if (importancia >= 3) return 'Relevante';
    return 'Baja prioridad';
  }
  
  // Obtener texto según calificación seleccionada
  String _calificacionSeleccionadaTexto() {
    switch (_calificacionSeleccionada) {
      case 1:
        return 'No es importante';
      case 2:
        return 'Poco importante';
      case 3:
        return 'Moderadamente importante';
      case 4:
        return 'Importante';
      case 5:
        return 'Muy importante';
      default:
        return 'Selecciona una valoración';
    }
  }
} 