import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TodosReportesPage extends StatefulWidget {
  const TodosReportesPage({super.key});

  @override
  State<TodosReportesPage> createState() => _TodosReportesPageState();
}

class _TodosReportesPageState extends State<TodosReportesPage> {
  String? filtroTipo;
  String? filtroEstado;
  DateTimeRange? filtroFecha;
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
                  onFiltro: (tipo, estado, fecha) {
                    setState(() {
                      filtroTipo = tipo;
                      filtroEstado = estado;
                      filtroFecha = fecha;
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
                      child: ListTile(
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
                        title: Text(
                          tipoReporteToString(reporte.tipo),
                          style: TextStyle(
                            color: EcoPalette.greenDark.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                      SizedBox(width: 4),
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
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                      SizedBox(width: 4),
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
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: EcoPalette.greenPrimary.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_forward_ios, 
                              color: EcoPalette.greenPrimary.color,
                              size: 16,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/verReporte', arguments: reporte);
                            },
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/verReporte', arguments: reporte);
                        },
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
      default:
        return EcoPalette.info.color;
    }
  }
}

class _FiltrosDialog extends StatefulWidget {
  final void Function(String?, String?, DateTimeRange?) onFiltro;
  const _FiltrosDialog({required this.onFiltro});

  @override
  State<_FiltrosDialog> createState() => _FiltrosDialogState();
}

class _FiltrosDialogState extends State<_FiltrosDialog> {
  String? tipo;
  String? estado;
  DateTimeRange? fecha;

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
            
            // Selector de rango de fechas
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: EcoPalette.greenLight.color,
                foregroundColor: EcoPalette.greenDark.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                minimumSize: Size(double.infinity, 50),
              ),
              icon: Icon(Icons.date_range),
              label: Text(
                fecha == null ? 'Seleccionar rango de fechas' :
                '${fecha!.start.day}/${fecha!.start.month}/${fecha!.start.year} - ${fecha!.end.day}/${fecha!.end.month}/${fecha!.end.year}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(Duration(days: 1)),
                  initialDateRange: fecha,
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: EcoPalette.greenPrimary.color,
                        onPrimary: EcoPalette.white.color,
                        surface: EcoPalette.white.color,
                        onSurface: EcoPalette.black.color,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => fecha = picked);
              },
            ),
            
            SizedBox(height: 24),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.clear),
                  label: Text('Limpiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: EcoPalette.error.color,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedTipo = null;
                      _selectedEstado = null;
                      tipo = null;
                      estado = null;
                      fecha = null;
                    });
                    widget.onFiltro(null, null, null);
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.check),
                  label: Text('Aplicar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EcoPalette.greenPrimary.color,
                    foregroundColor: EcoPalette.white.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    widget.onFiltro(tipo, estado, fecha);
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