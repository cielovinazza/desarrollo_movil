Sistema de cotizaciones- Flutter+Firebase

La aplicación móvil "CotizApp" desarrollada en Flutter está destinada para la gestión integral de cotizaciones de proyectos de pintura/construcción. Permite crear, editar, previsualizar y enviar cotizaciones mediante archivos PDF a clientes (tambien registrados dentro de la misma app). Posee soporte offline y sincronizacion automatica con Firebase.

## Librerias utilizadas

Libreria                Versión         Uso
flutter (SDK)             ^3.11.1        Framework principal
firebase_core             ^4.10.0        Inicialización de firebase
firebase_auth             ^6.5.2         Autenticación de usuarios 
cloud_firestore           ^6.4.1         Base de datos en tiempo real
firebase_storage          ^13.4.1        Almacenamiento de archivos PDF (requiere plan blaze de firebase)
pdf                       ^3.12.0        Generación de documentos PDF
printing                  ^5.14.3        Previsualización e impresión de PDFs
path_provider             ^2.1.5         Acceso a rutas del sistema de archivos
intl                      ^0.20.2        Formateo de fechas y montos en CLP
url_launcher              ^6.3.0         Apertura de urls externas
syncfusion_flutter_pdfViewer ^28.2.7     Visualizacion de Pdfs en la app
share_plus                 ^12.0.2       Compartir archivos desde la app (por app de mensajes)
file_picker                ^8.0.0        importación de archivos csv (materiales para esta app)
shared_preferences         ^2.3.2        Almacenamiento local de borradores y documentos offline
connectivity_plus          ^7.1.1        Detección de estado de red (online/offline)
cupertino_icons            ^1.0.8        Iconos estilo IOS

## Requisitos previos para el uso correcto de la app
• FlutterSDK ^3.11.1
• Android Studio o VS code con extensión de flutter
• Dart SDK (incluido con flutter, pero recomendable confirmar instalación en extensiones de VS code)
• Dispositivo android o emulador (sirve emulador de android studio)

## Instalación 
## 1.Clonar repositorio de github

previamente se debe tener instalado gitbash para windows, una vez instalado gitbash abra una terminal y ejecute los comandos: 
git clone https://github.com/cielovinazza/desarrollo_movil
cd desarollo_movil

## 2. Instalar dependencias
dentro de la carpeta del proyecto ejecute el comando:
flutter pub get (esto instala automaticamente las librerias escritas en pubspec.yaml)

## 3. Verificar entorno
flutter doctor
este comando es para confirmar que está todo correctamente configurado (flutter, sdk, android studio, visual studio, etc) Todos los items deben aparecer con un ticket, si alguno muestra un error, siga las instrucciones mostradas en pantalla por la terminal.

## 4. Conectar un dispositivo
Opcion A: puede utilizar un dispositivo android fisico, para ello antes debe activar las opciones de desarrollador (tocar 7 veces el numero de compilación en "Acerca del télefono" en configuraciones) y activar la depuracion por USB (o inalambrica si lo prefiere)

Opcion B: usar un emulador, puede utilizar un emulador de android studio (Device Manager → create device → seleccionar un dispositivo con API21 o superior y crearlo → iniciar el emulador)

para verificar que su dispositivo está conectado ejecute el comando: flutter devices

luego ejecute la aplicación con el comando: flutter run, si todo está preconfigurado correctamente, la app se abrirá automaticamente en su dispositivo o emulador

5. Generar APK de release (opcional)
si desea generar un apk instalable sin necesidad de utilizar android studio o tener activada la depuración siempre, ejecute el comando:

flutter build apk --release

luego busque la app en el directorio "build/app/outputs/flutter-apk/app-release.apk" dentro de la carpeta del proyecto y copie el archivo .apk directamente en el dispositivo fisico (debe tener habilitada la instalación de apps de fuentes desconocidas, si no lo tiene habilitelo en Ajustes → Seguridad)

## Backend - Firebase
El backend de la app está completamente gestionado por Firebase (servicio de Google). No requiere servidor propio ni infraestructura adicional.

Servicios Utilizados

