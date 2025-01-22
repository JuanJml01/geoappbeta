import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geoappbeta/Pages/betaLogin.dart';
import 'package:geoappbeta/Pages/betaSubiendoR.dart';
import 'package:geoappbeta/Provider/reporteProvider.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:geoappbeta/Service/tomarFoto.dart';
import 'package:geoappbeta/skeleton.dart';
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
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Login(),
          '/home': (context) => Skeleton(),
          '/subiendo': (context) => SubiendoReporte(),
        },
      ),
    );
  }
}
