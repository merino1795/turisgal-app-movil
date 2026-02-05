import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; //Necesario para acceder a los servicios (APiService)
import 'package:turigal/services/api_service.dart'; // Importar la logica de conexion
import 'package:turigal/widgets/contacto_form.dart'; //Importamos el widget visual del formulario

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  // 1. Clave global para identificar y validar el formulario
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 2. Controladores para capturar el texto introducido por el usuario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();

  // 3. Estado de carga para controlar la interfaz (mostrar spinner, bloquear boton, etc.)
  bool _isLoading = false;

  @override
  void dispose() {
    // Limpieza de controladores
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  // Función auxiliar para mostrar alertas modales (pop-ups)
  void _showAlert(String title, String content, {Color color = Colors.blue}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // 4. Lógica de envío del formulario
  void _handleSubmit() async {
    // Primero, validamos que todos los campos cumplan las reglas (email válido, no vacíos)
    if (_formKey.currentState?.validate() ?? false) {
      // Si es válido, iniciamos la carga
      setState(() {
        _isLoading = true;
      });

      try {
        // Obtenemos una instancia de ApiService a través del Provider
        final apiService = Provider.of<ApiService>(context, listen: false);

        // Llamamos al método contactUs del servicio API
        final success = await apiService.contactUs(
          name: _nombreController.text,
          email: _emailController.text,
          phone: _telefonoController.text,
          message: _mensajeController.text,
        );

        //Verificamos el resultado y mostramos la alerta correspondiente
        if (success) {
          _showAlert(
            '¡Mensaje Enviado!',
            'Tu solicitud ha sido enviada con éxito. Te responderemos lo antes posible.',
            color: Colors.green,
          );
          // Limpiar los campos para que el usuario pueda enviar otro mensaje
          _nombreController.clear();
          _emailController.clear();
          _telefonoController.clear();
          _mensajeController.clear();
        } else {
          _showAlert(
            'Error de Envío',
            'No se pudo enviar tu mensaje. Por favor, inténtalo de nuevo.',
            color: Colors.red,
          );
        }
      } catch (e) {
        // Capturamos cualquier error de red o excepción inesperada
        _showAlert(
          'Error',
          'Ha ocurrido un error inesperado al contactar con el servidor: $e',
          color: Colors.red,
        );
      } finally {
        // Independientemente del resultado, detenemos la carga
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 5. Construcción de la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // Usamos la clave del formulario aquí para poder validarlo
          child: Form(
            key: _formKey,
            // El formulario visual recibe los controladores y la función de envío
            child: Opacity(
              opacity: _isLoading ? 0.6 : 1.0, // Oscurecer mientras carga
              child: AbsorbPointer(
                absorbing:
                    _isLoading, // Deshabilitar interacción mientras carga
                child: ContactForm(
                  nombreController: _nombreController,
                  emailController: _emailController,
                  telefonoController: _telefonoController,
                  mensajeController: _mensajeController,
                  onSubmit: _handleSubmit, // Función de envío implementada
                ),
              ),
            ),
          ),
        ),
      ),
      // Muestra un indicador de carga en la parte inferior si está cargando
      bottomNavigationBar: _isLoading
          ? const LinearProgressIndicator(minHeight: 8.0)
          : null,
    );
  }
}
