import 'package:flutter/material.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:geoappbeta/mocha.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(color: Mocha.base.color),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: screenHeight * 0.1,
              ),
              tituloApp(screenWidth: screenWidth, screenHeight: screenHeight),
              SizedBox(
                height: screenHeight * 0.30,
              ),
              botonLoginGoogle(
                  screenWidth: screenWidth, screenHeight: screenHeight),
              botonLoginAno(
                  screenWidth: screenWidth, screenHeight: screenHeight),
              SizedBox(
                height: screenHeight * 0.3,
              ),
              TextoInferior(
                  screenWidth: screenWidth, screenHeight: screenHeight),
              SizedBox(
                height: screenHeight * 0.040,
              )
            ],
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
    return SizedBox(
      width: screenWidth * 0.8,
      child: Text(
        "lorem ipsum dolor sit amet, consectetur adipiscing el super nisl tempor inv sociosqu ad minim veniam",
        style: TextStyle(
            fontSize: (screenWidth + screenHeight) * 0.01,
            color: Mocha.text.color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class botonLoginAno extends StatelessWidget {
  const botonLoginAno({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: TextButton.styleFrom(
            backgroundColor: Mocha.surface2.color,
            side: BorderSide(width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            minimumSize: Size(screenWidth * 0.62, screenHeight * 0.045)),
        onPressed: () async {
          try {
            await context.read<SessionProvider>().IniciarAnonimo();
            if (context.read<SessionProvider>().user == null) {
              throw Exception("Error al iniciar sesion anonima");
            } else {
              Navigator.pushNamed(context, "/home");
            }
          } catch (e) {
            print("Error al iniciar sesion anonima: $e");
          }
        },
        child: Text(
          "Iniciar anonimo",
          style: TextStyle(
              fontSize: (screenWidth + screenHeight) * 0.014,
              color: Mocha.text.color),
        ));
  }
}

class botonLoginGoogle extends StatelessWidget {
  const botonLoginGoogle({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            side: BorderSide(width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            minimumSize: Size(screenWidth * 0.62, screenHeight * 0.045)),
        onPressed: () async {
          try {
            await context.read<SessionProvider>().IniciarGoogle();
            if (context.read<SessionProvider>().user == null) {
              throw Exception("Error al iniciar sesion con google");
            } else {
              print("hola");
              Navigator.pushNamed(context, "/home");
            }
          } catch (e) {
            print("Error al iniciar sesion con google: $e");
          }
        },
        child: Text(
          "Iniciar con google",
          style: TextStyle(
              fontSize: (screenWidth + screenHeight) * 0.014,
              color: Mocha.mantle.color),
        ));
  }
}

class tituloApp extends StatelessWidget {
  const tituloApp({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      "GeopApp beta",
      style: TextStyle(
          color: Mocha.green.color,
          fontSize: (screenWidth + screenHeight) * 0.026,
          fontWeight: FontWeight.bold),
    );
  }
}