•Firebase Authentication: login y gestión de sesiones de usuario mediante correo y contraseña (administrada/creada desde la consola de firebase)
•Cloud Firestore: base de datos NoSQL, donde se almacenan las cotizaciones, clientes, historial de correos enviados y contadores.
•Firebase Storage: sistema de almacenamiento en la nube para archivos PDF generados por la app
•Trigger Email(extensión): permite el envío automatico de pdfs al correo de los clientes, tambien escribe los datos en la coleccion historial_correos.

Estructura de la base de datos:
cotizaciones/
  {cotizacionId}/
    - id
    - codigo                  (distinto de id, ej: "CT-001", o "CT-001-V2" si fue rechazada y reeditada)
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

contadores/
  cotizaciones/
    - ultimoNumero            (genera códigos correlativos CT-001, CT-002, ...)

historial_correos/
  {docId}/
    - to                      (email del cliente)
    - message/
        - subject
        - html
        - attachments[]       (filename, path con URL del PDF en Storage)

## Como conectarse a Firebase

Dentro de la carpeta android/app/ de este proyecto, existe un archivo llamado google-services.json, el cual contiene toda la configuración necesaria para que la app se conecte automaticamente al proyecto Firebase donde están almacenados los datos. Este archivo fue generado de manera automatica por Firebase al momento de integrar el servicio al proyecto y ya está incluido en el repositorio, por lo que simplemente basta con clonar el repositorio para conectarse a Firebase sin necesidad de realizar ninguna configuración adicional ni instalar herramientas extra para que funcione. 

De la misma manera existe un archivo llamado firebase_options.dart dentro de la carpeta lib/ que Flutter utiliza internamente para inicializar la conexión con Firebase al arrancar la app. Este archivo al igual que google-services.json ya está incluido en el repositorio.

En resumen: al clonar el repositorio y ejecutar flutter run, la app ya se conecta a Firebase automáticamente. No se requiere ningún paso adicional.

## Importante: si al ejecutar la app aparece un error relacionado con Firebase (por ejemplo, FirebaseException o google-services.json not found), verificar que los archivos android/app/google-services.json y lib/firebase_options.dart existen en el proyecto clonado. Si no están presentes, deben solicitarse al equipo de desarrollo ya que contienen credenciales del proyecto.

Si se desea/necesita conectar la app a un proyecto Firebase propio en lugar del incluido en el repositorio, siga estos pasos:

## 0. Crear una cuenta de firebase (si ya tiene una, salte directamente al paso 1)
Firebase es un servicio de Google, por lo que se accede con una cuenta de Google (la misma que se usa para Gmail, YouTube, etc.). Si no se tiene una cuenta de Google, primero crear una en https://accounts.google.com/signup.

Una vez que se tiene la cuenta de Google:

Ir a https://firebase.google.com
Hacer clic en el botón "Comenzar" o "Get started" en la esquina superior derecha
Iniciar sesión con la cuenta de Google
Se redirigirá automáticamente a la consola de Firebase en https://console.firebase.google.com, donde ya se puede crear y administrar proyectos

## 1. Instalar herramientas necesarias
primero, se debe instalar la CLI de Firebase y la herramienta FlutterFire. Para ello abra una terminal y ejecute los comandos:

npm install -g firebase-tools

dart pub global activate flutterfire_cli

