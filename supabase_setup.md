# Configuración de Supabase para GeoAppTest

Este documento contiene las instrucciones para configurar Supabase correctamente para la aplicación GeoAppTest.

## Requisitos

1. Tener una cuenta en [Supabase](https://supabase.com/)
2. Haber creado un proyecto en Supabase

## Pasos para la configuración

### 1. Ejecutar el script SQL para configurar la base de datos

Hay dos opciones para ejecutar el script SQL:

#### Opción 1: Desde el Editor SQL de Supabase

1. Inicia sesión en tu proyecto de Supabase
2. Ve a la sección "SQL Editor"
3. Crea un nuevo script y copia el contenido del archivo `db_reset_complete.sql`
4. Ejecuta el script

#### Opción 2: Desde la línea de comandos con Supabase CLI

1. Instala Supabase CLI si no lo tienes instalado
2. Ejecuta los siguientes comandos:

```
supabase login
supabase link --project-ref TU_REFERENCIA_DE_PROYECTO
supabase db push --db-file db_reset_complete.sql
```

### 2. Configurar el Storage

1. En la sección "Storage" de Supabase, crea dos buckets:
   - `imagenes`: para almacenar las imágenes de los reportes
   - `perfiles`: para almacenar las fotos de perfil de los usuarios

2. Configura los buckets con acceso público para lectura:
   - En cada bucket, ve a "Policies"
   - Añade una política para permitir a todos los usuarios ver los archivos
   - Ejemplo de política para lectura pública:
     ```sql
     CREATE POLICY "Permitir acceso de lectura público" 
     ON storage.objects FOR SELECT 
     TO public 
     USING (bucket_id = 'imagenes' OR bucket_id = 'perfiles');
     ```

### 3. Configurar autenticación

1. Ve a la sección "Authentication" > "Providers"
2. Habilita "Email" como método de autenticación
3. Si lo deseas, puedes configurar otros proveedores como Google, Facebook, etc.
4. Opcionalmente, configura los correos electrónicos de confirmación y recuperación de contraseña

### 4. Actualizar la configuración de la aplicación

Asegúrate de que las credenciales en el archivo `lib/main.dart` coincidan con las de tu proyecto:

```dart
await Supabase.initialize(
  url: 'https://TU_REFERENCIA.supabase.co',
  anonKey: 'TU_CLAVE_ANONIMA',
);
```

## URLs y APIs de Supabase en la aplicación

La aplicación requiere acceso a tres servicios principales de Supabase:

1. **Base de datos**: Para almacenar y recuperar reportes, usuarios, logros, etc.
2. **Storage**: Para almacenar imágenes de reportes y fotos de perfil
3. **Autenticación**: Para gestionar usuarios y sesiones

## Verificación

Para verificar que la configuración es correcta:

1. Ejecuta la aplicación
2. Intenta crear un usuario y iniciar sesión
3. Crea un reporte nuevo con una imagen
4. Verifica que puedas ver los reportes en el mapa

Si todos estos pasos funcionan correctamente, ¡la configuración está lista! 