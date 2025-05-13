# Configuración de Autenticación con Google en Android

Este documento explica cómo configurar la autenticación con Google en tu aplicación Flutter para Android.

## Requisitos previos

1. Tener una cuenta de Google Cloud Platform
2. Tener un proyecto creado en Firebase
3. Tener configurado Supabase para autenticación

## Pasos para configurar Google Sign-In en Android

### 1. Configurar el proyecto en Google Cloud Platform

1. Ve a la [Consola de Google Cloud](https://console.cloud.google.com/)
2. Selecciona tu proyecto o crea uno nuevo
3. Ve a "APIs y servicios" > "Credenciales"
4. Haz clic en "Crear credenciales" > "ID de cliente de OAuth"
5. Selecciona "Aplicación de Android" como tipo de aplicación
6. Completa la información requerida:
   - Nombre: Nombre de tu aplicación
   - Paquete: El ID de paquete de tu aplicación Android (ej. `com.example.geoapptest`)
   - Huella digital SHA-1: La huella digital de tu certificado de firma

### 2. Obtener la huella digital SHA-1

Para obtener la huella digital SHA-1 en Windows:

```bash
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android
```

### 3. Configurar el archivo build.gradle

Asegúrate de que el archivo `android/app/build.gradle` tenga configurado correctamente el ID de paquete:

```gradle
defaultConfig {
    applicationId "com.example.geoapptest" // Debe coincidir con el ID registrado en Google Cloud
    // ...
}
```

### 4. Configurar el archivo AndroidManifest.xml

Añade los siguientes permisos en tu archivo `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 5. Configurar variables de entorno

Crea o actualiza el archivo `.env` en la raíz de tu proyecto con la siguiente variable:

```
SUPABASE_URL=tu_url_de_supabase
SUPABASE_KEY=tu_clave_anonima_de_supabase
webClientId=tu_id_de_cliente_web_de_google
```

El `webClientId` es el ID de cliente de OAuth para aplicaciones web que puedes obtener en la consola de Google Cloud.

### 6. Instalar dependencias necesarias

Asegúrate de tener las siguientes dependencias en tu archivo `pubspec.yaml`:

```yaml
dependencies:
  google_sign_in: ^6.2.1
  supabase_flutter: ^2.3.4
  flutter_dotenv: ^5.1.0
  crypto: ^3.0.3
```

### 7. Usar la función de autenticación

Para utilizar la función de autenticación con Google:

```dart
try {
  final sessionProvider = context.read<SessionProvider>();
  final authResponse = await sessionProvider.signInWithGoogle();
  
  if (authResponse.user != null) {
    // Autenticación exitosa
    // Navegar a la pantalla principal
  }
} catch (e) {
  // Manejar el error
}
```

## Solución de problemas comunes

1. **Error "Sign in failed com.google.android.gms.common.api.ApiException: 10"**
   - Verifica que el SHA-1 esté correctamente configurado en Google Cloud
   - Asegúrate de estar usando el mismo keystore para firmar la aplicación

2. **Error "No se pudo obtener el ID Token de Google"**
   - Verifica que el webClientId sea correcto
   - Asegúrate de tener conexión a internet

3. **Error "Error al iniciar sesión con Google"**
   - Verifica los logs para obtener más detalles sobre el error
   - Asegúrate de que Supabase esté configurado para aceptar autenticación con Google 