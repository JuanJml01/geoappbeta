import 'package:flutter/material.dart';
import 'package:geoappbeta/Pages/beta_config.dart';
import 'package:geoappbeta/Pages/beta_home.dart';
import 'package:geoappbeta/Pages/beta_subir_reporte.dart';
import 'package:geoappbeta/Pages/reportes_seguimiento.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:geoappbeta/Pages/todos_reportes.dart';
import 'package:geoappbeta/Pages/mi_perfil.dart';
import 'package:provider/provider.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  int _selectedIndex = 1;
  final PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionProvider = context.read<SessionProvider>();
      if (sessionProvider.user == null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _itemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(index,
        duration: Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          const TodosReportesPage(),
          const Home(),
          const SubirReporte(),
          const ReportesSeguimientoPage(),
          const MiPerfilPage(),
          const UsuarioConfig(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: EcoPalette.black.color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _itemTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: EcoPalette.white.color,
            selectedItemColor: EcoPalette.greenPrimary.color,
            unselectedItemColor: EcoPalette.gray.color,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Reportes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle),
                label: 'Reportar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark),
                label: 'Seguimiento',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Perfil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Ajustes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
