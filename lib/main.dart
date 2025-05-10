import 'package:flutter/material.dart';
import 'package:geoapptest/Pages/beta_home.dart';
import 'package:geoapptest/Provider/reporteProvider.dart';
import 'package:geoapptest/Provider/usuarioProvider.dart';
import 'package:geoapptest/Service/logger_service.dart';
import 'package:geoapptest/mocha.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase con URLs y claves
  await Supabase.initialize(
    url: 'https://pxoxxugokjhktgjpzihw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4b3h4dWdva2poa3Rnanopamd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTY1ODA2MzcsImV4cCI6MjAzMjE1NjYzN30.UIDGnLWDEjfQxUBbFZlBmOiOMjhlEAKBbFfnbKgSTlY',
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Reporteprovider()),
        ChangeNotifierProvider(create: (context) => UsuarioProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Inicializar proveedores después de construcción del widget
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<Reporteprovider>().fetchReporte();
        await context.read<UsuarioProvider>().inicializar();
        LoggerService.log('✅ Aplicación inicializada correctamente');
      } catch (e) {
        LoggerService.error('❌ Error al inicializar la aplicación: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoAppTest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Usar la paleta de colores Mocha definida en mocha.dart
        colorScheme: Mocha.lightColorScheme,
        // Configuración para transiciones de página animadas
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: Mocha.darkColorScheme,
        // Configuración para transiciones de página animadas
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: ThemeMode.system,
      home: const Home(),
    );
  }
}
