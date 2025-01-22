import 'package:flutter/material.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
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
      body: Center(
        child: TextButton(
            onPressed: () {
              context.read<SessionProvider>().SalirSession();
              Navigator.pop(context);
            },
            child: Text("Salir Cuenta")),
      ),
    );
  }
}
