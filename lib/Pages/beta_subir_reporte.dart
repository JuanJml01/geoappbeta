// ignore_for_file:  use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:geoappbeta/Service/tomarFoto.dart';
import 'package:geoappbeta/mocha.dart';
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
      try {
        final sessionProvider = context.read<SessionProvider>();
        final user = sessionProvider.user;
        
        if (user != null && user.email != null && user.email!.isNotEmpty) {
          // Usuario con email
          String email = user.email!;
          await context.read<Reporteprovider>().fetchReporteForEmail(nombre: email);
          
          if (mounted) {
            setState(() {
              isInitialized = true;
              _tipoUser = TipoUser.email;
            });
          }
        } else {
          // Usuario anónimo o sin email
          context.read<Reporteprovider>().reportes.clear();
          
          if (mounted) {
            setState(() {
              isInitialized = true;
              _tipoUser = TipoUser.anonimo;
            });
          }
        }
      } catch (e) {
        // En caso de error, establecer como usuario anónimo
        context.read<Reporteprovider>().reportes.clear();
        
        if (mounted) {
          setState(() {
            isInitialized = true;
            _tipoUser = TipoUser.anonimo;
          });
        }
        
        debugPrint('Error al inicializar datos: $e');
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
    // Obtener el primer tag de tipo (para compatibilidad)
    final tipoTag = reporte.tipoTags.isNotEmpty 
        ? reporte.tipoTags.first 
        : getTipoReporteTagById('otro');
        
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tipoTag.icono,
                              size: 12,
                              color: EcoPalette.greenDark.color,
                            ),
                            SizedBox(width: 4),
                            Text(
                              tipoTag.nombre,
                              style: TextStyle(
                                color: EcoPalette.greenDark.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
  
  // Lista para almacenar los tags seleccionados
  final List<String> _selectedTipoTags = ['otro']; // Por defecto 'otro'
  final List<String> _selectedUbicacionTags = ['otro']; // Por defecto 'otro'

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
          // Resetear selecciones previas
          _selectedTipoTags.clear();
          _selectedTipoTags.add('otro');
          _selectedUbicacionTags.clear();
          _selectedUbicacionTags.add('otro');
          
          // Mostrar el diálogo de detalles y esperar la respuesta
          final bool continuarProceso = await _pedirDetallesReporte(context);
          
          if (continuarProceso && _controllerText.text.isNotEmpty) {
            // Mostrar indicador de carga
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
            
            try {
              // Escanear la foto
              await provider.scanearFoto(foto: provider.foto!);
              
              // Navegar a la pantalla de carga y prevenir retorno
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/subiendo',
                (route) => false, // Esto impide volver atrás
                arguments: {
                  'descripcion': _controllerText.text,
                  'tipoTags': _selectedTipoTags,
                  'ubicacionTags': _selectedUbicacionTags,
                },
              );
            } catch (e) {
              // Mostrar error si falla el procesamiento
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al procesar la imagen: ${e.toString()}'),
                  backgroundColor: EcoPalette.error.color,
                  duration: Duration(seconds: 3),
                ),
              );
            }
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

  Future<bool> _pedirDetallesReporte(BuildContext context) async {
    bool continuarProceso = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false, // Evitar cerrar el diálogo tocando fuera
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevenir cierre con botón atrás
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Dialog(
                backgroundColor: EcoPalette.white.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: screenWidth * 0.9,
                  constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
                  child: SingleChildScrollView(
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
                          
                          // Selección de Tipo de Problema (tags múltiples)
                          Text(
                            'Tipo de problema',
                            style: TextStyle(
                              color: EcoPalette.greenDark.color,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: EcoPalette.greenLight.color),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tiposReporteTags.map((tag) {
                                final isSelected = _selectedTipoTags.contains(tag.id);
                                return FilterChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        tag.icono,
                                        size: 16,
                                        color: isSelected 
                                            ? EcoPalette.white.color 
                                            : EcoPalette.greenDark.color,
                                      ),
                                      SizedBox(width: 4),
                                      Text(tag.nombre),
                                    ],
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setStateDialog(() {
                                      if (selected) {
                                        // Si se selecciona 'Otro', deseleccionar los demás
                                        if (tag.id == 'otro') {
                                          _selectedTipoTags.clear();
                                          _selectedTipoTags.add('otro');
                                        } else {
                                          // Si se selecciona otro tag, remover 'Otro'
                                          _selectedTipoTags.remove('otro');
                                          _selectedTipoTags.add(tag.id);
                                        }
                                      } else {
                                        // No permitir deseleccionar todos los tags
                                        if (_selectedTipoTags.length > 1) {
                                          _selectedTipoTags.remove(tag.id);
                                        }
                                        
                                        // Si no hay selecciones, añadir 'Otro'
                                        if (_selectedTipoTags.isEmpty) {
                                          _selectedTipoTags.add('otro');
                                        }
                                      }
                                    });
                                  },
                                  backgroundColor: EcoPalette.white.color,
                                  selectedColor: EcoPalette.greenPrimary.color,
                                  checkmarkColor: EcoPalette.white.color,
                                  labelStyle: TextStyle(
                                    color: isSelected 
                                        ? EcoPalette.white.color 
                                        : EcoPalette.greenDark.color,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Selección de Ubicación (tags múltiples)
                          Text(
                            'Tipo de ubicación',
                            style: TextStyle(
                              color: EcoPalette.greenDark.color,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: EcoPalette.greenLight.color),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ubicacionTags.map((tag) {
                                final isSelected = _selectedUbicacionTags.contains(tag.id);
                                return FilterChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        tag.icono,
                                        size: 16,
                                        color: isSelected 
                                            ? EcoPalette.white.color 
                                            : EcoPalette.greenDark.color,
                                      ),
                                      SizedBox(width: 4),
                                      Text(tag.nombre),
                                    ],
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setStateDialog(() {
                                      if (selected) {
                                        // Si se selecciona 'Otro', deseleccionar los demás
                                        if (tag.id == 'otro') {
                                          _selectedUbicacionTags.clear();
                                          _selectedUbicacionTags.add('otro');
                                        } else {
                                          // Si se selecciona otro tag, remover 'Otro'
                                          _selectedUbicacionTags.remove('otro');
                                          _selectedUbicacionTags.add(tag.id);
                                        }
                                      } else {
                                        // No permitir deseleccionar todos los tags
                                        if (_selectedUbicacionTags.length > 1) {
                                          _selectedUbicacionTags.remove(tag.id);
                                        }
                                        
                                        // Si no hay selecciones, añadir 'Otro'
                                        if (_selectedUbicacionTags.isEmpty) {
                                          _selectedUbicacionTags.add('otro');
                                        }
                                      }
                                    });
                                  },
                                  backgroundColor: EcoPalette.white.color,
                                  selectedColor: EcoPalette.greenPrimary.color,
                                  checkmarkColor: EcoPalette.white.color,
                                  labelStyle: TextStyle(
                                    color: isSelected 
                                        ? EcoPalette.white.color 
                                        : EcoPalette.greenDark.color,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Descripción
                          Text(
                            'Descripción del reporte',
                            style: TextStyle(
                              color: EcoPalette.greenDark.color,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _controllerText,
                            cursorColor: EcoPalette.greenPrimary.color,
                            maxLines: 4,
                            decoration: InputDecoration(
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
                          
                          // Resumen de selecciones
                          if (_selectedTipoTags.isNotEmpty || _selectedUbicacionTags.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: EcoPalette.greenLight.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resumen:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: EcoPalette.greenDark.color,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  if (_selectedTipoTags.isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: _selectedTipoTags.map((id) {
                                        final tag = getTipoReporteTagById(id);
                                        return Chip(
                                          label: Text(tag.nombre),
                                          avatar: Icon(tag.icono, size: 16),
                                          backgroundColor: EcoPalette.greenPrimary.color.withOpacity(0.1),
                                          labelStyle: TextStyle(color: EcoPalette.greenDark.color, fontSize: 12),
                                        );
                                      }).toList(),
                                    ),
                                  if (_selectedUbicacionTags.isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: _selectedUbicacionTags.map((id) {
                                        final tag = getUbicacionTagById(id);
                                        return Chip(
                                          label: Text(tag.nombre),
                                          avatar: Icon(tag.icono, size: 16),
                                          backgroundColor: EcoPalette.accent.color.withOpacity(0.1),
                                          labelStyle: TextStyle(color: EcoPalette.greenDark.color, fontSize: 12),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          
                          SizedBox(height: 24),
                          
                          // Botones
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  continuarProceso = false;
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
                                    continuarProceso = true;
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
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    
    return continuarProceso;
  }
}
