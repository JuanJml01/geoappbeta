// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Provider/usuarioProvider.dart';
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
  
  // Estado para votación de prioridad
  bool _votandoPrioridad = false;
  bool? _votoActual;
  
  // Estado para seguimiento
  bool _enSeguimiento = false;
  bool _cambiandoSeguimiento = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mapController = MapController();
    
    // Incrementar contador de vistas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Reporteprovider>().incrementarVistas(widget.reporte.id);
      _obtenerUbicacionUsuario();
      _verificarSeguimiento();
      
      // Escuchar cambios de pestaña para inicializar el mapa cuando sea necesario
      _tabController.addListener(_handleTabChange);
    });
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }
  
  // Manejar cambios de pestaña
  void _handleTabChange() {
    // Si cambiamos a la pestaña del mapa, asegurar que se renderice correctamente
    if (_tabController.index == 1) {
      // Pequeño retraso para asegurar que el widget del mapa esté montado
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _mapController.camera.zoom == 0) {
          final reporteLatLng = LatLng(widget.reporte.latitud, widget.reporte.longitud);
          _mapController.move(reporteLatLng, 15.0);
        }
      });
    }
  }
  
  // Verificar si el reporte está en seguimiento
  void _verificarSeguimiento() {
    final usuarioProvider = context.read<UsuarioProvider>();
    setState(() {
      _enSeguimiento = usuarioProvider.estaEnSeguimiento(widget.reporte.id);
    });
  }
  
  // Cambiar estado de seguimiento
  Future<void> _toggleSeguimiento() async {
    if (_cambiandoSeguimiento) return;
    
    setState(() {
      _cambiandoSeguimiento = true;
    });
    
    final usuarioProvider = context.read<UsuarioProvider>();
    bool resultado;
    
    if (_enSeguimiento) {
      resultado = await usuarioProvider.eliminarReporteSeguimiento(widget.reporte.id);
    } else {
      resultado = await usuarioProvider.agregarReporteSeguimiento(widget.reporte.id);
    }
    
    if (resultado) {
      setState(() {
        _enSeguimiento = !_enSeguimiento;
      });
    }
    
    setState(() {
      _cambiandoSeguimiento = false;
    });
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
    if (_calificacionSeleccionada == 0 || _enviandoCalificacion) {
      return;
    }
    
    setState(() {
      _enviandoCalificacion = true;
    });
    
    try {
      final usuarioProvider = context.read<UsuarioProvider>();
      final resultado = await usuarioProvider.calificarReporte(
        widget.reporte.id, 
        _calificacionSeleccionada,
        comentario: _comentario.isNotEmpty ? _comentario : null,
      );
      
      if (resultado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Gracias por tu valoración!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar el reporte para ver la nueva calificación
        await context.read<Reporteprovider>().cargarReporte(widget.reporte.id);
        
        setState(() {
          _comentario = '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo enviar la valoración. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _enviandoCalificacion = false;
      });
    }
  }
  
  // Votar por la prioridad
  Future<void> _votarPrioridad(bool esPrioritario) async {
    if (_votandoPrioridad) return;
    
    setState(() {
      _votandoPrioridad = true;
    });
    
    try {
      final usuarioProvider = context.read<UsuarioProvider>();
      final resultado = await usuarioProvider.votarPrioridadReporte(
        widget.reporte.id, 
        esPrioritario,
      );
      
      if (resultado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Gracias por tu voto!'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _votoActual = esPrioritario;
        });
        
        // Recargar el reporte para actualizar la prioridad
        await context.read<Reporteprovider>().cargarReporte(widget.reporte.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo registrar tu voto. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _votandoPrioridad = false;
      });
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
                    // Imagen del reporte
                    CachedNetworkImage(
                      imageUrl: widget.reporte.imagen,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: SpinKitPulse(
                            color: Colors.white,
                            size: 50.0,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                    ),
                    
                    // Gradiente para mejorar legibilidad del título
                    const Positioned.fill(
                      child: DecoratedBox(
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
                    ),
                    
                    // Información adicional en la imagen
                    Positioned(
                      bottom: 50,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Calificación promedio
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.reporte.calificacionPromedio.toStringAsFixed(1)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          
                          // Contador de vistas
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
              actions: [
                // Botón de seguimiento
                IconButton(
                  icon: Icon(
                    _enSeguimiento ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                  ),
                  onPressed: _cambiandoSeguimiento ? null : _toggleSeguimiento,
                  tooltip: _enSeguimiento ? 'Quitar de seguimiento' : 'Seguir reporte',
                ),
              ],
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
                      : widget.reporte.estado == EstadoReporte.cancelado
                          ? 'Cancelado'
                          : 'Resuelto',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.reporte.estado == EstadoReporte.pendiente
                      ? Colors.orange
                      : widget.reporte.estado == EstadoReporte.enProceso
                          ? Colors.blue
                          : widget.reporte.estado == EstadoReporte.cancelado
                              ? Colors.red
                              : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.reporte.estado == EstadoReporte.pendiente
                      ? 'Pendiente'
                      : widget.reporte.estado == EstadoReporte.enProceso
                          ? 'En proceso'
                          : widget.reporte.estado == EstadoReporte.cancelado
                              ? 'Cancelado'
                              : 'Resuelto',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ),
          
          // Sección de importancia y prioridad
          const SizedBox(height: 24),
          const Text('Importancia y prioridad:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          
          // Importancia basada en calificaciones
          _buildInfoItem(
            Icons.star_rate, 
            'Importancia', 
            widget.reporte.importancia > 0 
                ? '${widget.reporte.importancia}/10'
                : 'Sin calificación',
            trailing: widget.reporte.calificacionPromedio > 0 
                ? Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (widget.reporte.calificacionPromedio / 2).round() 
                            ? Icons.star 
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  )
                : null,
          ),
          
          // Prioridad comunitaria
          _buildInfoItem(
            Icons.people, 
            'Prioridad comunitaria', 
            widget.reporte.prioridadComunidad ? 'Alta' : 'Normal',
            trailing: Row(
              children: [
                // Botón para votar "Sí es prioritario"
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    color: _votoActual == true ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  onPressed: _votandoPrioridad ? null : () => _votarPrioridad(true),
                  tooltip: 'Es prioritario',
                ),
                
                // Botón para votar "No es prioritario"
                IconButton(
                  icon: Icon(
                    Icons.thumb_down,
                    color: _votoActual == false ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                  onPressed: _votandoPrioridad ? null : () => _votarPrioridad(false),
                  tooltip: 'No es prioritario',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          // Etiquetas
          const Text('Etiquetas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          
          // Mostrar etiquetas de tipo
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.reporte.tipoTags.map((tag) {
              return Chip(
                avatar: Icon(tag.icono, size: 16),
                label: Text(tag.nombre),
                backgroundColor: Colors.blue.withOpacity(0.1),
                side: BorderSide(color: Colors.blue.withOpacity(0.3)),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Mostrar etiquetas de ubicación
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.reporte.ubicacionTags.map((tag) {
              return Chip(
                avatar: Icon(tag.icono, size: 16),
                label: Text(tag.nombre),
                backgroundColor: Colors.green.withOpacity(0.1),
                side: BorderSide(color: Colors.green.withOpacity(0.3)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  // Construir un elemento de información
  Widget _buildInfoItem(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
  
  // Construir el resumen rápido
  Widget _buildResumenRapido() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icono principal
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: Icon(
            widget.reporte.tipoTags.isNotEmpty 
                ? widget.reporte.tipoTags.first.icono 
                : Icons.help_outline,
            color: Colors.blue,
            size: 30,
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
            ],
          ),
        ),
      ],
    );
  }
  
  // Construir el tab del mapa
  Widget _buildMapaTab() {
    final reporteLatLng = LatLng(widget.reporte.latitud, widget.reporte.longitud);
    
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: reporteLatLng,
            initialZoom: 15.0,
            onMapReady: () {
              // Asegurar que el mapa se centre correctamente cuando esté listo
              _mapController.move(reporteLatLng, 15.0);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.geoappbeta.app',
              // Añadir opciones adicionales para mejorar la carga
              maxZoom: 19,
              keepBuffer: 5,
              tileSize: 256,
              backgroundColor: Colors.grey[300],
            ),
            MarkerLayer(
              markers: [
                // Marcador del reporte
                Marker(
                  point: reporteLatLng,
                  width: 40,
                  height: 40,
                  child: Icon(
                    widget.reporte.tipoTags.isNotEmpty 
                        ? widget.reporte.tipoTags.first.icono 
                        : Icons.pin_drop,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                
                // Marcador de la ubicación del usuario (si está disponible)
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 30,
                    height: 30,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
              ],
            ),
          ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e instrucciones
          const Text(
            'Valora este reporte',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu valoración ayuda a determinar la importancia de este problema ambiental.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Estrellas para calificar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                icon: Icon(
                  _calificacionSeleccionada >= starValue * 2 
                      ? Icons.star 
                      : _calificacionSeleccionada >= starValue * 2 - 1 
                          ? Icons.star_half 
                          : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    _calificacionSeleccionada = starValue * 2;
                  });
                },
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          // Texto descriptivo de la calificación
          Center(
            child: Text(
              _getCalificacionDescripcion(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Campo para comentario
          TextField(
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              hintText: 'Escribe un comentario sobre este reporte...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _comentario = value;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Botón para enviar valoración
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calificacionSeleccionada > 0 && !_enviandoCalificacion 
                  ? _enviarCalificacion 
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _enviandoCalificacion 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enviar valoración',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          
          // Sección de prioridad comunitaria
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          
          const Text(
            '¿Consideras que este problema es prioritario?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu voto ayuda a determinar qué problemas ambientales deberían atenderse primero.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Botones para votar prioridad
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón "No es prioritario"
              ElevatedButton.icon(
                onPressed: _votandoPrioridad ? null : () => _votarPrioridad(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _votoActual == false ? Colors.red[100] : null,
                  foregroundColor: Colors.red,
                ),
                icon: const Icon(Icons.thumb_down),
                label: const Text('No es prioritario'),
              ),
              
              // Botón "Es prioritario"
              ElevatedButton.icon(
                onPressed: _votandoPrioridad ? null : () => _votarPrioridad(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _votoActual == true ? Colors.green[100] : null,
                  foregroundColor: Colors.green,
                ),
                icon: const Icon(Icons.thumb_up),
                label: const Text('Es prioritario'),
              ),
            ],
          ),
          
          // Sección de comentarios
          if (widget.reporte.calificaciones.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Icon(Icons.comment, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Comentarios (${widget.reporte.calificaciones.where((c) => c.comentario != null && c.comentario!.isNotEmpty).length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lista de comentarios
            ...widget.reporte.calificaciones
              .where((c) => c.comentario != null && c.comentario!.isNotEmpty)
              .map((c) => _buildComentarioItem(c))
              .toList(),
          ],
        ],
      ),
    );
  }
  
  // Construir un elemento de comentario
  Widget _buildComentarioItem(ReporteCalificacion calificacion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar del usuario (genérico)
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                radius: 16,
                child: Text(
                  (calificacion.email ?? 'A').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Nombre del usuario o "Anónimo"
              Expanded(
                child: Text(
                  calificacion.email?.split('@').first ?? 'Usuario anónimo',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Calificación con estrellas
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < (calificacion.calificacion / 2).round() 
                        ? Icons.star 
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comentario
          Text(calificacion.comentario ?? ''),
          const SizedBox(height: 4),
          // Fecha del comentario
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '${calificacion.createdAt.day}/${calificacion.createdAt.month}/${calificacion.createdAt.year}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Obtener descripción de la calificación
  String _getCalificacionDescripcion() {
    switch (_calificacionSeleccionada) {
      case 0:
        return 'Selecciona una calificación';
      case 1:
      case 2:
        return 'Poco importante';
      case 3:
      case 4:
        return 'Algo importante';
      case 5:
      case 6:
        return 'Importante';
      case 7:
      case 8:
        return 'Muy importante';
      case 9:
      case 10:
        return 'Extremadamente importante';
      default:
        return '';
    }
  }
} 