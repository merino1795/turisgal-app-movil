import 'dart:async'; // Necesario para el Timer
import 'package:flutter/material.dart';
import '../login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Duración del Splash Screen en milisegundos (2.5 segundos)
  final int splashDuration = 3000;

  @override
  void initState() {
    super.initState();

    // ESTE ES EL CÓDIGO CLAVE que replica el setTimeout de JavaScript
    Timer(Duration(milliseconds: splashDuration), () {
      // Navegación una vez que el temporizador ha terminado

      // 1. Obtiene el contexto actual para la navegación
      final context = this.context;

      // 2. Navega a la pantalla de Login (reemplazando el Splash Screen)
      // Nota: Debe usar su ruta de Login real. Usaré una simulación simple.

      // Asegúrese de que el contexto sigue siendo válido si el widget no se ha desmontado
      if (mounted) {
        // Ejemplo de navegación real en Flutter (usando MaterialPageRoute)

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ), // Reemplace 'LoginScreen()' por su widget de Login
        );

        // Simulación de una simple navegación para fines de demostración
        print("Tiempo de Splash terminado. Navegando a Login.");
        // Si el usuario ya estuviera logueado, aquí se navegaría a la pantalla principal.
      }
    });
  }

  // El método build define la apariencia (el logo y el fondo azul)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        203,
        234,
        243,
      ), // El color azul de Turigal
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo-turisgal.png',
              width: 450,
              height: 450,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  color: Colors.white,
                  child: const Center(
                    child: Text(
                      'Error: Logo no encontrado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF0077b6)),
                    ),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: Text(
                '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
