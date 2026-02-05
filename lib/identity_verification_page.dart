import 'dart:convert'; // Para convertir las fotos a Base64 (formato de texto para enviar a API).
import 'dart:io'; // Para manejar los archivos de imagen del dispositivo.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // PAQUETE REAL para usar la cámara.
import 'package:turigal/services/checkin_service.dart'; // Servicio conectado al backend.

class IdentityVerificationPage extends StatefulWidget {
  const IdentityVerificationPage({super.key});

  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  // 1. Instancia del servicio para comunicar con el servidor
  final CheckInService _checkInService = CheckInService();

  // 2. Variables para almacenar las fotos tomadas
  File? _documentImage; // Foto del DNI/Pasaporte
  File? _selfieImage; // Selfie del usuario

  // 3. Variables de datos de la reserva (se reciben de la pantalla anterior)
  String? _reservationId;
  String? _guestName;

  // 4. Estado de carga
  bool _isLoading = false;

  // Se ejecuta cuando la pantalla ha cargado sus dependencias (argumentos de navegación)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recuperamos los datos pasados desde 'CheckInPage'
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _reservationId = args['reservationId']?.toString();
      _guestName = args['guestName'];
    }
  }

  // --- LÓGICA DE CÁMARA (REAL) ---
  // Abre la cámara, toma la foto y la guarda en la variable correspondiente
  Future<void> _pickImage({required bool isDocument}) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Abrimos la cámara trasera para DNI, frontal para Selfie (opcional, aquí usamos trasera por defecto)
      // Limitamos la calidad para no saturar el servidor con imágenes de 10MB
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024, // Reducir ancho máximo
        maxHeight: 1024, // Reducir alto máximo
        imageQuality: 85, // Compresión JPEG
        preferredCameraDevice: isDocument
            ? CameraDevice.rear
            : CameraDevice.front,
      );

      // Si el usuario sacó la foto (no canceló)
      if (photo != null) {
        setState(() {
          if (isDocument) {
            _documentImage = File(photo.path);
          } else {
            _selfieImage = File(photo.path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error al abrir cámara: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo acceder a la cámara.')),
      );
    }
  }

  // --- LÓGICA DE ENVÍO AL BACKEND ---
  void _submitVerification() async {
    // 1. Validaciones Locales
    if (_documentImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, toma ambas fotos para continuar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_reservationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Falta ID de reserva.')),
      );
      return;
    }

    // 2. Iniciar Carga
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Convertir Imágenes a Base64
      // Leemos los bytes del archivo y los transformamos a texto.
      final String documentBase64 = base64Encode(
        await _documentImage!.readAsBytes(),
      );
      final String selfieBase64 = base64Encode(
        await _selfieImage!.readAsBytes(),
      );

      // 4. Llamada a la API
      // Enviamos el ID y las dos fotos "codificadas"
      await _checkInService.verifyIdentity(
        reservationId: _reservationId!,
        documentBase64: documentBase64,
        selfieBase64: selfieBase64,
      );

      // 5. Éxito (Si no hay excepción, el backend aceptó las fotos)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Identidad verificada correctamente.'),
            backgroundColor: Colors.green,
          ),
        );

        // 6. Navegar al Paso 3: Firma
        Navigator.of(context).pushNamed(
          '/checkin/signature', // Ruta definida en main.dart
          arguments: {
            'reservationId': _reservationId, // Pasamos el ID al siguiente paso
            'guestName': _guestName, // Pasamos el nombre
          },
        );
      }
    } catch (e) {
      // 7. Error (OCR falló, cara no coincide, error servidor)
      // Limpiamos el mensaje de error para que sea legible
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMsg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      // Siempre quitamos el spinner
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verificación de Identidad',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepOrange),
                  SizedBox(height: 20),
                  Text('Analizando documentos...'),
                  Text(
                    'Esto puede tardar unos segundos.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título personalizado
                  Text(
                    'Hola, ${_guestName ?? 'Huésped'}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Por motivos de seguridad y normativa legal, necesitamos verificar tu documentación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // --- CAJA FOTO 1: DOCUMENTO ---
                  _buildPhotoSlot(
                    title: '1. Foto del DNI / Pasaporte',
                    imageFile: _documentImage,
                    isDocument: true,
                    icon: Icons.credit_card,
                  ),

                  const SizedBox(height: 20),

                  // --- CAJA FOTO 2: SELFIE ---
                  _buildPhotoSlot(
                    title: '2. Selfie (Tu cara)',
                    imageFile: _selfieImage,
                    isDocument: false,
                    icon: Icons.face,
                  ),

                  const SizedBox(height: 40),

                  // --- BOTÓN CONTINUAR ---
                  ElevatedButton(
                    onPressed:
                        _submitVerification, // Llama a la función de envío
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'VERIFICAR Y CONTINUAR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Widget auxiliar para crear las "Cajas" donde van las fotos
  Widget _buildPhotoSlot({
    required String title,
    required File? imageFile,
    required bool isDocument,
    required IconData icon,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () =>
              _pickImage(isDocument: isDocument), // Al tocar, abre cámara
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(15),
              image: imageFile != null
                  ? DecorationImage(
                      image: FileImage(imageFile), // Muestra la foto tomada
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text(
                        'Tocar para tomar foto',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Container(
                    // Si hay foto, añadimos un icono de "Retomar" pequeño en la esquina
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.all(10),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 15,
                      child: Icon(Icons.edit, size: 18, color: Colors.black),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
