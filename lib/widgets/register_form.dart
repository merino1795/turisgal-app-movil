import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Regex para validar contraseña segura
final RegExp passwordValidator = RegExp(
  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#\$&*~`^%+=_-]).{8,}$',
);

class RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  // Controladores para capturar lo que escribe el usuario
  final TextEditingController nameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  // Callbacks para la lógica de negocio
  final VoidCallback onRegister;
  final VoidCallback onToggleObscure;
  final VoidCallback onBackToLogin;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.lastNameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onRegister,
    required this.onToggleObscure,
    required this.onBackToLogin,
  });

  // Validador de Teléfono: 9 dígitos y solo números
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, introduce tu teléfono.';
    }
    // Verifica que solo contenga dígitos
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'El teléfono solo puede contener números.';
    }
    // Verifica longitud mínima
    if (value.length < 9) {
      return 'El teléfono debe tener al menos 9 dígitos.';
    }
    return null;
  }

  // Validador de Email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, introduce tu email.';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Introduce un formato de email válido.';
    }
    return null;
  }

  // Validador de Contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, introduce tu contraseña.';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (!passwordValidator.hasMatch(value)) {
      return 'Debe incluir: mayúscula, minúscula y un símbolo especial.';
    }
    return null;
  }

  // Validador de campos de texto simple (Nombre/Apellido, obligatorios)
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Logotipo ---
            const Icon(Icons.person_add, size: 60, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Crea tu Cuenta',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),

            // Campos de texto reutilizando un método auxiliar _buildInputField
            // --- Input de Nombre ---
            _buildInputField(
              'Nombre',
              nameController,
              Icons.person_outline,
              _validateName,
              TextInputType.name,
            ),
            const SizedBox(height: 15),

            // --- Input de Apellidos ---
            _buildInputField(
              'Apellidos',
              lastNameController,
              Icons.person_outline,
              _validateName,
              TextInputType.name,
            ),
            const SizedBox(height: 15),

            // --- Input de Teléfono ---
            _buildInputField(
              'Teléfono',
              phoneController,
              Icons.phone,
              _validatePhone,
              TextInputType.phone,
              isNumeric: true,
            ), // NUEVO
            const SizedBox(height: 15),

            // --- Input de Email ---
            _buildInputField(
              'Email',
              emailController,
              Icons.email,
              _validateEmail,
              TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),

            // --- Input de Contraseña ---
            _buildPasswordField(),
            const SizedBox(height: 30),

            // --- Botón de Registrarse ---
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: onRegister, //Envia el formulario
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'REGISTRARME',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // --- Enlace Volver al Login ---
            TextButton(
              onPressed: onBackToLogin,
              child: const Text(
                '¿Ya tienes cuenta? Inicia Sesión',
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

  // Widget auxiliar para crear campos de texto estándar
  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    String? Function(String?) validator,
    TextInputType keyboardType, {
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          // Si es numérico, impedimos escribir letras
          inputFormatters: isNumeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: 'Introduce $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.blue, width: 2.0),
            ),
            prefixIcon: Icon(icon, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  // Widget auxiliar específico para la contraseña
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contraseña',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          validator: _validatePassword,
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
      ],
    );
  }
}
