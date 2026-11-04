# Sistema de cotizaciones – Flutter + Firebase

La aplicación móvil **CotizApp**, desarrollada en Flutter, está destinada a la gestión integral de cotizaciones de proyectos de pintura y construcción. Permite crear, editar, previsualizar y enviar cotizaciones mediante archivos PDF a clientes registrados dentro de la misma aplicación. Además, posee soporte offline y sincronización automática con Firebase.

## Librerías utilizadas

| Librería | Versión | Uso |
|---|---|---|
| flutter (SDK) | ^3.11.1 | Framework principal |
| firebase_core | ^4.10.0 | Inicialización de Firebase |
| firebase_auth | ^6.5.2 | Autenticación de usuarios |
| cloud_firestore | ^6.4.1 | Base de datos en tiempo real |
| firebase_storage | ^13.4.1 | Almacenamiento de archivos PDF (requiere plan Blaze) |
| pdf | ^3.12.0 | Generación de documentos PDF |
| printing | ^5.14.3 | Previsualización e impresión de PDFs |
| path_provider | ^2.1.5 | Acceso a rutas del sistema de archivos |
| intl | ^0.20.2 | Formateo de fechas y montos en CLP |
| url_launcher | ^6.3.0 | Apertura de URLs externas |
| syncfusion_flutter_pdfviewer | ^28.2.7 | Visualización de PDFs en la aplicación |
| share_plus | ^12.0.2 | Compartir archivos desde la aplicación |
| file_picker | ^8.0.0 | Importación de archivos CSV (materiales para esta aplicación) |
| shared_preferences | ^2.3.2 | Almacenamiento local de borradores y documentos offline |
| connectivity_plus | ^7.1.1 | Detección del estado de red (online/offline) |
| cupertino_icons | ^1.0.8 | Iconos estilo iOS |

## Requisitos previos para el uso correcto de la aplicación

- Flutter SDK ^3.11.1.
- Android Studio o Visual Studio Code con la extensión de Flutter.
- Dart SDK (incluido con Flutter).
- Dispositivo Android o emulador.

## Instalación

### 1. Clonar repositorio de GitHub

Previamente se debe tener instalado Git Bash para Windows. Una vez instalado, abrir una terminal y ejecutar:

```bash
git clone https://github.com/cielovinazza/desarrollo_movil
cd desarrollo_movil
```

### 2. Instalar dependencias

Dentro de la carpeta del proyecto, ejecutar:

```bash
flutter pub get
```

Este comando instala automáticamente las librerías declaradas en `pubspec.yaml`.

### 3. Verificar entorno

Ejecutar:

```bash
flutter doctor
```

Este comando permite comprobar que Flutter, los SDK y las herramientas necesarias estén correctamente configurados. Si algún elemento presenta errores, seguir las instrucciones mostradas en la terminal.

### 4. Conectar un dispositivo

**Opción A: Dispositivo Android físico**

Activar las opciones de desarrollador (presionar siete veces el número de compilación en "Acerca del teléfono", dentro de Configuración) y habilitar la depuración por USB o inalámbrica.

**Opción B: Emulador**

Utilizar un emulador de Android Studio:

1. Abrir Device Manager.
2. Seleccionar Create Device.
3. Elegir un dispositivo con API 21 o superior.
4. Crear e iniciar el emulador.

Para verificar que el dispositivo esté conectado:

```bash
flutter devices
```

Luego ejecutar:

```bash
flutter run
```

Si todo está configurado correctamente, la aplicación se abrirá en el dispositivo o emulador.

### 5. Generar APK de release (opcional)

Para generar un APK instalable sin necesidad de utilizar Android Studio ni mantener activa la depuración, ejecutar:

```bash
flutter build apk --release
```

El archivo se encontrará en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Copiar el archivo `.apk` al dispositivo físico. Es posible que sea necesario habilitar la instalación de aplicaciones de fuentes desconocidas desde Ajustes → Seguridad.

---

## Backend – Firebase

El backend de la aplicación está completamente gestionado por Firebase (servicio de Google). No requiere servidor propio ni infraestructura adicional.

### Servicios utilizados

