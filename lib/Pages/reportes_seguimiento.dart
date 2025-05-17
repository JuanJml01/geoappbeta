// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/Model/usuarioModel.dart';
import 'package:geoappbeta/Pages/beta_detalles_reporte.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Provider/usuarioProvider.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReportesSeguimientoPage extends StatefulWidget {
  const ReportesSeguimientoPage({super.key});

  @override
  State<ReportesSeguimientoPage> createState() => _ReportesSeguimientoPageState();
}

class _ReportesSeguimientoPageState extends State<ReportesSeguimientoPage> {
  bool _isLoading = true;
  List<Reporte> _reportesSeguimiento = [];
  
  @override
  void initState() {
    super.initState();
    _cargarReportesSeguimiento();
  }
  
  Future<void> _cargarReportesSeguimiento() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final usuarioProvider = context.read<UsuarioProvider>();
      final reporteProvider = context.read<Reporteprovider>();
      
      // Asegurarse de que el usuario esté inicializado
      if (usuarioProvider.usuarioActual == null) {
        await usuarioProvider.inicializar();
      }
      
      // Cargar reportes en seguimiento
      await usuarioProvider.cargarReportesSeguimiento();
      
      // Obtener IDs de reportes en seguimiento
      final reportesIds = usuarioProvider.usuarioActual?.reportesSeguimiento
          .map((r) => r.reporteId)
          .toList() ?? [];
      
      // Filtrar reportes que están en seguimiento
      _reportesSeguimiento = reporteProvider.reportes
          .where((r) => reportesIds.contains(r.id))
          .toList();
      
      // Si algún reporte no está en la lista principal, cargarlo individualmente
      for (final seguimiento in usuarioProvider.usuarioActual?.reportesSeguimiento ?? []) {
        if (!_reportesSeguimiento.any((r) => r.id == seguimiento.reporteId)) {
          try {
            final reporte = await reporteProvider.cargarReporte(seguimiento.reporteId);
            if (reporte != null) {
              _reportesSeguimiento.add(reporte);
            }
          } catch (e) {
            // Ignorar errores individuales
          }
        }
      }
    } catch (e) {
      // Manejar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar reportes en seguimiento: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _quitarDeSeguimiento(int reporteId) async {
    try {
      final usuarioProvider = context.read<UsuarioProvider>();
      final resultado = await usuarioProvider.eliminarReporteSeguimiento(reporteId);
      
      if (resultado) {
        setState(() {
          _reportesSeguimiento.removeWhere((r) => r.id == reporteId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte eliminado de seguimiento'),
            backgroundColor: Colors.green,
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
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes en Seguimiento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReportesSeguimiento,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _reportesSeguimiento.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: EcoPalette.gray.color,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes reportes en seguimiento',
                        style: TextStyle(
                          fontSize: 18,
                          color: EcoPalette.black.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega reportes a seguimiento para verlos aquí',
                        style: TextStyle(
                          color: EcoPalette.gray.color,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/todos_reportes');
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Ver todos los reportes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EcoPalette.greenPrimary.color,
                          foregroundColor: EcoPalette.white.color,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reportesSeguimiento.length,
                  itemBuilder: (context, index) {
                    final reporte = _reportesSeguimiento[index];
                    return _buildReporteCard(reporte);
                  },
                ),
    );
  }
  
  Widget _buildReporteCard(Reporte reporte) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del reporte
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: reporte.imagen,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
                // Etiquetas superpuestas
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          reporte.tipoTags.isNotEmpty
                              ? reporte.tipoTags.first.icono
                              : Icons.help_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reporte.tipoTags.isNotEmpty
                              ? reporte.tipoTags.first.nombre
                              : 'Desconocido',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Indicador de prioridad
                if (reporte.prioridadComunidad)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.priority_high, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'PRIORITARIO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Contenido del reporte
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y calificación
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        reporte.tipoTags.map((t) => t.nombre).join(', '),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          reporte.calificacionPromedio.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Descripción
                Text(
                  reporte.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Estadísticas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fecha
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${reporte.createdAt.day}/${reporte.createdAt.month}/${reporte.createdAt.year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    // Vistas
                    Row(
                      children: [
                        Icon(Icons.remove_red_eye, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${reporte.vistas}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    // Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(estadoReporteToString(reporte.estado)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        estadoReporteToString(reporte.estado),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Botones de acción
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón para quitar de seguimiento
                TextButton.icon(
                  onPressed: () => _quitarDeSeguimiento(reporte.id),
                  icon: const Icon(Icons.bookmark_remove),
                  label: const Text('Quitar de seguimiento'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                
                // Botón para ver detalles
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetallesReportePage(reporte: reporte),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Ver detalles'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en proceso':
        return Colors.blue;
      case 'resuelto':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 