import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart'; // Servicio de autenticación

class UpdatePasswordPage extends StatefulWidget {
  final String email;

  const UpdatePasswordPage({super.key, required this.email});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  // Clave global para validar el formulario
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores de texto para capturar las contraseñas
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Estados visuales
  bool _obscurePassword = true; // Ocultar texto (pass 1)
  bool _obscureConfirmPassword = true; // Ocultar texto (pass 2)
  bool _isLoading = false; // Bloqueo durante la petición

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- UI: Alertas ---
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
                Navigator.of(context).pop();
                if (onAccept != null) {
                  // Pequeño retraso para asegurar que el diálogo se cerró visualmente
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

  // Toggle para mostrar/ocultar contraseñas
  void _toggleObscurePassword(bool isConfirmField) {
    setState(() {
      if (isConfirmField) {
        _obscureConfirmPassword = !_obscureConfirmPassword;
      } else {
        _obscurePassword = !_obscurePassword;
      }
    });
  }

  // --- VALIDACIONES DE FORMATO ---

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La confirmación es obligatoria.';
    }
    return null;
  }

  // Valida complejidad (Longitud, Mayúscula, Minúscula, Número, Símbolo)
  String? _checkPasswordRequirements(String password) {
    List<String> errors = [];

    if (password.length < 8) errors.add('• Mínimo 8 caracteres.');
    if (!RegExp(r'[A-Z]').hasMatch(password))
      errors.add('• Al menos una mayúscula.');
    if (!RegExp(r'[a-z]').hasMatch(password))
      errors.add('• Al menos una minúscula.');
    if (!RegExp(r'[0-9]').hasMatch(password))
      errors.add('• Al menos un número.');
    if (!RegExp(r'[!@#\$&*~`^%+=_-]').hasMatch(password))
      errors.add('• Al menos un símbolo (!@#\$%^&*)');

    if (errors.isNotEmpty) {
      return errors.join('\n');
    }
    return null;
  }

  // --- LÓGICA PRINCIPAL: ACTUALIZAR ---
  void _handlePasswordUpdate() async {
    if (_isLoading) return;

    // 1. Validar campos vacíos
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showAlert('Campos Incompletos', 'Rellena ambos campos.', Colors.red);
      return;
    }

    final newPassword = _passwordController.text;

    // 2. Validar REQUISITOS DE SEGURIDAD
    final requirementErrors = _checkPasswordRequirements(newPassword);
    if (requirementErrors != null) {
      _showAlert(
        'Seguridad Débil',
        'Tu contraseña debe cumplir:\n\n$requirementErrors',
        Colors.red,
      );
      return;
    }

    // 3. Validar COINCIDENCIA
    if (newPassword != _confirmPasswordController.text) {
      _showAlert('Error', 'Las contraseñas no coinciden.', Colors.red);
      return;
    }

    // 4. Iniciar Carga
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // 5. LLAMADA REAL A LA API
      // Enviamos email, nueva contraseña y la "resetKey" (que AuthService guardó en memoria en el paso anterior)
      await authService.updatePassword(
        email: widget.email,
        newPassword: newPassword,
      );

      // 6. Éxito
      _showAlert(
        'Contraseña Actualizada',
        'Tu contraseña se ha cambiado correctamente. Inicia sesión ahora.',
        Colors.green,
        onAccept: () {
          // Redirigir al Login y limpiar historial
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
      );
    } on Exception catch (e) {
      // 7. Error (Token expirado, error servidor)
      _showAlert(
        'Error',
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    } finally {
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
          'Nueva Contraseña',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset, size: 60, color: Colors.blue),
                  const SizedBox(height: 20),

                  const Text(
                    'Restablecer Contraseña',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Muestra el email del usuario para confirmar identidad
                  Text(
                    widget.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- INPUT 1: NUEVA CONTRASEÑA ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    keyboardType: TextInputType.visiblePassword,
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.vpn_key, color: Colors.blue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => _toggleObscurePassword(false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- INPUT 2: CONFIRMAR ---
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    keyboardType: TextInputType.visiblePassword,
                    validator: _validateConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.blue,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => _toggleObscurePassword(true),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- BOTÓN ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handlePasswordUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'CAMBIAR CONTRASEÑA',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
