import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../services/auth_service.dart'; //Servicio de autenticacion
import '/widgets/forgot_password_form.dart'; // Widget del formulario
// Importamos la página de actualización
import 'update_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Clave global para validar el formulario
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  // Estado para manejar el PIN del servidor (en un entorno real, el PIN se envía por email/SMS)
  // Aquí lo guardamos para verificarlo localmente si el backend lo devuelve en modo debug
  String? _serverPin;
  bool _pinSent = false; // Indica si el PIN ha sido enviado

  // Nuevo estado para gestionar la carga/espera de la red
  bool _isLoading = false;

  @override
  void dispose() {
    // Limpieza de controladores
    _emailController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // --- Helpers de validacion ---
  // Validador de Teléfono (al menos 9 dígitos numéricos)
  bool _isValidPhone() {
    final phoneText = _phoneController.text;
    if (phoneText.isEmpty) return false;
    return RegExp(
      r'^[0-9]{9,}$',
    ).hasMatch(phoneText.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  // Validador de Email (formato básico)
  bool _isValidEmail() {
    final emailText = _emailController.text;
    if (emailText.isEmpty) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailText);
  }

  // Función para mostrar la Alerta Modal
  void _showAlert(
    String title,
    String content,
    Color titleColor, {
    VoidCallback? onAccept,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
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
                Navigator.of(context).pop(); //Cierra el diálogo

                // Ejecuta la acción posterior si existe (con un pequeño delay para asegurar cierre)
                if (onAccept != null) {
                  Future.delayed(
                    const Duration(milliseconds: 100),
                    () => onAccept(),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Lógica Principal ---
  // Paso 1: Solicitar el PIN al servidor
  void _sendPinToEmail() async {
    // Si ya estamos cargando, ignoramos el clic para evitar múltiples solicitudes
    if (_isLoading) return;

    // 1. Validación local (UI)
    if (!_formKey.currentState!.validate()) {
      _showAlert(
        'Validación Requerida',
        'Por favor, asegúrate de que el Email y Teléfono cumplen el formato.',
        Colors.red,
      );
      return;
    }

    // 2. Activar carga y preparar datos
    setState(() {
      _isLoading = true;
      _pinSent = false;
      _serverPin = null;
    });

    // Obtener instancia del servicio de autenticación
    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text;
    final phone = _phoneController.text;

    try {
      // 3. Llamamos al servicio. Esperamos un String (el PIN) si el backend lo devuelve (debug)
      // En producción, el backend enviaría el email y devolvería solo "OK".
      final actualPin = await authService.requestPasswordReset(
        email: email,
        phone: phone,
      );

      // 4. Éxito: Usamos el PIN real devuelto por el servidor
      setState(() {
        _serverPin = actualPin; // Guardamos el PIN para verificación local
        _pinSent = true;
        _pinController.clear();
        debugPrint('PIN REAL DEVUELTO DEL SERVIDOR: $actualPin');
      });

      _showAlert(
        'PIN Solicitado (Simulado)',
        '¡Usuario verificado! El PIN ha sido generado y enviado al email.\n\n'
            '🔑 **PIN DE PRUEBA: $actualPin** \n\n' // Muestra el PIN real
            'Úsalo en el campo de verificación para continuar.',
        Colors.green, // Usar verde para éxito
      );
    } on Exception catch (e) {
      // 5. Error: Mostrar el mensaje de error del servicio
      _showAlert(
        'Atención',
        // Limpiamos el prefijo 'Exception: ' para mostrar el mensaje de error del backend o la red
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
      setState(() {
        _pinSent = false; // No se envió el PIN
        _serverPin = null; // Limpiamos el PIN almacenado
      });
    } finally {
      // 6. Desactivar la carga siempre
      setState(() {
        _isLoading = false; // Desactivamos la carga
      });
    }
  }

  // Paso 2: Intentar verificar el PIN y actualizar la contraseña (se mantiene la lógica local)
  void _verifyPinAndNavigate() async {
    final enteredPin = _pinController.text;
    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text;

    if (_pinSent == false) {
      _showAlert(
        'PIN No Solicitado',
        'Primero debes solicitar el PIN con el botón "ENVIAR PIN".',
        Colors.blue,
      );
      return;
    }

    if (!_formKey.currentState!.validate() || enteredPin.isEmpty) {
      _showAlert(
        'Campo PIN Vacío',
        'Debes introducir el código PIN de 6 dígitos que recibiste.',
        Colors.red,
      );
      return;
    }

    // Verificación local rápida (si tenemos el PIN del servidor)
    if (_serverPin != null && enteredPin != _serverPin) {
      _showAlert(
        'PIN Erróneo',
        'El PIN introducido no coincide con el enviado a su correo electrónico.',
        Colors.red,
      );
      return;
    }

    // 1. Activar la carga
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Llamar al servicio para verificar el token real en el servidor
      // Esto obtiene la clave de reseteo (resetKey) necesaria para cambiar la contraseña
      await authService.verifyPasswordResetToken(
        email: email,
        token: enteredPin,
      );

      // 3. Éxito: Mostrar mensaje y navegar a la pantalla de Actualización
      _showAlert(
        'PIN Correcto',
        'El PIN ha sido verificado correctamente. Serás redirigido para cambiar tu contraseña.',
        Colors.green,
        onAccept: () {
          // CLAVE DEL CAMBIO: Navegamos a la pantalla de Actualizar Contraseña y pasamos el email.
          Navigator.of(context).pushReplacementNamed(
            '/update-password',
            arguments: {'email': email}, // Pasamos el email como argumento
          );
        },
      );
    } on Exception catch (e) {
      // 4. Error: Mostrar el mensaje de error del servicio
      _showAlert(
        'Error de Verificación',
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    } finally {
      // 5. Desactivar la carga
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recuperar Contraseña',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ForgotPasswordForm(
            formKey: _formKey,
            emailController: _emailController,
            phoneController: _phoneController,
            pinController: _pinController,
            pinSent: _pinSent,
            // Pasar el nuevo estado de carga al widget del formulario
            isLoading: _isLoading, // Nuevo parámetro
            onSendPin: _sendPinToEmail, // Llamada para enviar el PIN
            onUpdatePassword:
                _verifyPinAndNavigate, // Llamada para verificar el PIN
          ),
        ),
      ),
    );
  }
}