(Si no tiene Node.js instalado (necesario para el primer comando), descárgalo desde https://nodejs.org e instalelo antes de continuar.)

## 2. Iniciar sesión en Firebase
ejecute el comando firebase login
este comando abrirá una ventana en el navegador pidiendo iniciar sesión con su cuenta de google con acceso a Firebase. Acepte los permisos solicitados. (si no tiene una cuenta en firebase siga los pasos del punto 0)

## 3. Activar el plan Blaze en Firebase

Esta aplicación utiliza Firebase Storage (para guardar los PDFs) y Trigger Email (para enviar correos). Ambos servicios requieren que el proyecto tenga activado el plan Blaze (pago por uso), ya que no están disponibles en el plan gratuito Spark.

Importante: activar el plan Blaze no significa que se va a cobrar dinero automáticamente. Firebase solo cobra si el uso supera los límites gratuitos incluidos en el plan, los cuales son bastante generosos para una aplicación de uso normal (para que empiece a cobrar la cantidad de lecturas debe superar las 50 mil por dia y las escrituras y eliminaciones deben superar las 20.000 por dia y en storage se debe superar los 5GB en archivos, sin embargo los PDFs no suelen pesar mas de 10mb cada uno). Sin embargo, sí es necesario registrar una tarjeta de crédito o débito para habilitarlo.

Para activarlo:

Dentro del proyecto en https://console.firebase.google.com, ir a la esquina inferior izquierda donde dice "Spark" y hacer clic en "Actualizar"
Seleccionar el plan Blaze y seguir los pasos para ingresar los datos de pago
Se recomienda configurar un presupuesto de seguridad para evitar sorpresas: durante el proceso de activación, Firebase ofrece la opción de establecer un límite de gasto mensual. Al alcanzar ese límite, Firebase envía una notificación por correo. Establecer un valor bajo (por ejemplo, $1 o $5 CLP) es suficiente como medida de seguridad.

## 4. Crear proyecto en Firebase Console 
1. ir a https://console.firebase.google.com
2. Hacer click en "Agregar proyecto" y seguir los pasos
3. Una vez creado el proyecto, debe habilitar los siguientes servicios desde el menú lateral:
  • Authentication → Métodos de acceso → Correo/Contraseña → Activar
  • Firestore Database → Crear base de datos → Seleccionar Modo producción
  • Storage → Comenzar → Aceptar las reglas por defecto

## 5. Configurar Trigger Email
Trigger email es una extensión de firebase que permite enviar correos electronicos de forma automatica cuando se agrega un documento a una colección de Firestore. Está app la utiliza para enviar las cotizaciones en formato PDF al correo de los clientes.

Para instalarla:
1. En el menú lateral de Firebase Console, dirijase a "Extensions (o extensiones si lo tiene en español)"
2. Hacer click en explorar extensiones.
3. Buscar "Trigger Email from Firestore" y seleccionarla
4. Hacer click en instalar y seguir los pasos de configuración:
  • En el campo "Email documents collection", ingrese EXACTAMENTE historial_correos
  • En la sección "SMTP connection URI" ingrese las credenciales del servicio de correo que usará para enviar los correos. Se recomienda usar gmail con una contraseña de aplicación:
    • Ir a https://myaccount.google.com/apppasswords y genera una contraseña de aplicación
    IMPORTANTE: para poder generar la contraseña de aplicación debe tener habilitada en su cuenta de google la verificación en dos pasos
    • El formato de la URI (campo donde debe escribir) es smtps://tucorreo@gmail.com:contraseña_de_app(sin espacios)@smtp.gmail.com:465
    • En el campo "Default From address" ponga la dirección de correo desde donde quiere que se envíen los correos de la app.
    • En el campo OAuth2 SMTP Port(opcional) se recomienda poner 465 si trabajará con gmail (a pesar de ser opcional)
5. Hacer click en "Instalar Extensión" y esperar a que finalice la instalación (esto puede tardar algunos minutos)

## 6. Conectar el proyecto flutter con Firebase
Dentro de la carpeta raiz del proyecto (donde está el archivo pubspec.yaml) ejecute el comando:

flutterfire configure

Este comando detecta automaticamente los proyectos de Firebase disponibles en la cuenta y muestra un menú para seleccionar cual utilizar. Al seleccionar el proyecto correcto, el comando reemplaza automaticamente los archivos "google-services.json" y "firebase_options.dart" con los del nuevo proyecto. No es necesario que copie ni mueva los archivos manualmente.

## 7. Ejecutar la app
Si todos los pasos anteriores fueron ejecutados correctamente, deberia poder levantar la app en su propio entorno de firebase, para ello utilice antes el comando: 

flutter pub get (para instalar las dependencias de pubspec.yaml y evitar conflictos)

y luego ejecute el comando:

flutter run

A partir de este punto, la app deberia estar conectada a su nuevo proyecto de Firebase, con su propia base de datos.
