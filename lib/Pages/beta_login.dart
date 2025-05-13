// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geoapptest/Provider/userProvider.dart';
import 'package:geoapptest/Provider/usuarioProvider.dart';
import 'package:provider/provider.dart';
import 'package:geoapptest/mocha.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EcoPalette.greenPrimary.color,
              EcoPalette.greenDark.color,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.08),
                TituloApp(screenWidth: screenWidth, screenHeight: screenHeight),
                SizedBox(height: screenHeight * 0.04),
                Container(
                  width: screenWidth * 0.8,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EcoPalette.white.color.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: EcoPalette.black.color.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.eco,
                        size: screenWidth * 0.15,
                        color: EcoPalette.greenPrimary.color,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "Bienvenido a GeoApp",
                        style: TextStyle(
                          fontSize: (screenWidth + screenHeight) * 0.018,
                          fontWeight: FontWeight.bold,
                          color: EcoPalette.greenDark.color,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        "Inicia sesión para continuar",
                        style: TextStyle(
                          fontSize: (screenWidth + screenHeight) * 0.012,
                          color: EcoPalette.gray.color,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      BotonLoginGoogle(screenWidth: screenWidth, screenHeight: screenHeight),
                      SizedBox(height: screenHeight * 0.02),
                      BotonLoginAno(screenWidth: screenWidth, screenHeight: screenHeight),
                    ],
                  ),
                ),
                Spacer(),
                TextoInferior(screenWidth: screenWidth, screenHeight: screenHeight),
                SizedBox(height: screenHeight * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TextoInferior extends StatelessWidget {
  const TextoInferior({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenWidth * 0.8,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: EcoPalette.white.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "lorem ipsum dolor sit ames, connecter advising el super nill tempore inv sociol ad minim venial",
        style: TextStyle(
          fontSize: (screenWidth + screenHeight) * 0.01,
          color: EcoPalette.white.color,
          shadows: [
            Shadow(
              color: EcoPalette.black.color.withOpacity(0.3),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class BotonLoginAno extends StatelessWidget {
  const BotonLoginAno({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: EcoPalette.white.color,
            foregroundColor: EcoPalette.greenPrimary.color,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            minimumSize: Size(screenWidth * 0.62, screenHeight * 0.055)),
        onPressed: () async {
          try {
            // Mostrar indicador de carga
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: CircularProgressIndicator(
                  color: EcoPalette.white.color,
                ),
              ),
            );
            
            await context.read<SessionProvider>().iniciarAnonimo();
            if (context.read<SessionProvider>().user == null) {
              throw Exception("Error al iniciar sesion anonima");
            } else {
              // Inicializar el perfil de usuario
              final usuarioProvider = context.read<UsuarioProvider>();
              await usuarioProvider.inicializar();
              
              // Cerrar el diálogo de carga
              Navigator.pop(context);
              
              // Navegar a la pantalla principal
              Navigator.pushNamedAndRemoveUntil(
                context, 
                "/home", 
                (route) => false
              );
            }
          } catch (e) {
            // Cerrar el diálogo de carga si está visible
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error al iniciar sesión anónima: ${e.toString()}"),
                backgroundColor: EcoPalette.error.color,
              ),
            );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline),
            SizedBox(width: 8),
            Text(
              "Iniciar como anónimo",
              style: TextStyle(
                fontSize: (screenWidth + screenHeight) * 0.014,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ));
  }
}

class BotonLoginGoogle extends StatelessWidget {
  const BotonLoginGoogle({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: EcoPalette.white.color,
            foregroundColor: Colors.black87,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            minimumSize: Size(screenWidth * 0.62, screenHeight * 0.055)),
        onPressed: () async {
          try {
            // Mostrar indicador de carga
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: CircularProgressIndicator(
                  color: EcoPalette.white.color,
                ),
              ),
            );
            
            await context.read<SessionProvider>().iniciarGoogle();
            if (context.read<SessionProvider>().user == null) {
              throw Exception("Error al iniciar sesión con Google");
            } else {
              // Inicializar el perfil de usuario
              final usuarioProvider = context.read<UsuarioProvider>();
              await usuarioProvider.inicializar();
              
              // Cerrar el diálogo de carga
              Navigator.pop(context);
              
              // Navegar a la pantalla principal
              Navigator.pushNamedAndRemoveUntil(
                context, 
                "/home", 
                (route) => false
              );
            }
          } catch (e) {
            // Cerrar el diálogo de carga si está visible
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error al iniciar sesión con Google: ${e.toString()}"),
                backgroundColor: EcoPalette.error.color,
              ),
            );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              "https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg",
              height: screenHeight * 0.03,
            ),
            SizedBox(width: 8),
            Text(
              "Iniciar con Google",
              style: TextStyle(
                fontSize: (screenWidth + screenHeight) * 0.014,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ));
  }
}

class TituloApp extends StatelessWidget {
  const TituloApp({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "GeoApp",
          style: TextStyle(
            color: EcoPalette.white.color,
            fontSize: (screenWidth + screenHeight) * 0.035,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: EcoPalette.black.color.withOpacity(0.3),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Text(
          "Cuidando el planeta juntos",
          style: TextStyle(
            color: EcoPalette.white.color.withOpacity(0.9),
            fontSize: (screenWidth + screenHeight) * 0.014,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
