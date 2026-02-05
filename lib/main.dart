import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Gestión de estado global
import 'package:flutter/services.dart'; // Para controlar la orientación o barra de estado (opcional)

// --- SERVICIOS ---
import 'package:turigal/services/auth_service.dart'; // Maneja Login/Registro/Logout
import 'package:turigal/services/api_service.dart'; // Maneja la conexión con el Backend

// --- PANTALLAS (Widgets de página completa) ---
import 'package:turigal/widgets/splash_screen.dart'; // Pantalla de carga inicial
import 'login_page.dart';
import 'register_page.dart';
import 'forgot_password_page.dart'; // Recuperación de contraseña
import 'update_password_page.dart'; // Cambio de contraseña (Paso final)
import 'contact_page.dart';
import 'home_page.dart'; // Pantalla Principal
import 'profile_page.dart';
import 'checking_page.dart'; // Escaneo de QR
import 'identity_verification_page.dart'; // Fotos DNI/Selfie
import 'signature_page.dart'; // Firma Digital
import 'my_reservation_screen.dart'; // Lista de reservas

// --- WIDGETS DE FUNCIONALIDAD ---
import 'package:turigal/widgets/check-out.dart'; // Pantalla de salida

// Punto de entrada de la aplicación Dart
void main() async {
  // 1. Aseguramos que el motor de Flutter esté listo antes de ejecutar código asíncrono
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializamos el Servicio API para intentar recuperar la sesión del usuario (si existe token guardado)
  final apiService = ApiService();
  await apiService.initUser(); // Carga userId y token de SharedPreferences

  // 3. Lanzamos la aplicación visual
  runApp(
    MultiProvider(
      providers: [
        // Inyectamos AuthService en toda la app para que cualquier widget sepa si el usuario está logueado
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Quita la etiqueta "DEBUG" de la esquina superior derecha
      debugShowCheckedModeBanner: false,
      title: 'Turisgal App',

      // --- TEMA GLOBAL ---
      theme: ThemeData(
        primarySwatch: Colors.blue, // Color principal
        scaffoldBackgroundColor:
            Colors.blue.shade50, // Fondo azul claro por defecto
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Estilo global para botones elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),

      // --- RUTAS DE NAVEGACIÓN ---
      // '/' es la primera ruta que se carga. SplashScreen decide si ir a Login o Home.
      initialRoute: '/',

      // Mapa de rutas estáticas (sin argumentos complejos)
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/reservations': (context) =>
            const MyReservationsScreen(), // Ojo con el nombre de la clase
        '/checkin': (context) =>
            const CheckInPage(), // Paso 1 del Check-in (QR)
        '/contact': (context) => const ContactPage(),
      },

      // --- GENERADOR DE RUTAS DINÁMICAS (onGenerateRoute) ---
      // Se usa cuando necesitamos pasar argumentos (datos) de una pantalla a otra.
      onGenerateRoute: (settings) {
        // 1. RUTA: ACTUALIZAR CONTRASEÑA
        // Necesita recibir el 'email' para saber a quién cambiarle la clave.
        if (settings.name == '/update-password') {
          final args = settings.arguments;
          // Validamos que los argumentos sean un Mapa y contengan el email
          if (args is Map<String, dynamic> && args.containsKey('email')) {
            return MaterialPageRoute(
              builder: (context) => UpdatePasswordPage(email: args['email']),
            );
          }
          // Si faltan datos, volvemos al login por seguridad
          return MaterialPageRoute(builder: (context) => const LoginPage());
        }

        // 2. RUTA: CHECK-OUT
        // Necesita el 'reservationId' para saber qué reserva cerrar.
        if (settings.name == '/checkout') {
          final args = settings.arguments;
          if (args is Map<String, dynamic> &&
              args.containsKey('reservationId')) {
            return MaterialPageRoute(
              builder: (context) =>
                  CheckoutScreen(reservationId: args['reservationId']),
            );
          }
          // Si falla, volver a Home
          return MaterialPageRoute(builder: (context) => const HomePage());
        }

        // 3. RUTA: VERIFICACIÓN DE IDENTIDAD (Check-in Paso 2)
        // Necesita 'reservationId' y opcionalmente 'guestName'.
        if (settings.name == '/checkin/verify-identity') {
          final args = settings.arguments;
          // Validación flexible: Permitimos que guestName sea opcional
          if (args is Map<String, dynamic> &&
              args.containsKey('reservationId')) {
            return MaterialPageRoute(
              builder: (context) {
                return const IdentityVerificationPage();
              },
              settings:
                  settings, // IMPORTANTE: Pasar los settings para que ModalRoute funcione dentro
            );
          }
          return MaterialPageRoute(builder: (context) => const CheckInPage());
        }

        // 4. RUTA: FIRMA DIGITAL (Check-in Paso 3)
        // Necesita 'reservationId'.
        if (settings.name == '/checkin/signature') {
          final args = settings.arguments;
          if (args is Map<String, dynamic> &&
              args.containsKey('reservationId')) {
            return MaterialPageRoute(
              builder: (context) => SignaturePage(
                reservationId: args['reservationId'],
              ), // Igual que arriba, lee args internamente
              settings: settings,
            );
          }
          return MaterialPageRoute(builder: (context) => const CheckInPage());
        }

        // Si la ruta no coincide con ninguna, devolvemos null (Flutter usará onUnknownRoute)
        return null;
      },

      // --- RUTA DESCONOCIDA (Fallback) ---
      // Si intentamos navegar a una ruta que no existe, decidimos a dónde ir.
      onUnknownRoute: (settings) {
        // Obtenemos el servicio de Auth sin escuchar cambios (listen: false)
        // Esto puede dar error si el contexto no está listo, así que mejor usamos una ruta segura por defecto.
        return MaterialPageRoute(builder: (context) => const LoginPage());
      },
    );
  }
}
