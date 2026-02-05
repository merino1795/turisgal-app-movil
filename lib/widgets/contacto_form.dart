import 'package:flutter/material.dart';

// Formulario reutilizable para la página de Contacto
class ContactForm extends StatelessWidget {
  // Controladores para leer el texto que escribe el usuario
  final TextEditingController nombreController;
  final TextEditingController emailController;
  final TextEditingController telefonoController;
  final TextEditingController mensajeController;

  // Función que se ejecuta al pulsar el botón
  final VoidCallback onSubmit;

  // Constructor
  const ContactForm({
    super.key,
    required this.emailController,
    required this.nombreController,
    required this.telefonoController,
    required this.mensajeController,
    required this.onSubmit,
  });

  // Validadores de los campos del formulario
  // Validador de Email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, introduce tu email, es obligatorio.';
    }
    // Regex de validación de email estándar
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Introduce un formato de email válido.';
    }
    return null;
  }

  // Validador de Teléfono
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio.';
    }
    // Validación de formato: al menos 9 dígitos
    if (!RegExp(
      r'^[0-9]{9,}$',
    ).hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
      return 'Introduce un número de teléfono válido (mínimo 9 dígitos).';
    }
    return null;
  }

  // Validador de Nombre
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es obligatorio.';
    }
    return null;
  }

  // Validador de Mensaje
  String? _validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'El mensaje es obligatorio.';
    }
    if (value.length < 10) {
      return 'El mensaje debe tener al menos 10 caracteres.';
    }
    return null;
  }

  // WIDGET AUXILIAR PARA MOSTRAR LA INFORMACIÓN DE CONTACTO ESTÁTICA
  Widget _buildContactInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de contacto
        const Text(
          '¿Necesitas ayuda inmediata? Contáctanos:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 15),
        // Teléfono
        ListTile(
          leading: const Icon(Icons.phone, color: Colors.blue),
          title: const Text(
            'Teléfono',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('+34 699 76 55 14'),
        ),
        // Email
        ListTile(
          leading: const Icon(Icons.email, color: Colors.blue),
          title: const Text(
            'Email',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('info@turisgal.com'),
        ),
        // Horario
        ListTile(
          leading: const Icon(Icons.access_time, color: Colors.blue),
          title: const Text(
            'Horario de Atención',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Lunes a sábado: 10:00 a 22:00'),
        ),
        const SizedBox(height: 25),
        const Divider(),
        const SizedBox(height: 25),
        const Text(
          'O escríbenos un mensaje',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 400), // Ancho máximo compacto
      // Utilizamos Column para apilar la info estática y el formulario
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- NUEVA SECCIÓN: INFORMACIÓN DE CONTACTO ---
          _buildContactInfo(context),

          // ---------------------------------------------
          Form(
            // Contiene los campos para la validación
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ocupa solo el espacio necesario
              children: [
                // --- Input de Nombre (TextFormField con validador) ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Nombre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  // CORRECCIÓN: Añadir controlador y validador
                  controller: nombreController,
                  validator: _validateName,
                  decoration: InputDecoration(
                    hintText: 'Introduce tu nombre completo...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Input de Telefono (TextFormField con validador) ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Teléfono',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: telefonoController,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone, // Llama al validador de telefono
                  decoration: InputDecoration(
                    hintText: 'Introduce tu número de telefono...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),

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
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail, // Llama al validador de Email
                  decoration: InputDecoration(
                    hintText: 'Tu dirección de correo...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Input de Mensaje (TextFormField con validador) ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Mensaje',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  // CORRECCIÓN: Añadir controlador y validador.
                  controller: mensajeController,
                  validator: _validateMessage,
                  maxLines: 4, // Permitir multilínea para el mensaje
                  decoration: InputDecoration(
                    hintText: 'Dejanos un comentario...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.comment, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 30),

                // --- Botón de Enviar (compacto y centrado) ---
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: onSubmit, // RENOMBRADO: onLogin -> onSubmit
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'ENVIAR',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