- **Firebase Authentication:** login y gestión de sesiones de usuario mediante correo y contraseña. Las cuentas son administradas desde Firebase Console.
- **Cloud Firestore:** base de datos NoSQL donde se almacenan las cotizaciones, clientes, historial de correos enviados y contadores.
- **Firebase Storage:** almacenamiento en la nube para los archivos PDF generados por la aplicación.
- **Trigger Email (extensión):** permite el envío automático de PDFs al correo de los clientes. También escribe los datos en la colección `historial_correos`.

### Estructura de la base de datos

**cotizaciones/**

```text
cotizaciones/
  {cotizacionId}/
    - id
    - codigo                  (distinto de id, ej: "CT-001" o "CT-001-V2")
    - clienteId
    - clienteNombre
    - clienteEmail
    - clienteRut
    - clienteTelefono
    - clienteDireccion
    - direccion               (dirección de la obra)
    - trabajos[]              (tipo, metrosCuadrados, precioPorMetro, descripcionBreve)
    - manoObra[]              (cargo, dias, valorJornada)
    - materiales[]            (nombre, cantidad, costoUnitario, unidadMedida)
    - subtotalObra
    - subtotalMateriales
    - subtotalManoObra
    - viatico
    - porcentajeUtilidad
    - porcentajeIva
    - totalFinal
    - estado                  ("En Proceso", "Aprobada", "Rechazada por el Cliente", etc.)
    - usuarioId
    - pdfUrl                  (URL del PDF subido a Firebase Storage)
    - observacion
    - version                 (entero, se incrementa en cada edición)
    - fechaCreacion
    - fechaEdicion
    - fechaCambioEstado
```

**contadores/**

```text
contadores/
  cotizaciones/
    - ultimoNumero            (genera códigos correlativos CT-001, CT-002, ...)
```

**historial_correos/**

```text
historial_correos/
  {docId}/
    - to                      (email del cliente)
    - message/
        - subject
        - html
        - attachments[]       (filename, path con URL del PDF en Storage)
```

## Cómo conectarse a Firebase

Dentro de la carpeta `android/app/` de este proyecto existe un archivo llamado `google-services.json`, que contiene la configuración necesaria para que la aplicación Android se conecte al proyecto Firebase.

También existe el archivo `firebase_options.dart` dentro de la carpeta `lib/`, que Flutter utiliza internamente para inicializar la conexión con Firebase al arrancar la aplicación.

Ambos archivos están incluidos en el repositorio. Por lo tanto, al clonar el proyecto y ejecutar `flutter run`, la aplicación se conecta automáticamente al proyecto Firebase configurado, sin necesidad de realizar pasos adicionales de conexión.

### Credenciales de prueba

Para ingresar a la aplicación se pueden utilizar las siguientes credenciales de prueba. De lo contrario, se debe solicitar al administrador de Firebase que otorgue un usuario con correo personal para cambiar la contraseña.

**Correo:** `pruebafirebase@test.com`

**Contraseña:** `123456`

### Importante

Si al ejecutar la aplicación aparece un error relacionado con Firebase (por ejemplo, `FirebaseException` o `google-services.json not found`), verificar que los archivos `android/app/google-services.json` y `lib/firebase_options.dart` existan en el proyecto clonado.

Si no están presentes, deben solicitarse al equipo de desarrollo, ya que contienen la configuración de conexión del proyecto.

---

# Configuración de un proyecto Firebase propio

Si se desea o necesita conectar la aplicación a un proyecto Firebase propio en lugar del incluido en el repositorio, seguir estos pasos.

### 0. Crear una cuenta de Firebase

Si ya se dispone de una cuenta de Google, se puede saltar directamente al paso 1.

Firebase utiliza cuentas de Google. Si no se tiene una, crear una desde:

https://accounts.google.com/signup

Una vez creada la cuenta:

1. Ir a https://firebase.google.com.
2. Hacer clic en "Comenzar" o "Get started".
3. Iniciar sesión con la cuenta de Google.
4. Se redirigirá a Firebase Console: https://console.firebase.google.com.

### 1. Instalar herramientas necesarias

Primero se debe instalar Firebase CLI y FlutterFire CLI.

Ejecutar:

```bash
npm install -g firebase-tools
```

```bash
dart pub global activate flutterfire_cli
```

Si no se tiene Node.js instalado (necesario para el primer comando), descargarlo desde https://nodejs.org e instalarlo antes de continuar.

### 2. Iniciar sesión en Firebase

Ejecutar:

```bash
firebase login
```

Este comando abrirá una ventana en el navegador para iniciar sesión con una cuenta de Google que tenga acceso a Firebase. Aceptar los permisos solicitados.

### 3. Activar el plan Blaze en Firebase

Esta aplicación utiliza Firebase Storage para guardar los PDFs y Trigger Email para enviar correos. Estos servicios requieren que el proyecto tenga activado el plan Blaze (pago por uso).

Activar el plan Blaze no significa que se cobrará dinero automáticamente. Firebase cobra según el uso de los servicios y los límites aplicables al proyecto. Se debe revisar la información de precios vigente antes de activar el plan.

Para activarlo:

1. Dentro del proyecto en https://console.firebase.google.com, ir a la sección de facturación.
2. Seleccionar el plan Blaze.
3. Seguir los pasos para ingresar los datos de pago.
4. Revisar las opciones de presupuesto y alertas de facturación disponibles.

Se recomienda configurar alertas de presupuesto para monitorear los gastos del proyecto.

### 4. Crear proyecto en Firebase Console

1. Ir a https://console.firebase.google.com.
2. Hacer clic en "Agregar proyecto" y seguir los pasos.
3. Una vez creado el proyecto, habilitar los siguientes servicios:

   - Authentication → Métodos de acceso → Correo/Contraseña → Activar.
   - Firestore Database → Crear base de datos → Seleccionar modo producción.
   - Storage → Comenzar → Configurar las reglas de seguridad correspondientes.

### 5. Configurar Trigger Email

Trigger Email es una extensión de Firebase que permite enviar correos electrónicos automáticamente cuando se agrega un documento a una colección de Firestore.

La aplicación la utiliza para enviar las cotizaciones en formato PDF al correo de los clientes.

Para instalarla:

1. En el menú lateral de Firebase Console, dirigirse a Extensions (Extensiones).
2. Hacer clic en explorar extensiones.
3. Buscar "Trigger Email from Firestore" y seleccionarla.
4. Hacer clic en instalar y seguir los pasos de configuración:

   - En el campo **Email documents collection**, ingresar exactamente:

     ```text
     historial_correos
     ```

   - En **SMTP connection URI**, ingresar las credenciales del servicio de correo que se utilizará para enviar los correos. Se recomienda Gmail con una contraseña de aplicación.
   - Ir a https://myaccount.google.com/apppasswords y generar una contraseña de aplicación. Para ello, debe estar habilitada la verificación en dos pasos de la cuenta de Google.
   - El formato de la URI es:

     ```text
     smtps://tucorreo@gmail.com:contraseña_de_app@ smtp.gmail.com:465
     ```

     Se debe eliminar el espacio antes de `smtp.gmail.com` al configurar el valor.

   - En **Default From address**, ingresar la dirección de correo desde donde se enviarán los correos de la aplicación.
   - En **OAuth2 SMTP Port** (opcional), se recomienda utilizar `465` si se trabajará con Gmail.

5. Hacer clic en "Instalar extensión" y esperar a que finalice el proceso.

### 6. Conectar el proyecto Flutter con Firebase

Dentro de la carpeta raíz del proyecto (donde se encuentra `pubspec.yaml`), ejecutar:

```bash
flutterfire configure
```

Este comando detecta automáticamente los proyectos de Firebase disponibles en la cuenta y muestra un menú para seleccionar cuál utilizar.

Al seleccionar el proyecto correcto, genera o actualiza los archivos de configuración correspondientes, incluyendo `firebase_options.dart` y, según la configuración de plataformas, los archivos nativos necesarios.

### 7. Ejecutar la aplicación

Si todos los pasos anteriores fueron ejecutados correctamente, la aplicación debería estar conectada al nuevo proyecto Firebase.

Ejecutar:

```bash
flutter pub get
```

Luego:

```bash
flutter run
```

A partir de este punto, la aplicación debería estar conectada al nuevo proyecto Firebase y utilizar su propia base de datos.

### 8. Configuración de reglas en Firestore

Para que el proyecto funcione correctamente con sus reglas de seguridad, pegar las siguientes reglas en Firebase Console → Firestore Database → Reglas:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    match /cliente/{clienteId} {
      allow read, delete: if request.auth != null;
      allow write: if request.auth != null;
    }

    match /cotizaciones/{cotizacionId} {
      allow read, delete, create: if request.auth != null;
      allow update: if request.auth != null &&
      request.resource.data.fechaCreacion == resource.data.get('fechaCreacion', null);
      allow delete: if false;
    }

    match /historial_correos/{document} {
      allow read, create: if request.auth != null;
      allow update, delete: if false;
    }

    match /contadores/{contadorId} {
      allow read, update: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

---

## Configuración de Firebase Storage y CORS para Flutter Web

### Problema identificado

Durante las pruebas de la aplicación en Flutter Web, se detectó que los documentos PDF almacenados en Firebase Storage no podían visualizarse correctamente desde el navegador.

Se presentaban errores como:

```text
There was an error opening this document.
```

Y posteriormente:

```text
ClientException: Failed to fetch
```

El problema se relacionaba con las restricciones CORS (Cross-Origin Resource Sharing) al realizar solicitudes desde el navegador hacia Firebase Storage.

### Solución implementada

Se configuró CORS directamente en el bucket de Firebase Storage utilizando Google Cloud CLI.

**Bucket utilizado:**

```text
proyecto-desarrollo-movi-47954.firebasestorage.app
```

### 1. Instalar Google Cloud CLI

Descargar e instalar Google Cloud CLI desde:

https://cloud.google.com/sdk/docs/install

Una vez instalado, comprobar su funcionamiento:

```powershell
gcloud --version
```

### 2. Autenticarse y seleccionar el proyecto

Ejecutar:

```powershell
gcloud init
```

Durante la configuración:

- Seleccionar la cuenta de Google que tenga permisos para administrar el bucket.
- Seleccionar el proyecto Firebase correspondiente.
- No es necesario configurar una región ni zona de Compute Engine para esta operación.

Para comprobar el proyecto activo:

```powershell
gcloud config get-value project
```

### 3. Crear el archivo cors.json

En la raíz del proyecto, crear un archivo llamado `cors.json` con el siguiente contenido:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "responseHeader": [
      "Content-Type",
      "Content-Length",
      "Content-Range",
      "Accept-Ranges"
    ],
    "maxAgeSeconds": 3600
  }
]
```

**Descripción de los parámetros:**

| Parámetro | Descripción |
|---|---|
| origin | Orígenes desde los cuales se permiten solicitudes CORS. |
| method | Métodos HTTP permitidos: GET y HEAD. |
| responseHeader | Encabezados de respuesta expuestos al navegador. |
| maxAgeSeconds | Tiempo de caché de la configuración CORS, expresado en segundos. |

### 4. Aplicar la configuración al bucket

Desde PowerShell, ubicado en la carpeta donde se encuentra `cors.json`, ejecutar:

```powershell
gcloud storage buckets update gs://proyecto-desarrollo-movi-47954.firebasestorage.app --cors-file=cors.json
```

### 5. Verificar la configuración

Ejecutar:

```powershell
gcloud storage buckets describe gs://proyecto-desarrollo-movi-47954.firebasestorage.app --format="default(cors_config)"
```

La configuración debe mostrar los métodos `GET` y `HEAD`, el origen configurado y los encabezados correspondientes.

### 6. Resultado obtenido

Después de aplicar y verificar la configuración CORS, se volvió a ejecutar la aplicación Flutter Web.

Se comprobó que el documento PDF de la cotización `CT-019` podía visualizarse correctamente desde el navegador.

**Estado:** configuración aplicada y visualización de PDF verificada en el entorno de desarrollo.

### 7. Consideraciones de seguridad

- CORS no hace públicos los documentos ni reemplaza las reglas de seguridad de Firebase Storage.
- Las reglas de Storage deben seguir exigiendo autenticación para las operaciones protegidas.
- La configuración utilizada con `origin: ["*"]` se aplicó para facilitar las pruebas de desarrollo.
- Antes de desplegar la aplicación en producción, se debe reemplazar `*` por el dominio real autorizado.

Ejemplo:

```json
"origin": ["https://midominio.cl"]
```

Si la aplicación utiliza más de un dominio autorizado, se deben agregar los orígenes correspondientes.

Después de modificar `cors.json`, volver a aplicar la configuración al bucket utilizando el comando de actualización indicado anteriormente.

**Importante:** la configuración CORS se administra directamente en Google Cloud Storage. Guardar `cors.json` en el repositorio permite conservar y reproducir la configuración, pero no significa que se aplique automáticamente al desplegar la aplicación.