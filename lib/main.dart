import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geoapptest/Pages/beta_login.dart';
import 'package:geoapptest/Pages/beta_subiendo_r.dart';
import 'package:geoapptest/Pages/beta_ver_reporte.dart';
import 'package:geoapptest/Pages/todos_reportes.dart';
import 'package:geoapptest/Provider/reporteProvider.dart';
import 'package:geoapptest/Provider/userProvider.dart';
import 'package:geoapptest/Service/tomarFoto.dart';
import 'package:geoapptest/mocha.dart';
import 'package:geoapptest/skeleton.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno si es necesario
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Continuar si no hay archivo .env
    debugPrint('No se encontró archivo .env, usando valores predeterminados');
  }
  
  // Inicializar Supabase con URLs y claves
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'https://ouyznxujncdrdwpzchnf.supabase.co',
    anonKey: dotenv.env['SUPABASE_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4b3h4dWdva2poa3Rnanopamd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTY1ODA2MzcsImV4cCI6MjAzMjE1NjYzN30.UIDGnLWDEjfQxUBbFZlBmOiOMjhlEAKBbFfnbKgSTlY',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SessionProvider()),
        ChangeNotifierProvider(create: (context) => Reporteprovider()),
        Provider(create: (context) => TomarFoto()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GeoAppTest',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme(
            primary: EcoPalette.greenPrimary.color,
            secondary: EcoPalette.accent.color,
            surface: EcoPalette.white.color,
            background: EcoPalette.sand.color,
            error: EcoPalette.error.color,
            onPrimary: EcoPalette.white.color,
            onSecondary: EcoPalette.white.color,
            onSurface: EcoPalette.black.color,
            onBackground: EcoPalette.black.color,
            onError: EcoPalette.white.color,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: EcoPalette.sand.color,
          appBarTheme: AppBarTheme(
            backgroundColor: EcoPalette.greenPrimary.color,
            foregroundColor: EcoPalette.white.color,
            elevation: 0,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const Login(),
          '/home': (context) => const Skeleton(),
          '/verReporte': (context) => const VerReporte(),
          '/subiendo': (context) => const SubiendoReporte(),
          '/todosReportes': (context) => const TodosReportesPage(),
        },
      ),
    );
  }
}
