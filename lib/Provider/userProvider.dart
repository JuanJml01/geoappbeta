// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SessionProvider with ChangeNotifier {
  final Supabase _auth = Supabase.instance;

  User? _user;
  User? get user => _user;

  Future<void> iniciarAnonimo() async {
    try {
      final userCredential = await _auth.client.auth.signInAnonymously();
      _user = userCredential.user;
      notifyListeners();
    } catch (e) {
      throw ('Error al iniciar sesión anónima: $e');
    }
  }

  Future<void> iniciarGoogle() async {
    try {
      final googleUser =
          await GoogleSignIn(serverClientId: dotenv.env['webClientId']).signIn();
      final googleAuth = await googleUser!.authentication;

      final accesToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accesToken == null) {
        throw 'No accestoken';
      }
      if (idToken == null) {
        throw 'No idToken';
      }

      final userCredential = await _auth.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accesToken);

      _user = userCredential.user;
      notifyListeners();
    } catch (e) {
      throw ('Error al iniciar sesión con Google: $e');
    }
  }

  Future<void> salirSession() async {
    await _auth.client.auth.signOut();
    await GoogleSignIn().signOut();
    _user = null;
    notifyListeners();
  }
}
