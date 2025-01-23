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
        unselectedItemColor: Mocha.surface2.color,
        selectedItemColor: Mocha.overlay2.color,
        backgroundColor: Mocha.surface0.color,
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
        body: PageView(
            physics: ClampingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            controller: _pageController,
            children: [SubirReporte(), Home(), UsuarioConfig()]),
        bottomNavigationBar: barraNavegacion,
      ),
    );
  }
}
