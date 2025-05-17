import 'package:flutter/material.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:geoappbeta/Provider/usuarioProvider.dart';
import 'package:geoappbeta/Model/usuarioModel.dart';
import 'package:geoappbeta/Service/error_service.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Model/reporteModel.dart';
import 'package:geoappbeta/Pages/beta_detalles_reporte.dart';

class MiPerfilPage extends StatefulWidget {
  const MiPerfilPage({super.key});

  @override
  State<MiPerfilPage> createState() => _MiPerfilPageState();
}

class _MiPerfilPageState extends State<MiPerfilPage> {
  bool _isLoading = true;
  int _reportesCount = 0;
  
  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }
  
  Future<void> _cargarDatosUsuario() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      final reporteProvider = Provider.of<Reporteprovider>(context, listen: false);
      
      // Inicializar el usuario si es necesario
      if (usuarioProvider.usuarioActual == null) {
        await usuarioProvider.inicializar();
      }
      
      // Cargar reportes del usuario
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      final user = sessionProvider.user;
      
      if (user != null && user.email != null) {
        // Cargar reportes del usuario por email
        await reporteProvider.fetchReporteForEmail(nombre: user.email!);
        _reportesCount = reporteProvider.reportes.length;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorService.mostrarSnackBarError(
          context, 
          ErrorService.obtenerMensajeError(e)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Consumer2<SessionProvider, UsuarioProvider>(
      builder: (context, sessionProvider, usuarioProvider, _) {
        final authUser = sessionProvider.user;
        final Usuario? usuario = usuarioProvider.usuarioActual;
        
        // Datos del usuario autenticado
        final String userEmail = authUser?.email ?? 'Anónimo';
        final String userName = usuario?.nombre ?? userEmail.split('@').first;
        final bool isAnonymous = authUser == null || authUser.email == null || authUser.email!.isEmpty;
        
        // Estadísticas
        final int reportesCount = _reportesCount; // Usar el contador real de reportes
        final int zonasCount = usuario?.zonasInteres.length ?? 0;
        final int logrosCount = usuario?.logrosObtenidos ?? 0;
        final int reportesSeguimientoCount = usuario?.reportesEnSeguimiento ?? 0;
        
        if (_isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: EcoPalette.greenPrimary.color,
            ),
          );
        }
        
        return Scaffold(
          backgroundColor: EcoPalette.sand.color,
          body: RefreshIndicator(
            onRefresh: _cargarDatosUsuario,
            color: EcoPalette.greenPrimary.color,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(top: screenHeight * 0.07, bottom: screenHeight * 0.03),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          EcoPalette.greenPrimary.color,
                          EcoPalette.greenDark.color,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: EcoPalette.black.color.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: EcoPalette.white.color,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: EcoPalette.black.color.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: screenWidth * 0.13,
                            backgroundColor: EcoPalette.white.color,
                            child: usuario?.foto == null 
                                ? Icon(
                                    isAnonymous ? Icons.person_outline : Icons.person, 
                                    size: screenWidth * 0.13, 
                                    color: EcoPalette.greenPrimary.color
                                  )
                                : ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: usuario!.foto!,
                                      width: screenWidth * 0.26,
                                      height: screenWidth * 0.26,
                                      fit: BoxFit.cover,
                                      memCacheWidth: (screenWidth * 0.26 * MediaQuery.of(context).devicePixelRatio).round(),
                                      memCacheHeight: (screenWidth * 0.26 * MediaQuery.of(context).devicePixelRatio).round(),
                                      placeholder: (context, url) => CircularProgressIndicator(
                                        color: EcoPalette.greenPrimary.color,
                                        strokeWidth: 2,
                                      ),
                                      errorWidget: (context, url, error) => Icon(
                                        Icons.error_outline,
                                        color: EcoPalette.error.color,
                                        size: screenWidth * 0.08,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userName,
                          style: TextStyle(
                            color: EcoPalette.white.color,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.06,
                            shadows: [
                              Shadow(
                                color: EcoPalette.black.color.withOpacity(0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        if (!isAnonymous) 
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: EcoPalette.white.color.withOpacity(0.9),
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (usuario != null && !usuario.esAnonimo)
                          Text(
                            'Nivel ${usuario.nivel} • ${usuario.puntos} puntos',
                            style: TextStyle(
                              color: EcoPalette.white.color.withOpacity(0.9),
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isAnonymous)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EcoPalette.white.color,
                                  foregroundColor: EcoPalette.greenPrimary.color,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  // Implementar edición de perfil
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'Editar perfil',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: EcoPalette.white.color,
                                side: BorderSide(color: EcoPalette.white.color),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await sessionProvider.salirSession();
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/',
                                    (route) => false,
                                  );
                                } catch (e) {
                                  ErrorService.mostrarError(
                                    context: context,
                                    titulo: 'Error al cerrar sesión',
                                    mensaje: ErrorService.obtenerMensajeError(e),
                                  );
                                }
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.logout, size: 18),
                                  SizedBox(width: 4),
                                  Text('Cerrar sesión'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatCard(title: 'Reportes', value: reportesCount.toString(), icon: Icons.assignment, color: EcoPalette.greenPrimary.color),
                        _StatCard(title: 'Seguimiento', value: reportesSeguimientoCount.toString(), icon: Icons.bookmark, color: EcoPalette.accent.color),
                        _StatCard(title: 'Logros', value: logrosCount.toString(), icon: Icons.emoji_events, color: EcoPalette.greenDark.color),
                      ],
                    ),
                  ),
                  if (usuario != null && !usuario.esAnonimo)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EcoPalette.white.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: EcoPalette.black.color.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nivel de impacto', 
                            style: TextStyle(
                              color: EcoPalette.greenDark.color, 
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: usuario.puntos / (100 * usuario.nivel), // Progreso basado en puntos
                              backgroundColor: EcoPalette.grayLight.color,
                              color: EcoPalette.greenPrimary.color,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${usuario.puntos} / ${100 * usuario.nivel} puntos para nivel ${usuario.nivel + 1}',
                            style: TextStyle(
                              color: EcoPalette.gray.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: EcoPalette.white.color,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: EcoPalette.black.color.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TabBar(
                            labelColor: EcoPalette.white.color,
                            unselectedLabelColor: EcoPalette.gray.color,
                            indicator: BoxDecoration(
                              color: EcoPalette.greenPrimary.color,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Reportes'),
                              Tab(text: 'Logros'),
                              Tab(text: 'Cuenta'),
                            ],
                          ),
                        ),
                        Container(
                          height: screenHeight * 0.4,
                          margin: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            color: EcoPalette.white.color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: EcoPalette.black.color.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TabBarView(
                            children: [
                              _TabReportes(),
                              _TabLogros(logros: usuario?.logros ?? []),
                              _TabCuenta(usuario: usuario, email: userEmail),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EcoPalette.white.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: EcoPalette.black.color.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
          Text(title, style: TextStyle(color: EcoPalette.gray.color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _TabReportes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Obtener reportes del provider
    final reportes = Provider.of<Reporteprovider>(context).reportes;
    
    if (reportes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: EcoPalette.greenLight.color),
            const SizedBox(height: 16),
            Text(
              'No has creado reportes aún', 
              style: TextStyle(
                color: EcoPalette.greenDark.color,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              )
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a la página de crear reporte
                Navigator.pushNamed(context, '/subiendo');
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear reporte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EcoPalette.greenPrimary.color,
                foregroundColor: EcoPalette.white.color,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: reportes.length,
      itemBuilder: (context, index) {
        final reporte = reportes[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(reporte.imagen),
          ),
          title: Text(reporte.tipoTags.map((t) => t.nombre).join(', ')),
          subtitle: Text(
            reporte.descripcion.isNotEmpty 
                ? reporte.descripcion.substring(0, reporte.descripcion.length > 50 ? 50 : reporte.descripcion.length) + (reporte.descripcion.length > 50 ? '...' : '')
                : 'Sin descripción'
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: reporte.estado == EstadoReporte.pendiente
                  ? Colors.orange
                  : reporte.estado == EstadoReporte.enProceso
                      ? Colors.blue
                      : reporte.estado == EstadoReporte.cancelado
                          ? Colors.red
                          : Colors.green,
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetallesReportePage(reporte: reporte),
              ),
            );
          },
        );
      },
    );
  }
}

class _TabLogros extends StatelessWidget {
  final List<Logro> logros;
  
  const _TabLogros({required this.logros});
  
  @override
  Widget build(BuildContext context) {
    if (logros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 48, color: EcoPalette.accent.color.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes logros', 
              style: TextStyle(
                color: EcoPalette.greenDark.color,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              )
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: logros.length,
      itemBuilder: (context, index) {
        final logro = logros[index];
        return _LogroCard(
          title: logro.nombre,
          description: logro.descripcion,
          icon: logro.iconoWidget,
          color: logro.categoriaColor,
          obtenido: logro.obtenido,
          puntos: logro.puntos,
        );
      },
    );
  }
}

class _LogroCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool obtenido;
  final int puntos;
  
  const _LogroCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.obtenido,
    required this.puntos,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(obtenido ? 0.2 : 0.1),
              child: Icon(icon, color: obtenido ? color : color.withOpacity(0.5)),
            ),
            if (obtenido)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: EcoPalette.greenPrimary.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: EcoPalette.white.color, size: 10),
                ),
              ),
          ],
        ),
        title: Text(
          title, 
          style: TextStyle(
            color: obtenido ? color : EcoPalette.gray.color, 
            fontWeight: FontWeight.bold
          )
        ),
        subtitle: Text(description),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: obtenido ? color.withOpacity(0.2) : EcoPalette.grayLight.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+$puntos pts',
            style: TextStyle(
              color: obtenido ? color : EcoPalette.gray.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabCuenta extends StatelessWidget {
  final Usuario? usuario;
  final String email;
  
  const _TabCuenta({required this.usuario, required this.email});
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _CuentaCard(
          title: 'Correo electrónico',
          subtitle: email,
          icon: Icons.email,
          color: EcoPalette.info.color,
        ),
        const SizedBox(height: 12),
        if (usuario != null && !usuario!.esAnonimo) ...[
          _CuentaCard(
            title: 'Ciudad',
            subtitle: usuario?.ciudad ?? 'No especificada',
            icon: Icons.location_city,
            color: EcoPalette.greenDark.color,
          ),
          const SizedBox(height: 12),
          _CuentaCard(
            title: 'Biografía',
            subtitle: usuario?.bio ?? 'No hay biografía',
            icon: Icons.description,
            color: EcoPalette.accent.color,
          ),
          const SizedBox(height: 12),
          _CuentaCard(
            title: 'Fecha de registro',
            subtitle: '${usuario!.createdAt.day}/${usuario!.createdAt.month}/${usuario!.createdAt.year}',
            icon: Icons.calendar_today,
            color: EcoPalette.greenPrimary.color,
          ),
        ],
        const SizedBox(height: 12),
        _CuentaCard(
          title: 'Cerrar sesión',
          subtitle: 'Salir de la aplicación',
          icon: Icons.logout,
          color: EcoPalette.error.color,
          onTap: () async {
            try {
              await Provider.of<SessionProvider>(context, listen: false).salirSession();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            } catch (e) {
              ErrorService.mostrarError(
                context: context,
                titulo: 'Error al cerrar sesión',
                mensaje: ErrorService.obtenerMensajeError(e),
              );
            }
          },
        ),
      ],
    );
  }
}

class _CuentaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  
  const _CuentaCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
} 