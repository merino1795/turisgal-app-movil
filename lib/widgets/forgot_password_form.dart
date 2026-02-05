import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Widget de Formulario de Recuperación de Contraseña
class ForgotPasswordForm extends StatelessWidget {
  // clave del formulario para validar
  final GlobalKey<FormState> formKey;

  // Controladores de los campos de texto
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController pinController;

  // Estado visual del PIN enviado
  final bool pinSent; // Indica si el PIN ya ha sido enviado
  final bool isLoading; // Indica si se está procesando una solicitud

  // Funciones que se ejecutan al pulsar los botones
  final VoidCallback onSendPin;
  final VoidCallback onUpdatePassword;

  const ForgotPasswordForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.phoneController,
    required this.pinController,
    required this.pinSent,
    required this.isLoading,
    required this.onSendPin,
    required this.onUpdatePassword,
  });

  // --- Validadores de Formato UI ---
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es obligatorio.';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Introduce un formato de email válido.';
    }
    return null;
  }

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

  String? _validatePinFormat(String? value) {
    // Si tiene contenido, validamos el formato. La verificación de PIN vacío la hace el padre.
    if (value != null && value.isNotEmpty && value.length != 6) {
      return 'El PIN debe tener 6 dígitos.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
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
      child: Form(
        key: formKey, // Asignamos la clave global del formulario
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_sharp, size: 60, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Verificación de PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Asegúrate de que tus datos de contacto son correctos antes de solicitar el código.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // --- 1. Input de Email ---
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: const Icon(Icons.email, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),

            // --- 2. Input de Teléfono ---
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ], // Solo números
              decoration: InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: const Icon(Icons.phone, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 30),

            // --- Botón Enviar PIN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // Si está cargando, onPressed es null (deshabilitado)
                onPressed: isLoading ? null : onSendPin,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                      ), // Icono normal
                label: Text(
                  isLoading
                      ? 'VERIFICANDO...' // Mensaje cuando está cargando
                      : pinSent
                      ? 'VOLVER A ENVIAR PIN'
                      : 'ENVIAR PIN',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  // Cambio de color sutil para indicar que se ha solicitado
                  backgroundColor: isLoading
                      ? Colors
                            .blue
                            .shade300 // Color más claro mientras carga
                      : pinSent
                      ? Colors.grey
                      : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // --- Separador ---
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 30),

            // --- 3. Input de PIN (Solo acepta números) ---
            TextFormField(
              controller: pinController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              // RESTRICCIÓN CLAVE: Solo permite dígitos
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validatePinFormat,
              decoration: InputDecoration(
                labelText: 'Código PIN de Verificación',
                hintText: 'Introduce el código de 6 dígitos',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                ),
                prefixIcon: const Icon(Icons.vpn_key, color: Colors.blue),
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),

            // --- 4. Botón Verificar PIN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpdatePassword,
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text(
                  'VERIFICAR PIN Y CONTINUAR',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
