import 'package:flutter/material.dart';

final RegExp passwordValidator = RegExp(
  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#\$&*~`^%+=_-]).{8,}$',
);

class LoginForm extends StatelessWidget {
  // --- VARIABLES ---
  // Recibimos los controladores desde la pantalla padre para poder leer el texto.
  final GlobalKey<FormState>
  formKey; // La llave maestra para validar todo el formulario
  final TextEditingController emailController;
  final TextEditingController passwordController;
  // Estado visual recibido desde la pantalla padre
  final bool
  obscurePassword; // ¿Se ven los puntitos o el texto de la contraseña?
  // --- ACCIONES (CALLBACKS) ---
  // Funciones que se ejecutan cuando el usuario toca un botón.
  // El widget padre decide qué hacen estas funciones (llamar a la API, navegar, etc.).
  final VoidCallback onLogin;
  final VoidCallback onToggleObscure; // Muestra/Oculta contraseña
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onLogin,
    required this.onToggleObscure,
    required this.onForgotPassword,
    required this.onRegister,
  });

  // Validaciones
  // Comprueba si el email tiene formato correcto (a@b.c)
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, introduce tu email.';
    }
    // Expresión regular estándar para emails
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Introduce un formato de email válido.';
    }
    return null; // Null significa que no hay error
  }

  // Comprueba la seguridad de la contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, introduce tu contraseña.';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (!passwordValidator.hasMatch(value)) {
      return 'Debe incluir: mayúscula, minúscula y símbolo.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0), // Relleno interno
      decoration: BoxDecoration(
        color: Colors.white, // Fondo blanco
        borderRadius: BorderRadius.circular(20.0), // Bordes redondos
        boxShadow: [
          // Sombra sutil
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3), // Sombra hacia abajo
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 400), // Ancho máximo compacto
      //Formulario principal login
      child: Form(
        key: formKey, // Vincula la validación a este widget
        child: Column(
          mainAxisSize: MainAxisSize.min, // Se ajusta al tamaño del contenido
          children: [
            // --- Logotipo ---
            const Icon(Icons.lock_open, size: 80, color: Colors.blue),
            const SizedBox(height: 30),

            // --- Input de Email (TextFormField con validador) ---
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType
                  .emailAddress, // Teclado optimizado para emails (@)
              validator: _validateEmail, // Llama al validador de Email
              decoration: InputDecoration(
                hintText: 'Introduce email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                ),
                prefixIcon: const Icon(Icons.email, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),

            // --- Input de Contraseña (TextFormField con validador) ---
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Contraseña',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              validator: _validatePassword, // Llama al validador de Contraseña
              decoration: InputDecoration(
                hintText: 'Introduce contraseña',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                ),
                prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blue,
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Botón de Iniciar Sesión (compacto y centrado) ---
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed:
                    onLogin, // Esta función dispara la validación en LoginPage
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'INICIAR SESIÓN',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // --- Enlace Olvidé Contraseña ---
            TextButton(
              onPressed: onForgotPassword,
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            // --- Enlace Registrarse ---
            TextButton(
              onPressed: onRegister,
              child: const Text(
                '¿No tienes cuenta? Regístrate aquí',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
