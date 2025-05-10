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
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
      url: 'https://ouyznxujncdrdwpzchnf.supabase.co',
      anonKey: dotenv.env['SUPABASE_KEY'] ?? "");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SessionProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => Reporteprovider(),
        ),
        Provider(create: (context) => TomarFoto())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GeoApp',
        theme: ThemeData(
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
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: EcoPalette.greenPrimary.color,
              foregroundColor: EcoPalette.white.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: CardTheme(
            color: EcoPalette.white.color,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textTheme: TextTheme(
            titleLarge: TextStyle(color: EcoPalette.greenDark.color, fontWeight: FontWeight.bold),
            titleMedium: TextStyle(color: EcoPalette.greenPrimary.color),
            bodyLarge: TextStyle(color: EcoPalette.black.color),
            bodyMedium: TextStyle(color: EcoPalette.black.color),
          ),
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
          splashColor: EcoPalette.greenLight.color.withOpacity(0.3),
          highlightColor: EcoPalette.greenLight.color.withOpacity(0.1),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Login(),
          '/home': (context) => Skeleton(),
          '/subiendo': (context) => SubiendoReporte(),
          '/verReporte': (context) => VerReporte(),
          '/todosReportes': (context) => const TodosReportesPage(),
        },
      ),
    );
  }
}
