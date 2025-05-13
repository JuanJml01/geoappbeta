// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:geoapptest/Service/logger_service.dart';

class SessionProvider with ChangeNotifier {
  final Supabase _auth = Supabase.instance;

  User? _user;
  User? get user => _user;

  // Obtener el webClientId corregido
  String? get _webClientId {
    String? clientId = dotenv.env['webClientId'];
    
    if (clientId == null || clientId.isEmpty) {
      LoggerService.error('webClientId no está configurado en el archivo .env');
      return null;
    }
    
    // Verificar si el clientId contiene espacios o saltos de línea y limpiarlos
    clientId = clientId.trim();
    
    // Verificar si falta el sufijo .apps.googleusercontent.com
    if (!clientId.contains('.apps.googleusercontent.com')) {
      clientId = '$clientId.apps.googleusercontent.com';
    }
    
    LoggerService.auth('WebClientId obtenido: $clientId');
    return clientId;
  }

  Future<void> iniciarAnonimo() async {
    try {
      LoggerService.auth('Iniciando sesión anónima...');
      final userCredential = await _auth.client.auth.signInAnonymously();
      _user = userCredential.user;
      LoggerService.auth('Sesión anónima iniciada correctamente. User ID: ${_user?.id}');
      notifyListeners();
    } catch (e) {
      LoggerService.error('Error al iniciar sesión anónima: $e');
      throw ('Error al iniciar sesión anónima: $e');
    }
  }

  Future<void> iniciarGoogle() async {
    try {
      LoggerService.auth('Iniciando sesión con Google...');
      
      final clientId = _webClientId;
      if (clientId == null) {
        throw 'webClientId no configurado correctamente';
      }
      
      LoggerService.debug('WebClientId: $clientId');
      
      final googleUser = await GoogleSignIn(serverClientId: clientId).signIn();
      
      if (googleUser == null) {
        LoggerService.error('El usuario canceló el inicio de sesión con Google');
        throw 'Usuario canceló inicio de sesión';
      }
      
      LoggerService.auth('Usuario Google obtenido: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;

      final accesToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accesToken == null) {
        LoggerService.error('No se pudo obtener el Access Token de Google');
        throw 'No accestoken';
      }
      if (idToken == null) {
        LoggerService.error('No se pudo obtener el ID Token de Google');
        throw 'No idToken';
      }

      LoggerService.auth('Tokens de Google obtenidos. Iniciando sesión en Supabase...');
      final userCredential = await _auth.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accesToken);

      _user = userCredential.user;
      LoggerService.auth('Sesión con Google iniciada correctamente. User ID: ${_user?.id}');
      notifyListeners();
    } catch (e) {
      LoggerService.error('Error al iniciar sesión con Google: $e');
      throw ('Error al iniciar sesión con Google: $e');
    }
  }

  /// Realiza la autenticación con Google en Android
  Future<AuthResponse> signInWithGoogle() async {
    try {
      LoggerService.auth('Iniciando sesión con Google (método mejorado)...');
      
      // Verificar si webClientId está configurado
      final clientId = _webClientId;
      if (clientId == null) {
        throw AuthException('webClientId no está configurado correctamente');
      }
      
      LoggerService.debug('WebClientId: $clientId');
      
      // Generar nonce para seguridad
      final rawNonce = _auth.client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      LoggerService.debug('Nonce generado');
      
      // Iniciar sesión con Google
      LoggerService.auth('Solicitando cuenta de Google...');
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        serverClientId: clientId,
        scopes: ['email', 'profile'],
      ).signIn();
      
      if (googleUser == null) {
        LoggerService.error('El usuario canceló el inicio de sesión con Google');
        throw const AuthException('El usuario canceló el inicio de sesión con Google.');
      }
      
      LoggerService.auth('Usuario Google obtenido: ${googleUser.email}');
      
      // Obtener tokens de autenticación
      LoggerService.auth('Solicitando tokens de autenticación...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      
      if (idToken == null) {
        LoggerService.error('No se pudo obtener el ID Token de Google');
        throw const AuthException('No se pudo obtener el ID Token de Google.');
      }
      
      LoggerService.auth('Tokens obtenidos. Iniciando sesión en Supabase...');
      
      // Autenticar con Supabase usando el token de Google
      final authResponse = await _auth.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
        nonce: rawNonce,
      );
      
      // Actualizar el usuario y notificar a los listeners
      _user = authResponse.user;
      LoggerService.auth('Sesión con Google iniciada correctamente. User ID: ${_user?.id}');
      notifyListeners();
      
      return authResponse;
    } catch (e) {
      LoggerService.error('Error al iniciar sesión con Google: $e');
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Error al iniciar sesión con Google: $e');
    }
  }

  Future<void> salirSession() async {
    try {
      LoggerService.auth('Cerrando sesión...');
      await _auth.client.auth.signOut();
      await GoogleSignIn().signOut();
      _user = null;
      LoggerService.auth('Sesión cerrada correctamente');
      notifyListeners();
    } catch (e) {
      LoggerService.error('Error al cerrar sesión: $e');
      throw ('Error al cerrar sesión: $e');
    }
  }
}
