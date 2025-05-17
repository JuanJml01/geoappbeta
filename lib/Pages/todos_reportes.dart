import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geoappbeta/Provider/usuarioProvider.dart';

class TodosReportesPage extends StatefulWidget {
  const TodosReportesPage({super.key});

  @override
  State<TodosReportesPage> createState() => _TodosReportesPageState();
}

class _TodosReportesPageState extends State<TodosReportesPage> {
  String? filtroTipo;
  String? filtroEstado;
  DateTimeRange? filtroFecha;
  double? filtroCalificacionMinima;
  bool? filtroPrioritarios;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _pageSize = 10;
  int _currentDisplayed = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.7 && !_isLoading) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Simular la carga de más elementos con un breve delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentDisplayed += _pageSize;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: EcoPalette.greenPrimary.color,
        foregroundColor: EcoPalette.white.color,
        elevation: 0,
        title: const Text('Todos los reportes'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt, color: EcoPalette.white.color),
            tooltip: 'Filtrar reportes',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => _FiltrosDialog(
                  onFiltro: (tipo, estado, fecha, calificacionMinima, soloReportesPrioritarios) {
                    setState(() {
                      filtroTipo = tipo;
                      filtroEstado = estado;
                      filtroFecha = fecha;
                      filtroCalificacionMinima = calificacionMinima;
                      filtroPrioritarios = soloReportesPrioritarios;
                      // Resetear a la primera página al aplicar filtros
                      _currentDisplayed = _pageSize;
                    });
                  },
                ),
              );
            },
          )
        ],
      ),
      body: Consumer<Reporteprovider>(
        builder: (context, reporteProvider, child) {
          List<Reporte> allReportes = reporteProvider.reportes;
          
          // Aplicar filtros
          if (filtroTipo != null && filtroTipo!.isNotEmpty) {
            allReportes = allReportes.where((r) => tipoReporteToString(r.tipo) == filtroTipo).toList();
          }
          if (filtroEstado != null && filtroEstado!.isNotEmpty) {
            allReportes = allReportes.where((r) => estadoReporteToString(r.estado) == filtroEstado).toList();
          }
          if (filtroFecha != null) {
            allReportes = allReportes.where((r) =>
              r.createdAt.isAfter(filtroFecha!.start.subtract(const Duration(days: 1))) &&
              r.createdAt.isBefore(filtroFecha!.end.add(const Duration(days: 1)))
            ).toList();
          }
          // Filtrar por calificación mínima
          if (filtroCalificacionMinima != null) {
            allReportes = allReportes.where((r) => r.calificacionPromedio >= filtroCalificacionMinima!).toList();
          }
          // Filtrar solo prioritarios
          if (filtroPrioritarios == true) {
            allReportes = allReportes.where((r) => r.prioridadComunidad).toList();
          }
          
          // Ordenar por fecha de creación, más recientes primero
          allReportes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Mensaje cuando no hay reportes
          if (allReportes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: EcoPalette.gray.color,
                    semanticLabel: 'No hay resultados',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay reportes para mostrar.',
                    style: TextStyle(
                      color: EcoPalette.black.color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Aplicar paginación
          List<Reporte> paginatedReportes = allReportes.length > _currentDisplayed
              ? allReportes.sublist(0, _currentDisplayed)
              : allReportes;

          return Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(screenWidth * 0.03),
                itemCount: paginatedReportes.length + 1, // +1 para el indicador de carga
                itemBuilder: (context, i) {
                  // Indicador de carga al final de la lista
                  if (i == paginatedReportes.length) {
                    return _isLoading && allReportes.length > _currentDisplayed
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: EcoPalette.greenPrimary.color,
                                semanticsLabel: 'Cargando más reportes',
                              ),
                            ),
                          )
                        : SizedBox.shrink();
                  }

                  final reporte = paginatedReportes[i];
                  return Semantics(
                    label: 'Reporte de ${tipoReporteToString(reporte.tipo)} en estado ${estadoReporteToString(reporte.estado)}',
                    hint: 'Toca para ver detalles',
                    child: Card(
                      color: EcoPalette.white.color,
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          // Contenido principal de la tarjeta
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Hero(
                              tag: 'reporte-${reporte.id}',
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: EcoPalette.black.color.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: reporte.imagen,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: EcoPalette.grayLight.color,
                                      child: Icon(
                                        Icons.image,
                                        color: EcoPalette.gray.color,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: EcoPalette.grayLight.color,
                                      child: Icon(
                                        Icons.broken_image,
                                        color: EcoPalette.error.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tipoReporteToString(reporte.tipo),
                                    style: TextStyle(
                                      color: EcoPalette.greenDark.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Indicador de prioridad
                                if (reporte.prioridadComunidad)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.priority_high, color: Colors.orange, size: 12),
                                        SizedBox(width: 2),
                                        Text(
                                          'Prioritario',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reporte.descripcion,
                                  style: TextStyle(
                                    color: EcoPalette.black.color,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Calificación promedio
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: EcoPalette.amber.color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star, 
                                            size: 12, 
                                            color: EcoPalette.amber.color
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            '${reporte.calificacionPromedio.toStringAsFixed(1)}',
                                            style: TextStyle(
                                              color: EcoPalette.amber.color, 
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    // Fecha
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: EcoPalette.greenLight.color,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today, 
                                            size: 12, 
                                            color: EcoPalette.greenDark.color
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            '${reporte.createdAt.day}/${reporte.createdAt.month}/${reporte.createdAt.year}',
                                            style: TextStyle(
                                              color: EcoPalette.greenDark.color, 
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    // Estado
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getEstadoColor(estadoReporteToString(reporte.estado)).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.flag, 
                                            size: 12, 
                                            color: _getEstadoColor(estadoReporteToString(reporte.estado))
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            estadoReporteToString(reporte.estado),
                                            style: TextStyle(
                                              color: _getEstadoColor(estadoReporteToString(reporte.estado)), 
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pushNamed(context, '/verReporte', arguments: reporte);
                            },
                          ),
                          
                          // Barra de acciones rápidas
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Divider(height: 1, color: EcoPalette.grayLight.color),
                          ),
                          
                          // Botones de acción
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Botón de seguimiento
                                _buildSeguimientoButton(context, reporte),
                                
                                // Botón de calificación
                                _buildCalificacionButton(context, reporte),
                                
                                // Botón de prioridad
                                _buildPrioridadButton(context, reporte),
                                
                                // Botón de ver detalles
                                IconButton(
                                  icon: Icon(
                                    Icons.visibility,
                                    color: EcoPalette.greenPrimary.color,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/verReporte', arguments: reporte);
                                  },
                                  tooltip: 'Ver detalles',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Botón "Volver al inicio" para navegación rápida cuando la lista es larga
              if (_scrollController.hasClients && _scrollController.offset > 300)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: 1.0,
                    child: FloatingActionButton.small(
                      backgroundColor: EcoPalette.greenPrimary.color,
                      foregroundColor: EcoPalette.white.color,
                      tooltip: 'Volver al inicio',
                      child: Icon(Icons.arrow_upward),
                      onPressed: () {
                        _scrollController.animateTo(
                          0,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      backgroundColor: EcoPalette.sand.color,
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
      case 'cancelado':
        return Colors.red;
      default:
        return EcoPalette.info.color;
    }
  }

  // Método para construir el botón de seguimiento
  Widget _buildSeguimientoButton(BuildContext context, Reporte reporte) {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final enSeguimiento = usuarioProvider.estaEnSeguimiento(reporte.id);
    
    return IconButton(
      icon: Icon(
        enSeguimiento ? Icons.bookmark : Icons.bookmark_border,
        color: enSeguimiento ? EcoPalette.blue.color : EcoPalette.gray.color,
        size: 20,
      ),
      onPressed: () async {
        if (enSeguimiento) {
          await usuarioProvider.eliminarReporteSeguimiento(reporte.id);
        } else {
          await usuarioProvider.agregarReporteSeguimiento(reporte.id);
        }
        // Forzar reconstrucción
        setState(() {});
      },
      tooltip: enSeguimiento ? 'Quitar de seguimiento' : 'Seguir reporte',
    );
  }
  
  // Método para construir el botón de calificación
  Widget _buildCalificacionButton(BuildContext context, Reporte reporte) {
    return IconButton(
      icon: Icon(
        Icons.star_border,
        color: EcoPalette.amber.color,
        size: 20,
      ),
      onPressed: () {
        _mostrarDialogoCalificacion(context, reporte);
      },
      tooltip: 'Calificar reporte',
    );
  }
  
  // Método para construir el botón de prioridad
  Widget _buildPrioridadButton(BuildContext context, Reporte reporte) {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    
    return IconButton(
      icon: Icon(
        Icons.priority_high,
        color: reporte.prioridadComunidad ? Colors.orange : EcoPalette.gray.color,
        size: 20,
      ),
      onPressed: () {
        _mostrarDialogoPrioridad(context, reporte);
      },
      tooltip: 'Marcar como prioritario',
    );
  }
  
  // Diálogo para calificar un reporte
  void _mostrarDialogoCalificacion(BuildContext context, Reporte reporte) {
    int calificacionSeleccionada = 0;
    String comentario = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Calificar reporte'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('¿Qué tan importante consideras este problema ambiental?'),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          calificacionSeleccionada >= starValue * 2 
                              ? Icons.star 
                              : calificacionSeleccionada >= starValue * 2 - 1 
                                  ? Icons.star_half 
                                  : Icons.star_border,
                          color: EcoPalette.amber.color,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            calificacionSeleccionada = starValue * 2;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Comentario (opcional)',
                      hintText: 'Escribe un comentario sobre este reporte...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      comentario = value;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Enviar'),
                  onPressed: calificacionSeleccionada > 0 ? () async {
                    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
                    await usuarioProvider.calificarReporte(
                      reporte.id,
                      calificacionSeleccionada,
                      comentario: comentario.isNotEmpty ? comentario : null,
                    );
                    
                    // Recargar el reporte
                    final reporteProvider = Provider.of<Reporteprovider>(context, listen: false);
                    await reporteProvider.cargarReporte(reporte.id);
                    
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('¡Gracias por tu valoración!'),
                        backgroundColor: EcoPalette.success.color,
                      ),
                    );
                  } : null,
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Diálogo para marcar un reporte como prioritario
  void _mostrarDialogoPrioridad(BuildContext context, Reporte reporte) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Prioridad del reporte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Consideras que este problema ambiental es prioritario?'),
              SizedBox(height: 16),
              Text(
                'Tu voto ayuda a determinar qué problemas ambientales deberían atenderse primero.',
                style: TextStyle(
                  color: EcoPalette.gray.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: Icon(Icons.thumb_down, color: EcoPalette.error.color),
              label: Text('No es prioritario'),
              onPressed: () async {
                final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
                await usuarioProvider.votarPrioridadReporte(reporte.id, false);
                
                // Recargar el reporte
                final reporteProvider = Provider.of<Reporteprovider>(context, listen: false);
                await reporteProvider.cargarReporte(reporte.id);
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('¡Gracias por tu voto!'),
                    backgroundColor: EcoPalette.success.color,
                  ),
                );
              },
            ),
            TextButton.icon(
              icon: Icon(Icons.thumb_up, color: EcoPalette.success.color),
              label: Text('Es prioritario'),
              onPressed: () async {
                final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
                await usuarioProvider.votarPrioridadReporte(reporte.id, true);
                
                // Recargar el reporte
                final reporteProvider = Provider.of<Reporteprovider>(context, listen: false);
                await reporteProvider.cargarReporte(reporte.id);
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('¡Gracias por tu voto!'),
                    backgroundColor: EcoPalette.success.color,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _FiltrosDialog extends StatefulWidget {
  final void Function(String?, String?, DateTimeRange?, double?, bool?) onFiltro;
  const _FiltrosDialog({required this.onFiltro});

  @override
  State<_FiltrosDialog> createState() => _FiltrosDialogState();
}

class _FiltrosDialogState extends State<_FiltrosDialog> {
  String? tipo;
  String? estado;
  DateTimeRange? fecha;
  double? calificacionMinima;
  bool? soloReportesPrioritarios;

  // Lista de tipos de reportes para el desplegable
  final List<TipoReporte> _tiposReporte = TipoReporte.values;
  TipoReporte? _selectedTipo;
  
  // Lista de estados para el desplegable
  final List<EstadoReporte> _estadosReporte = EstadoReporte.values;
  EstadoReporte? _selectedEstado;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: EcoPalette.white.color,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: EcoPalette.greenPrimary.color),
                SizedBox(width: 8),
                Text(
                  'Filtrar reportes', 
                  style: TextStyle(
                    color: EcoPalette.greenDark.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Desplegable para tipo de reporte
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: EcoPalette.greenLight.color),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.category, color: EcoPalette.greenPrimary.color),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TipoReporte>(
                          hint: Text(
                            'Seleccionar tipo',
                            style: TextStyle(color: EcoPalette.gray.color),
                          ),
                          value: _selectedTipo,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: EcoPalette.greenPrimary.color),
                          items: [
                            DropdownMenuItem<TipoReporte>(
                              value: null,
                              child: Text('Todos los tipos'),
                            ),
                            ..._tiposReporte.map((TipoReporte value) {
                              return DropdownMenuItem<TipoReporte>(
                                value: value,
                                child: Text(tipoReporteToString(value)),
                              );
                            }).toList(),
                          ],
                          onChanged: (TipoReporte? newValue) {
                            setState(() {
                              _selectedTipo = newValue;
                              tipo = newValue != null ? tipoReporteToString(newValue) : null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Desplegable para estado de reporte
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: EcoPalette.greenLight.color),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: EcoPalette.greenPrimary.color),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<EstadoReporte>(
                          hint: Text(
                            'Seleccionar estado',
                            style: TextStyle(color: EcoPalette.gray.color),
                          ),
                          value: _selectedEstado,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: EcoPalette.greenPrimary.color),
                          items: [
                            DropdownMenuItem<EstadoReporte>(
                              value: null,
                              child: Text('Todos los estados'),
                            ),
                            ..._estadosReporte.map((EstadoReporte value) {
                              return DropdownMenuItem<EstadoReporte>(
                                value: value,
                                child: Text(estadoReporteToString(value)),
                              );
                            }).toList(),
                          ],
                          onChanged: (EstadoReporte? newValue) {
                            setState(() {
                              _selectedEstado = newValue;
                              estado = newValue != null ? estadoReporteToString(newValue) : null;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Desplegable para calificación mínima
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: EcoPalette.greenLight.color),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.star, color: EcoPalette.amber.color),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          hint: Text(
                            'Calificación mínima',
                            style: TextStyle(color: EcoPalette.gray.color),
                          ),
                          value: calificacionMinima,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: EcoPalette.greenPrimary.color),
                          items: [
                            DropdownMenuItem<double>(
                              value: null,
                              child: Text('Cualquier calificación'),
                            ),
                            DropdownMenuItem<double>(
                              value: 1.0,
                              child: Row(
                                children: [
                                  Text('1.0+ '),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                ],
                              ),
                            ),
                            DropdownMenuItem<double>(
                              value: 2.0,
                              child: Row(
                                children: [
                                  Text('2.0+ '),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                ],
                              ),
                            ),
                            DropdownMenuItem<double>(
                              value: 3.0,
                              child: Row(
                                children: [
                                  Text('3.0+ '),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                ],
                              ),
                            ),
                            DropdownMenuItem<double>(
                              value: 4.0,
                              child: Row(
                                children: [
                                  Text('4.0+ '),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                ],
                              ),
                            ),
                            DropdownMenuItem<double>(
                              value: 4.5,
                              child: Row(
                                children: [
                                  Text('4.5+ '),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                  Icon(Icons.star, color: EcoPalette.amber.color, size: 16),
                                  Icon(Icons.star_half, color: EcoPalette.amber.color, size: 16),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (double? newValue) {
                            setState(() {
                              calificacionMinima = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Checkbox para reportes prioritarios
            CheckboxListTile(
              title: Row(
                children: [
                  Icon(Icons.priority_high, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Solo reportes prioritarios'),
                ],
              ),
              value: soloReportesPrioritarios ?? false,
              activeColor: EcoPalette.greenPrimary.color,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (bool? value) {
                setState(() {
                  soloReportesPrioritarios = value;
                });
              },
            ),
            
            SizedBox(height: 16),
            
            // Selector de rango de fechas
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.date_range, color: EcoPalette.greenPrimary.color),
              title: Text(
                fecha != null 
                    ? 'Del ${fecha!.start.day}/${fecha!.start.month}/${fecha!.start.year} al ${fecha!.end.day}/${fecha!.end.month}/${fecha!.end.year}'
                    : 'Seleccionar rango de fechas',
                style: TextStyle(
                  color: fecha != null ? EcoPalette.black.color : EcoPalette.gray.color,
                ),
              ),
              onTap: () async {
                final DateTimeRange? result = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: fecha ?? DateTimeRange(
                    start: DateTime.now().subtract(Duration(days: 30)),
                    end: DateTime.now(),
                  ),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: EcoPalette.greenPrimary.color,
                          onPrimary: EcoPalette.white.color,
                          onSurface: EcoPalette.black.color,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                
                if (result != null) {
                  setState(() {
                    fecha = result;
                  });
                }
              },
              trailing: fecha != null ? IconButton(
                icon: Icon(Icons.clear, color: EcoPalette.error.color),
                onPressed: () {
                  setState(() {
                    fecha = null;
                  });
                },
              ) : null,
            ),
            
            SizedBox(height: 24),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón para limpiar filtros
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: EcoPalette.greenPrimary.color),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text('Limpiar filtros'),
                  onPressed: () {
                    setState(() {
                      _selectedTipo = null;
                      _selectedEstado = null;
                      tipo = null;
                      estado = null;
                      fecha = null;
                      calificacionMinima = null;
                      soloReportesPrioritarios = null;
                    });
                  },
                ),
                
                // Botón para aplicar filtros
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EcoPalette.greenPrimary.color,
                    foregroundColor: EcoPalette.white.color,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text('Aplicar filtros'),
                  onPressed: () {
                    widget.onFiltro(tipo, estado, fecha, calificacionMinima, soloReportesPrioritarios);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 