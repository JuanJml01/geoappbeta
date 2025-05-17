// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:geoappbeta/Provider/userProvider.dart';
import 'package:geoappbeta/Provider/usuarioProvider.dart';
import 'package:geoappbeta/Service/config_service.dart';
import 'package:geoappbeta/Service/error_service.dart';
import 'package:geoappbeta/Service/logger_service.dart';
import 'package:geoappbeta/Widgets/loading_dialog.dart';
import 'package:provider/provider.dart';
import 'package:geoappbeta/mocha.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _configuracionVerificada = false;
  bool _configuracionValida = true;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _verificarConfiguracion();
  }

  Future<void> _verificarConfiguracion() async {
    try {
      LoggerService.log('Verificando configuración de la aplicación...');
      
      // Verificar si el archivo .env se cargó correctamente
      if (dotenv.env.isEmpty) {
        setState(() {
          _configuracionVerificada = true;
          _configuracionValida = false;
          _mensajeError = 'Error de configuración:\n• No se encontró el archivo .env\n\nEjecuta el script crear_env.bat para generar el archivo .env con las variables necesarias.';
        });
        return;
      }
      
      // Verificar variables de entorno
      final variablesValidas = await ConfigService.verificarVariablesEntorno();
      
      // Verificar conexión con Supabase
      final conexionValida = await ConfigService.verificarConexionSupabase();
      
      // Verificar configuración de Google Auth
      final googleAuthValido = await ConfigService.verificarConfiguracionGoogleAuth();
      
      setState(() {
        _configuracionVerificada = true;
        _configuracionValida = variablesValidas && conexionValida && googleAuthValido;
        
        if (!_configuracionValida) {
          _mensajeError = 'Error de configuración:\n';
          
          // Verificar variables específicas
          if (dotenv.env['SUPABASE_URL'] == null || dotenv.env['SUPABASE_URL']!.isEmpty) {
            _mensajeError = _mensajeError! + '• SUPABASE_URL no está configurado\n';
          }
          if (dotenv.env['SUPABASE_KEY'] == null || dotenv.env['SUPABASE_KEY']!.isEmpty) {
            _mensajeError = _mensajeError! + '• SUPABASE_KEY no está configurado\n';
          }
          if (dotenv.env['webClientId'] == null || dotenv.env['webClientId']!.isEmpty) {
            _mensajeError = _mensajeError! + '• webClientId no está configurado\n';
          }
          if (dotenv.env['apiKey'] == null || dotenv.env['apiKey']!.isEmpty) {
            _mensajeError = _mensajeError! + '• apiKey no está configurado\n';
          }
          
          // Añadir mensajes de error generales
          if (!variablesValidas) _mensajeError = _mensajeError! + '• Variables de entorno incorrectas\n';
          if (!conexionValida) _mensajeError = _mensajeError! + '• No se pudo conectar con Supabase\n';
          if (!googleAuthValido) _mensajeError = _mensajeError! + '• Configuración de Google Auth incorrecta\n';
          
          _mensajeError = _mensajeError! + '\nEjecuta el script crear_env.bat en la raíz del proyecto para generar el archivo .env con las variables correctas.';
        }
      });
    } catch (e) {
      setState(() {
        _configuracionVerificada = true;
        _configuracionValida = false;
        _mensajeError = 'Error al verificar la configuración:\n$e\n\nVerifica el archivo .env en la raíz del proyecto.';
      });
      LoggerService.error('Error al verificar la configuración: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EcoPalette.greenPrimary.color,
              EcoPalette.greenDark.color,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.08),
                TituloApp(screenWidth: screenWidth, screenHeight: screenHeight),
                SizedBox(height: screenHeight * 0.04),
                Container(
                  width: screenWidth * 0.8,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EcoPalette.white.color.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: EcoPalette.black.color.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.eco,
                        size: screenWidth * 0.15,
                        color: EcoPalette.greenPrimary.color,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "Bienvenido a GeoApp",
                        style: TextStyle(
                          fontSize: (screenWidth + screenHeight) * 0.018,
                          fontWeight: FontWeight.bold,
                          color: EcoPalette.greenDark.color,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        "Inicia sesión para continuar",
                        style: TextStyle(
                          fontSize: (screenWidth + screenHeight) * 0.012,
                          color: EcoPalette.gray.color,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      if (!_configuracionVerificada)
                        CircularProgressIndicator(
                          color: EcoPalette.greenPrimary.color,
                        )
                      else if (!_configuracionValida)
                        Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                            SizedBox(height: 10),
                            Text(
                              _mensajeError ?? 'Error de configuración',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () {
                                _verificarConfiguracion();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EcoPalette.greenPrimary.color,
                                foregroundColor: EcoPalette.white.color,
                              ),
                              child: Text("Intentar nuevamente"),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            BotonLoginGoogle(screenWidth: screenWidth, screenHeight: screenHeight),
                            SizedBox(height: screenHeight * 0.02),
                            BotonLoginAno(screenWidth: screenWidth, screenHeight: screenHeight),
                          ],
                        ),
                    ],
                  ),
                ),
                Spacer(),
                TextoInferior(screenWidth: screenWidth, screenHeight: screenHeight),
                SizedBox(height: screenHeight * 0.04),
              ],
            ),
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
    return Container(
      width: screenWidth * 0.8,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: EcoPalette.white.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "lorem ipsum dolor sit ames, connecter advising el super nill tempore inv sociol ad minim venial",
        style: TextStyle(
          fontSize: (screenWidth + screenHeight) * 0.01,
          color: EcoPalette.white.color,
          shadows: [
            Shadow(
              color: EcoPalette.black.color.withOpacity(0.3),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
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
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: EcoPalette.white.color,
            foregroundColor: EcoPalette.greenPrimary.color,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            minimumSize: Size(screenWidth * 0.62, screenHeight * 0.055)),
        onPressed: () async {
          try {
            // Mostrar diálogo de carga
            LoadingDialog.show(context, mensaje: 'Iniciando sesión...');
            
            LoggerService.auth('Botón de inicio anónimo presionado');
            final sessionProvider = context.read<SessionProvider>();
            
            // Intentar iniciar sesión anónima
            await sessionProvider.iniciarAnonimo();
            
            // Verificar si el usuario fue creado correctamente
            if (sessionProvider.user == null) {
              LoggerService.error('Error: Usuario anónimo es null después de iniciar sesión');
              throw Exception("Error al iniciar sesion anonima: usuario es null");
            } else {
              LoggerService.auth('Usuario anónimo creado correctamente: ${sessionProvider.user?.id}');
              
              // Inicializar el perfil de usuario
              final usuarioProvider = context.read<UsuarioProvider>();
              LoggerService.auth('Inicializando perfil de usuario anónimo...');
              await usuarioProvider.inicializar();
              LoggerService.auth('Perfil de usuario anónimo inicializado');
              
              // Cerrar el diálogo de carga
              LoadingDialog.hide(context);
              
              // Navegar a la pantalla principal
              LoggerService.auth('Navegando a la pantalla principal');
              Navigator.pushNamedAndRemoveUntil(
                context, 
                "/home", 
                (route) => false
              );
            }
          } catch (e) {
            // Cerrar el diálogo de carga
            LoadingDialog.hide(context);
            
            LoggerService.error('Error en botón de inicio anónimo: $e');
            
            // Mostrar error con el nuevo servicio
            ErrorService.mostrarError(
              context: context,
              titulo: 'Error de inicio de sesión',
              mensaje: ErrorService.obtenerMensajeError(e),
            );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline),
            SizedBox(width: 8),
            Text(
              "Iniciar como anónimo",
              style: TextStyle(
                fontSize: (screenWidth + screenHeight) * 0.014,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: EcoPalette.white.color,
            foregroundColor: Colors.black87,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            minimumSize: Size(screenWidth * 0.62, screenHeight * 0.055)),
        onPressed: () async {
          try {
            // Mostrar diálogo de carga
            LoadingDialog.show(context, mensaje: 'Conectando con Google...');
            
            LoggerService.auth('Botón de inicio con Google presionado');
            
            // Usar la nueva función de autenticación con Google
            final sessionProvider = context.read<SessionProvider>();
            
            LoggerService.auth('Llamando a signInWithGoogle()...');
            final authResponse = await sessionProvider.signInWithGoogle();
            
            if (authResponse.user == null) {
              LoggerService.error('Error: Usuario de Google es null después de iniciar sesión');
              throw Exception("Error al iniciar sesión con Google: usuario es null");
            } else {
              LoggerService.auth('Usuario de Google creado correctamente: ${authResponse.user?.id}');
              LoggerService.auth('Email: ${authResponse.user?.email}');
              
              // Inicializar el perfil de usuario
              final usuarioProvider = context.read<UsuarioProvider>();
              LoggerService.auth('Inicializando perfil de usuario de Google...');
              await usuarioProvider.inicializar();
              LoggerService.auth('Perfil de usuario de Google inicializado');
              
              // Cerrar el diálogo de carga
              LoadingDialog.hide(context);
              
              // Navegar a la pantalla principal
              LoggerService.auth('Navegando a la pantalla principal');
              Navigator.pushNamedAndRemoveUntil(
                context, 
                "/home", 
                (route) => false
              );
            }
          } catch (e) {
            // Cerrar el diálogo de carga
            LoadingDialog.hide(context);
            
            LoggerService.error('Error en botón de inicio con Google: $e');
            
            // Mostrar error con el nuevo servicio
            ErrorService.mostrarError(
              context: context,
              titulo: 'Error de inicio de sesión',
              mensaje: ErrorService.obtenerMensajeError(e),
            );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              "https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg",
              height: screenHeight * 0.03,
            ),
            SizedBox(width: 8),
            Text(
              "Iniciar con Google",
              style: TextStyle(
                fontSize: (screenWidth + screenHeight) * 0.014,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
    return Column(
      children: [
        Text(
          "GeoApp",
          style: TextStyle(
            color: EcoPalette.white.color,
            fontSize: (screenWidth + screenHeight) * 0.035,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: EcoPalette.black.color.withOpacity(0.3),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Text(
          "Cuidando el planeta juntos",
          style: TextStyle(
            color: EcoPalette.white.color.withOpacity(0.9),
            fontSize: (screenWidth + screenHeight) * 0.014,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
