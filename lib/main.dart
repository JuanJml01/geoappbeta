import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geoappbeta/Pages/beta_login.dart';
import 'package:geoappbeta/Pages/beta_subiendo_r.dart';
import 'package:geoappbeta/Pages/beta_ver_reporte.dart';
import 'package:geoappbeta/Pages/todos_reportes.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:geoappbeta/Provider/usuarioProvider.dart';
import 'package:geoappbeta/Service/logger_service.dart';
import 'package:geoappbeta/Service/tomarFoto.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:geoappbeta/skeleton.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Archivo .env cargado correctamente');
    
    // Mostrar variables cargadas (sólo para depuración)
    debugPrint('Variables cargadas:');
    debugPrint('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']?.isNotEmpty == true ? "Configurado" : "No configurado"}');
    debugPrint('SUPABASE_KEY: ${dotenv.env['SUPABASE_KEY']?.isNotEmpty == true ? "Configurado" : "No configurado"}');
    debugPrint('webClientId: ${dotenv.env['webClientId']?.isNotEmpty == true ? "Configurado" : "No configurado"}');
    debugPrint('apiKey: ${dotenv.env['apiKey']?.isNotEmpty == true ? "Configurado" : "No configurado"}');
  } catch (e) {
    // Continuar si no hay archivo .env
    debugPrint('No se encontró archivo .env: $e');
    debugPrint('Asegúrate de que el archivo .env exista en la raíz del proyecto con las siguientes variables:');
    debugPrint('- SUPABASE_URL');
    debugPrint('- SUPABASE_KEY');
    debugPrint('- webClientId');
    debugPrint('- apiKey');
  }
  
  // Inicializar Supabase
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_KEY'];
    
    if (supabaseUrl != null && supabaseKey != null) {
      debugPrint('Inicializando Supabase...');
      
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      
      debugPrint('✅ Supabase inicializado correctamente');
    } else {
      throw Exception('Faltan variables de entorno necesarias para inicializar Supabase');
    }
  } catch (e) {
    debugPrint('❌ Error al inicializar Supabase: $e');
    debugPrint('Verifica que el archivo .env contenga SUPABASE_URL y SUPABASE_KEY válidos');
  }
  
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
        ChangeNotifierProvider(create: (context) => UsuarioProvider()),
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
