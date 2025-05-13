import 'package:flutter/material.dart';
import 'package:geoapptest/Provider/userProvider.dart';
import 'package:geoapptest/mocha.dart';
import 'package:provider/provider.dart';

class MiPerfilPage extends StatelessWidget {
  const MiPerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, _) {
        final user = sessionProvider.user;
        final String userName = user?.email?.split('@').first ?? 'Usuario Anónimo';
        final bool isAnonymous = user == null || user.email == null || user.email!.isEmpty;
        
        return Scaffold(
          backgroundColor: EcoPalette.sand.color,
          body: SingleChildScrollView(
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
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: EcoPalette.black.color.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
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
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: screenWidth * 0.13,
                          backgroundColor: EcoPalette.white.color,
                          child: Icon(
                            isAnonymous ? Icons.person_outline : Icons.person, 
                            size: screenWidth * 0.13, 
                            color: EcoPalette.greenPrimary.color
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
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
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      if (!isAnonymous) 
                        Text(
                          user!.email!,
                          style: TextStyle(
                            color: EcoPalette.white.color.withOpacity(0.9),
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      SizedBox(height: 16),
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
                              onPressed: () {},
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Editar perfil',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: EcoPalette.white.color,
                              side: BorderSide(color: EcoPalette.white.color),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () async {
                              await sessionProvider.salirSession();
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/',
                                (route) => false,
                              );
                            },
                            child: Row(
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
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(title: 'Reportes', value: '47', icon: Icons.assignment, color: EcoPalette.greenPrimary.color),
                      _StatCard(title: 'Zonas', value: '12', icon: Icons.place, color: EcoPalette.greenDark.color),
                      _StatCard(title: 'Logros', value: '8', icon: Icons.emoji_events, color: EcoPalette.accent.color),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                      Text(
                        'Nivel de impacto', 
                        style: TextStyle(
                          color: EcoPalette.greenDark.color, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )
                      ),
                      SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.7,
                          backgroundColor: EcoPalette.grayLight.color,
                          color: EcoPalette.greenPrimary.color,
                          minHeight: 8,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Próximo logro', 
                        style: TextStyle(
                          color: EcoPalette.brown.color,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        )
                      ),
                      SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.75,
                          backgroundColor: EcoPalette.grayLight.color,
                          color: EcoPalette.accent.color,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: EcoPalette.white.color,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: EcoPalette.black.color.withOpacity(0.05),
                              blurRadius: 5,
                              offset: Offset(0, 2),
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
                          tabs: [
                            Tab(text: 'Reportes'),
                            Tab(text: 'Logros'),
                            Tab(text: 'Cuenta'),
                          ],
                        ),
                      ),
                      Container(
                        height: screenHeight * 0.4,
                        margin: EdgeInsets.only(top: 16),
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
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TabBarView(
                          children: [
                            _TabReportes(),
                            _TabLogros(),
                            _TabCuenta(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      padding: EdgeInsets.all(12),
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
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 4),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: EcoPalette.greenLight.color),
          SizedBox(height: 16),
          Text(
            'Tus reportes aparecerán aquí', 
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
}

class _TabLogros extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _LogroCard(
          title: 'Primer reporte',
          description: '¡Felicidades por tu primer reporte!',
          icon: Icons.emoji_events,
          color: EcoPalette.accent.color,
        ),
        SizedBox(height: 12),
        _LogroCard(
          title: 'Impacto ecológico',
          description: 'Has generado impacto positivo en tu comunidad.',
          icon: Icons.eco,
          color: EcoPalette.greenDark.color,
        ),
      ],
    );
  }
}

class _LogroCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  
  const _LogroCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }
}

class _TabCuenta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _CuentaCard(
          title: 'Correo electrónico',
          subtitle: 'carlos@email.com',
          icon: Icons.email,
          color: EcoPalette.info.color,
        ),
        SizedBox(height: 12),
        _CuentaCard(
          title: 'Cerrar sesión',
          subtitle: 'Salir de la aplicación',
          icon: Icons.logout,
          color: EcoPalette.error.color,
          onTap: () {},
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
} 