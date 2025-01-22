import 'package:flutter/material.dart';
import 'package:geoappbeta/Pages/betaConfig.dart';
import 'package:geoappbeta/Pages/betaHome.dart';
import 'package:geoappbeta/Pages/betaSubirReporte.dart';
import 'package:geoappbeta/mocha.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> {
  int _selectedIndex = 0;

  void _itemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    var BarraNavegacion = BottomNavigationBar(
        showSelectedLabels: true,
        unselectedItemColor: Mocha.surface2.color,
        selectedItemColor: Mocha.overlay2.color,
        backgroundColor: Mocha.base.color,
        type: BottomNavigationBarType.fixed,
        iconSize: (screenWidth + screenHeight) * 0.027,
        selectedFontSize: (screenWidth + screenHeight) * 0.012,
        unselectedFontSize: (screenWidth + screenHeight) * 0.01,
        currentIndex: _selectedIndex,
        onTap: _itemTap,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.camera), label: "Subir reporte"),
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Ver reportes"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Mi cuenta")
        ]);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (dipop, result) async {
        if (dipop) {
          //await context.read<SessionProvider>().SalirSession();
        }
      },
      child: Scaffold(
        body: DecoratedBox(
            decoration: BoxDecoration(color: Mocha.base.color),
            child: _Screens(_selectedIndex)),
        bottomNavigationBar: BarraNavegacion,
      ),
    );
  }

  Widget _Screens(int index) {
    switch (index) {
      case 0:
        return SubirReporte();
      case 1:
        return Home();
      case 2:
        return UsuarioConfig();
      default:
        return Home();
    }
  }
}
