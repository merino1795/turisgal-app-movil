Turisgal - App Móvil de Gestión Turística
Aplicación móvil desarrollada en Flutter para la gestión integral de reservas, check-in digital y servicios turísticos, respaldada por un backend en Node.js con Prisma ORM y PostgreSQL.
📋 Características Principales
-Módulo Móvil (Flutter)
  -Autenticación Segura: Login, registro, recuperación de contraseña y actualización de credenciales.
  -Check-in Digital:Escaneo de QR para validación de reservas (mobile_scanner).
  -Verificación de identidad (OCR) mediante carga de documentos.
  -Firma digital manuscrita en pantalla.
  -Gestión de Reservas: Visualización de reservas activas e históricas.
  -Check-out Automatizado: Reporte de salida con carga de evidencia fotográfica (incidencias, estado del inmueble).
  -Geolocalización: Mapas interactivos con flutter_map para ubicación de propiedades.
  -Comunicación: Chat integrado con soporte/anfitrión.
  -Perfil: Gestión de datos de usuario.
-Módulo Backend (Node.js)
  -API REST: Arquitectura modular con Express.js.
  -ORM: Prisma para modelado y migración de base de datos (PostgreSQL).
  -OCR: Procesamiento de imágenes con tesseract.js para validación de documentos.
  -Seguridad: Hashing con bcrypt, JWT para sesiones y middleware de autenticación.
  -Uploads: Gestión de archivos (fotos de check-out, documentos) con multer.
🛠 Tech Stack
-Frontend (App Móvil)
  -Framework: Flutter (SDK ^3.9.2)
  -Lenguaje: Dart
  -Gestión de Estado: Provider
  -Almacenamiento Local: Shared Preferences, Flutter Secure Storage
  -Librerías Clave: http, intl, image_picker, url_launcher, latlong2.
-Backend (API)
  -Runtime: Node.js
  -Framework: Express.js
  -Lenguaje: JavaScript / TypeScript
  -Base de Datos: PostgreSQL
  -ORM: Prisma
  -OCR Engine: Tesseract.js
🚀 Instalación y Configuración
Sigue estos pasos en orden para levantar el entorno de desarrollo completo.
1. Requisitos Previos
   -Flutter SDK instalado y configurado en el PATH.
   -Node.js (v18+ recomendado).
   -PostgreSQL corriendo localmente o una instancia en la nube.
   -Dispositivo físico o emulador (Android/iOS).
2. Configuración del Backend (turigal-backend)
   1. Navega al directorio del servidor:Bashcd turigal-backend
   2. Instala las dependencias:Bashnpm install
   3. Configura las variables de entorno. Crea un archivo .env en la raíz de turigal-backend con el siguiente contenido (ajusta según tu entorno):
      Fragmento de código
        PORT=3000
        DATABASE_URL="postgresql://usuario:password@localhost:5432/turisgal_db?schema=public"
        JWT_SECRET="tu_clave_secreta_jwt"
        # Añadir credenciales de correo si usas nodemailer
    4. Ejecuta las migraciones de Prisma para crear las tablas (User, Reservation, Checkin, etc.):
       Bash
         npx prisma migrate dev --name init
     5. Inicia el servidor en modo desarrollo:
        Bash
          npm run start:dev
        El servidor debería estar corriendo en http://localhost:3000.
3. Configuración del Frontend (/)
  1. Vuelve a la raíz del proyecto y asegura las dependencias de Flutter:
     Bash
       flutter pub get
  3. Configuración de API URL:Verifica el archivo lib/services/api_service.dart. Si estás probando en un emulador Android, asegúrate de que la URL base apunte a tu backend local.
       Emulador Android: http://10.0.2.2:3000/api
       iOS / Físico: http://<TU_IP_LOCAL>:3000/api
  4. Ejecuta la aplicación:
     Bash
       flutter run
📂 Estructura del Proyecto
Frontend (lib/)
  -main.dart: Punto de entrada. Inicialización de servicios y rutas.
  -services/: Lógica de negocio y comunicación HTTP (auth_service.dart, api_service.dart, checkin_service.dart).
  -widgets/: Componentes reutilizables (qr_scanner.dart, signature_page.dart, formularios).
  -*.dart: Pantallas principales en la raíz de lib/ (login_page.dart, home_page.dart, etc.).
Backend (turigal-backend/)
  -server.js: Entry point. Configuración de middlewares y rutas.
  -prisma/schema.prisma: Definición de modelos de BD (User, Checkin, Reservation, Review).
  -controllers/: Lógica de los endpoints.
  -routes/: Definición de rutas de la API.
  -middleware/: Middleware de autenticación (auth_middleware.js).
📡 Endpoints Principales (API)
    Método | Endpoint | Descripción
    AUTH | /api/auth/login | Iniciar sesión y obtener JWT.
    AUTH | /api/auth/register | Registrar nuevo usuario.
    CHECKIN | /api/checkin/validate | Validar reserva mediante QR/ID.
    CHECKIN | /api/checkin/ocr | Subir doc de identidad para análisis OCR.
    RESERVAS | /api/reservations | Listar reservas del usuario.
    CHECKOUT | /api/checkout | Finalizar estancia y subir fotos.
⚠️ Notas de Desarrollo
  -Assets: Las imágenes deben estar en assets/images/. Recuerda que pubspec.yaml ya incluye la referencia a esta carpeta.
  -Permisos:
    -Android: Revisa AndroidManifest.xml para permisos de Cámara (QR/Fotos), Internet y Geolocalización.
     -iOS: Revisa Info.plist para las claves NSCameraUsageDescription, NSPhotoLibraryUsageDescription y NSLocationWhenInUseUsageDescription.
