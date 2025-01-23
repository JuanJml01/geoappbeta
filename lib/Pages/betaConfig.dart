// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:provider/provider.dart';

class UsuarioConfig extends StatefulWidget {
  const UsuarioConfig({super.key});

  @override
  State<UsuarioConfig> createState() => _UsuarioConfigState();
}

class _UsuarioConfigState extends State<UsuarioConfig> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(color: Mocha.base.color),
        child: Center(
          child: TextButton(
              onPressed: () {
                context.read<SessionProvider>().salirSession();
                Navigator.pop(context);
              },
              child: Text(
                "Salir Cuenta",
                style: TextStyle(color: Mocha.text.color),
              )),
        ),
      ),
    );
  }
}
