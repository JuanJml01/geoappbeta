**Configurando clave SHA en Windows**

El usuario necesita saber cómo configurar la clave SHA para utilizar Google Sign-In en Flutter en Windows. Existen diferentes métodos:

1. Usando `keytool` del JDK.
2. Mediante el comando `gradlew signingReport` en la terminal.
3. Con PowerShell usando OpenSSL.

Lo importante son dos valores de hash SHA: SHA-1 y SHA-256, obtenidos del keystore de depuración mediante el comando:
`keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android`.


**Métodos de configuración de clave SHA**

El usuario quiere saber cómo configurar la clave SHA en Windows para Google Sign-In en Flutter. Existen varios métodos:

1. Usando Gradle con el comando `gradlew signingReport` o a través de Android Studio en la vista de tareas Gradle.
2. Generando el keystore de release con `keytool -genkey`.
3. También se puede usar PowerShell o CMD con ciertos comandos.

En este caso, no se necesitan búsquedas online, pero se pueden citar fuentes como la documentación oficial de FlutterFire y Firebase.


Pensado durante 15 segundos


## Resumen de métodos para obtener la clave SHA en Windows

Para integrar Google Sign-In en Flutter necesitas registrar la huella digital (fingerprint) SHA-1 (y opcionalmente SHA-256) de tu aplicación en el proyecto de Firebase o en la consola de Google Cloud. En Windows existen varias formas de obtener estas claves:

1. **Usando `keytool`** (CMD o PowerShell) sobre el keystore de depuración (`debug.keystore`) o uno propio de lanzamiento.
2. **Con Gradle Signing Report** en la carpeta `android/` de tu proyecto, tanto en PowerShell como en CMD, o desde Android Studio por GUI.
3. **Extrayendo de un APK firmado** con `keytool -printcert`.
4. **Obteniendo la SHA de Play App Signing** directamente desde la Google Play Console si usas firma gestionada por Google.

A continuación se detallan cada una de estas opciones y los comandos concretos para Windows.

---

## 1. Usando `keytool` (CMD o PowerShell)

### 1.1 SHA de depuración (`debug.keystore`)

El JDK incluye la herramienta `keytool` que puede listar las huellas de certificado:

```bat
keytool -list -v \
  -keystore "%USERPROFILE%\.android\debug.keystore" \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

* **Explicación**:

  * `-keystore "%USERPROFILE%\.android\debug.keystore"` apunta al almacén de debug por defecto.
  * `-alias androiddebugkey` es el alias por defecto de la clave de depuración.
  * Las contraseñas por defecto son ambas `android`. ([Repeato][1], [GitHub][2])

El resultado incluye MD5, SHA-1 y SHA-256 bajo “Certificate fingerprints”.

### 1.2 SHA de lanzamiento (release keystore)

Si tienes tu propio keystore para producción, ajusta la ruta y alias:

```bat
keytool -list -v \
  -keystore "C:\ruta\a\my-release-key.jks" \
  -alias mi_alias \
  -storepass TU_STOREPASS \
  -keypass TU_KEYPASS
```

Sustituye las rutas y contraseñas por las de tu proyecto. ([Repeato][1])

---

## 2. Gradle Signing Report

### 2.1 Línea de comandos en PowerShell o CMD

1. Abre **PowerShell** o **Símbolo del sistema**.
2. Navega al directorio `android` de tu proyecto Flutter:

   ```bat
   cd C:\ruta\a\mi_proyecto\android
   ```
3. Ejecuta el task de Gradle para obtener el informe:

   * En PowerShell o CMD de Windows:

     ```bat
     .\gradlew signingReport
     ```
   * En Git Bash, WSL o similar:

     ```bash
     ./gradlew signingReport
     ```

El output mostrará un bloque “Variant: debug” (y “Variant: release” si tienes configurado un release signingConfig) con MD5, SHA-1 y SHA-256. ([Stack Overflow][3], [Google for Developers][4])

### 2.2 Usando Android Studio (GUI)

1. Abre tu proyecto en Android Studio.
2. En el panel **Gradle** (generalmente a la derecha), expande:

   ```
   :android
     └─ Tasks
        └─ android
           └─ signingReport
   ```
3. Haz doble clic en **signingReport**.
4. Revisa la ventana de **Run** para ver los fingerprints de cada variante. ([Medium][5])

---

## 3. Extrayendo SHA-1 de un APK firmado

Si ya tienes un APK firmado (por ejemplo `app-release.apk`), puedes usar `keytool` para leer su certificado:

```bat
keytool -printcert -jarfile "C:\ruta\a\app-release.apk"
```

Esto mostrará directamente la SHA-1 del certificado embebido. ([FlutterFlow Community][6])

---

## 4. SHA desde Google Play Console (Play App Signing)

Si tu app usa **Play App Signing** (firma gestionada por Google), la firma final que Google usa difiere de tu keystore local. Para verla:

1. Entra a **Google Play Console** y selecciona tu aplicación.
2. Ve a **Setup** → **App integrity** o **Integridad de la app**.
3. Bajo **Play App Signing key certificate**, copia la SHA-1 y SHA-256 mostradas.

Estas son las que debes registrar en Firebase/Google Cloud para que coincida con la firma final de la app publicada. ([Google for Developers][4])

---

### Notas adicionales

* Asegúrate de que la variable de entorno `JAVA_HOME` apunte al JDK correcto si recibes errores de “comando no encontrado” o de versión de Gradle. ([Medium][5])
* En PowerShell, recuerda usar `.\gradlew.bat` o `.\gradlew` si el `.bat` no está en tu PATH.
* Para entornos CI/CD, suele ser más robusto usar el método de Gradle Signing Report que `keytool`, pues no depende de rutas de keystore fijas.

Con estos métodos y comandos podrás obtener y configurar correctamente tus claves SHA-1/SHA-256 en Windows para el API de Google Sign-In en tu proyecto Flutter.

Lea y mira cual le funciona