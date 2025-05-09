import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geoapptest/Pages/beta_login.dart';
import 'package:geoapptest/Pages/beta_subiendo_r.dart';
import 'package:geoapptest/Pages/beta_ver_reporte.dart';
import 'package:geoapptest/Provider/reporteProvider.dart';
import 'package:geoapptest/Provider/userProvider.dart';
import 'package:geoapptest/Service/tomarFoto.dart';
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
        title: 'GeopApp',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Login(),
          '/home': (context) => Skeleton(),
          '/subiendo': (context) => SubiendoReporte(),
          '/verReporte': (context) => VerReporte()
        },
      ),
    );
  }
}
