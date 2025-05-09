// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geoapptest/Provider/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:geoapptest/mocha.dart';

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
              TituloApp(screenWidth: screenWidth, screenHeight: screenHeight),
              SizedBox(
                height: screenHeight * 0.30,
              ),
              BotonLoginGoogle(
                  screenWidth: screenWidth, screenHeight: screenHeight),
              BotonLoginAno(
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
        "lorem ipsum dolor sit ames, connecter advising el super nill tempore inv sociol ad minim venial",
        style: TextStyle(
            fontSize: (screenWidth + screenHeight) * 0.01,
            color: Mocha.text.color),
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
    return TextButton(
        style: TextButton.styleFrom(
            backgroundColor: Mocha.lavender.color,
            side: BorderSide(width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            minimumSize: Size(screenWidth * 0.62, screenHeight * 0.045)),
        onPressed: () async {
          try {
            await context.read<SessionProvider>().iniciarAnonimo();
            if (context.read<SessionProvider>().user == null) {
              throw Exception("Error al iniciar sesion anonima");
            } else {
              Navigator.pushNamed(context, "/home");
            }
          } catch (e) {
            throw ("Error al iniciar sesion anonima: $e");
          }
        },
        child: Text(
          "Iniciar anonimo",
          style: TextStyle(
              fontSize: (screenWidth + screenHeight) * 0.014,
              color: Mocha.mantle.color),
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
    return TextButton(
        style: TextButton.styleFrom(
            backgroundColor: Mocha.text.color,
            side: BorderSide(width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            minimumSize: Size(screenWidth * 0.62, screenHeight * 0.045)),
        onPressed: () async {
          try {
            await context.read<SessionProvider>().iniciarGoogle();
            if (context.read<SessionProvider>().user == null) {
              throw Exception("Error al iniciar sesion con google");
            } else {
              Navigator.pushNamed(context, "/home");
            }
          } catch (e) {
            throw ("Error al iniciar sesion con google: $e");
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
    return Text(
      "GeopApp beta",
      style: TextStyle(
          color: Mocha.green.color,
          fontSize: (screenWidth + screenHeight) * 0.026,
          fontWeight: FontWeight.bold),
    );
  }
}
