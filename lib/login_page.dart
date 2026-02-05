import 'package:flutter/material.dart';
import '/widgets/login_form.dart'; // Importa el componente visual
import 'package:provider/provider.dart'; // Importamos Provider
import 'package:turigal/services/auth_service.dart';
import 'package:turigal/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // CLAVE GLOBAL para acceder y validar el Formulario
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores para obtener el texto de los inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Estado para controlar la visibilidad del campo de contraseña
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // FUNCIÓN PARA MOSTRAR LA ALERTA MODAL (AlertDialog)
  void _showAlert(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: Text(content),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Aceptar',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Función que se ejecuta al presionar el botón de Login
  Future<void> _handleLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final emailEmpty = email.isEmpty;
    final passwordEmpty = password.isEmpty;
    // SCENARIO 1: Ambos campos están vacíos
    if (emailEmpty && passwordEmpty) {
      if (mounted) {
        _showAlert(
          'Campos Requeridos',
          'Debes introducir email y contraseña para iniciar sesión.',
        );
      }

      return;
    }

    // SCENARIO 2: Validación de formato
    if (_formKey.currentState!.validate()) {
      // Éxito: Los formatos son correctos
      // Obtenemos la instancia del AuthService
      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        // 1. Llamada a la API de Login
        await authService.login(email: email, password: password);
        await ApiService().initUser();

        if (!mounted) return;

        // 2. Éxito: Navegar a la pantalla de inicio
        debugPrint(
          'LOG: Login exitoso para el email: $email. Navegando a /home',
        );

        // Usamos pushNamedAndRemoveUntil para limpiar el stack de navegación
        // IMPORTANTE: La ruta '/home' DEBE estar definida en main.dart
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
      } catch (e) {
        if (!mounted) return;
        // 3. Fallo: Mostrar alerta con el mensaje de error de la API
        debugPrint('LOG: Error al intentar iniciar sesión: ${e.toString()}');
        // Intentamos extraer el mensaje de error de la excepción
        final errorMessage = e.toString().contains(':')
            ? e.toString().split(':').last.trim()
            : 'Email o contraseña incorrectos. Verifica tu conexión.';

        _showAlert('Error de Credenciales', errorMessage);
      }
    } else {
      // Fracaso: Algún campo no cumple con el formato (además del mensaje inline)
      String errorContent = '';

      // La Regex está definida en login_form.dart, la volvemos a poner aquí para la lógica del modal
      final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      final RegExp passwordValidator = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#\$&*~`^%+=_-]).{8,}$',
      );

      // Comprobamos el email
      if (emailEmpty ||
          !emailEmpty && !emailRegex.hasMatch(_emailController.text)) {
        errorContent +=
            '• El email debe tener un formato válido (ejemplo@dominio.com).\n';
      }

      // Comprobamos la contraseña
      if (passwordEmpty ||
          !passwordEmpty &&
              !passwordValidator.hasMatch(_passwordController.text)) {
        if (errorContent.isNotEmpty) errorContent += '\n';
        errorContent +=
            '• La contraseña debe tener al menos 8 caracteres, incluyendo mayúscula, minúscula y un símbolo.';
      }

      if (mounted) {
        _showAlert(
          'Error de Validación',
          'Por favor, corrige lo siguiente:\n\n$errorContent',
        );
      }
    }
  }

  // Función para cambiar la visibilidad de la contraseña
  void _toggleObscurePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  // FUNCIÓN DE NAVEGACIÓN A REGISTRO
  void _navigateToRegister() {
    // Usamos pushNamed para ir a la ruta '/register'
    Navigator.of(context).pushNamed('/register');
  }

  // >>> FUNCIÓN DE NAVEGACIÓN A OLVIDÉ CONTRASEÑA (¡MODIFICACIÓN CLAVE!) <<<
  void _goToForgotPassword() {
    // Navega a la ruta '/forgot-password' definida en main.dart
    Navigator.of(context).pushNamed('/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    // El widget visual (formulario) recibe la lógica del State
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inicio de Sesión',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: LoginForm(
            formKey: _formKey, // Pasamos la clave al formulario
            emailController: _emailController,
            passwordController: _passwordController,
            obscurePassword: _obscurePassword,
            onLogin:
                _handleLogin, // Llama a la función que valida y muestra el alerta
            onToggleObscure: _toggleObscurePassword,
            // >>> AQUÍ USAMOS LA FUNCIÓN REAL DE NAVEGACIÓN <<<
            onForgotPassword: _goToForgotPassword,
            onRegister: _navigateToRegister, // Llama a la función de navegación
          ),
        ),
      ),
    );
  }
}
