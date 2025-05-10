import 'package:flutter/material.dart';
import 'package:geoapptest/Pages/beta_config.dart';
import 'package:geoapptest/Pages/beta_home.dart';
import 'package:geoapptest/Pages/beta_subir_reporte.dart';
import 'package:geoapptest/mocha.dart';
import 'package:geoapptest/Pages/todos_reportes.dart';
import 'package:geoapptest/Pages/mi_perfil.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

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

    BottomNavigationBar barraNavegacion = BottomNavigationBar(
        showSelectedLabels: true,
        unselectedItemColor: EcoPalette.gray.color,
        selectedItemColor: EcoPalette.greenPrimary.color,
        backgroundColor: EcoPalette.white.color,
        type: BottomNavigationBarType.fixed,
        iconSize: (screenWidth + screenHeight) * 0.027,
        selectedFontSize: (screenWidth + screenHeight) * 0.012,
        unselectedFontSize: (screenWidth + screenHeight) * 0.01,
        currentIndex: _selectedIndex,
        onTap: _itemTap,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: "Reportes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.map), label: "Mapa"),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: "Nuevo"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Perfil"),
        ]);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (dipop, result) async {
        if (dipop) {
          //await context.read<SessionProvider>().SalirSession();
        }
      },
      child: Scaffold(
        body: PageView(
            physics: ClampingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            controller: _pageController,
            children: [TodosReportesPage(), Home(), SubirReporte(), MiPerfilPage()]),
        bottomNavigationBar: barraNavegacion,
      ),
    );
  }
}
