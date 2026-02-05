import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importar provider para acceder al estado global
import 'package:turigal/services/auth_service.dart'; // Importar el servicio de autenticación
import '/widgets/register_form.dart'; // Widget del formulario visual

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 1. Clave Global para validar el formulario
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 2. Controladores de texto para capturar los datos
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 3. Estados de la interfaz
  bool _obscurePassword = true; // Visibilidad de contraseña
  bool _isLoading = false; // Bloqueo durante la petición a la API

  @override
  void dispose() {
    // Limpieza de recursos
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- UI: Alertas ---
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
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // --- LÓGICA PRINCIPAL: REGISTRO ---
  void _handleRegister() async {
    // Evitar dobles pulsaciones
    if (_isLoading) return;

    // 1. Validación de campos (formato email, contraseña segura, etc.)
    if (!_formKey.currentState!.validate()) {
      _showAlert(
        'Datos Incompletos',
        'Por favor, revisa los campos marcados en rojo.',
      );
      return;
    }

    // 2. Iniciar Carga
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Obtener el servicio
      final authService = Provider.of<AuthService>(context, listen: false);

      // 4. LLAMADA REAL A LA API (/api/auth/register)
      // Esta función crea el usuario en la BD y lo loguea automáticamente (guarda el token).
      await authService.register(
        name: _nameController.text.trim(),
        surname: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      // 5. Éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registro exitoso. ¡Bienvenido a Turisgal!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navegar a la pantalla principal y eliminar el historial de navegación anterior
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      // 6. Manejo de Errores (Ej: Email ya registrado)
      // Limpiamos el mensaje de excepción para el usuario
      final errorMsg = e.toString().replaceFirst('Exception: ', '');

      _showAlert('Error de Registro', errorMsg);
    } finally {
      // 7. Finalizar Carga
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleObscurePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registro de Usuario',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // Si está cargando, mostramos un spinner, si no, el formulario
          child: _isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Creando tu cuenta...'),
                  ],
                )
              : RegisterForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  lastNameController: _lastNameController,
                  phoneController: _phoneController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  onRegister: _handleRegister, // Acción de registro
                  onToggleObscure: _toggleObscurePassword,
                  onBackToLogin: () {
                    Navigator.pop(context); // Volver al Login
                  },
                ),
        ),
      ),
    );
  }
}
