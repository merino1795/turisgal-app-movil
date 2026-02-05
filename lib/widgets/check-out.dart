import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
// ✅ CORRECCIÓN 1: Importar el modelo correcto
import '../reservation_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class CheckoutScreen extends StatefulWidget {
  final String reservationId;

  const CheckoutScreen({Key? key, required this.reservationId})
    : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _incidentsController = TextEditingController();

  Reservation? _reservation;

  final List<String> _uploadedPhotos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Tipos de fotos requeridas
  final List<String> _photoTypes = ['Cocina', 'Sala', 'Baño Principal'];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _incidentsController.dispose();
    super.dispose();
  }

  String _formatDateForDisplay(DateTime? dateValue) {
    if (dateValue == null) return 'Pendiente';
    try {
      return DateFormat.yMMMMd('es_ES').format(dateValue);
    } catch (_) {
      return 'Fecha inválida';
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reservation = await _apiService.getReservationById(
        widget.reservationId,
      );

      if (mounted) {
        setState(() {
          _reservation = reservation;

          // Cargar datos existentes si la reserva ya tenía algo guardado
          if (reservation != null) {
            _incidentsController.text = reservation.incidents ?? '';
            _uploadedPhotos.clear();
            _uploadedPhotos.addAll(reservation.uploadedPhotos);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar datos: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUploadPhoto(String type) async {
    if (_uploadedPhotos.contains(type)) return;

    // 1. Tomar foto con CALIDAD REDUCIDA (Crucial para rendimiento)
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 800, // Redimensionar si es muy grande
      maxHeight: 800,
      imageQuality: 50, // Comprimir calidad (0-100)
    );

    if (image == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2. Llamar al nuevo método Multipart
      final List<String> updated = await _apiService.uploadPhotoMultipart(
        widget.reservationId,
        type,
        File(image.path),
      );

      setState(() {
        _uploadedPhotos.clear();
        _uploadedPhotos.addAll(updated);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto de $type subida con éxito.')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al subir foto: $e';
      });
    }
  }

  Future<void> _saveIncidents() async {
    String text = _incidentsController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El campo de incidencias está vacío.')),
      );
      return;
    }

    if (text.length > 1000) {
      text = text.substring(0, 1000);
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incidencia lista para enviar al finalizar.'),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _finalizeCheckout() async {
    // Validar fotos
    if (_uploadedPhotos.length < _photoTypes.length) {
      _showConfirmationDialog(
        'Faltan Fotos',
        'Aún no has subido todas las fotos (${_uploadedPhotos.length}/${_photoTypes.length}). ¿Finalizar de todos modos?',
        _performFinalization,
      );
      return;
    }

    _showConfirmationDialog(
      'Confirmar Check-out',
      '¿Estás seguro de que quieres finalizar tu estancia?',
      _performFinalization,
    );
  }

  Future<void> _performFinalization() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _apiService.finalizeCheckout(
        widget.reservationId,
        _incidentsController.text,
      );

      setState(() {
        _isLoading = false;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Check-out completado con éxito!')),
          );
          Navigator.pop(context, true); // Volver y recargar
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al finalizar: $e';
      });
    }
  }

  void _showConfirmationDialog(
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutStatusCard(BuildContext context) {
    if (_reservation == null) return const SizedBox.shrink();

    final bool isCheckoutComplete =
        _reservation!.status == 'COMPLETADA' ||
        _reservation!.status == 'PENDIENTE_REVISION';
    final checkoutDate = _formatDateForDisplay(_reservation!.checkOutDate);

    // Obtenemos el nombre de la propiedad directamente del objeto
    final propertyName = _reservation!.propertyName;

    String statusText = isCheckoutComplete
        ? '¡Check-out Enviado!'
        : 'Check-out Pendiente';
    Color cardColor = isCheckoutComplete
        ? Colors.green.shade700
        : Colors.indigo.shade500;
    IconData cardIcon = isCheckoutComplete
        ? Icons.check_circle_outline
        : Icons.exit_to_app;
    String subtitleText = isCheckoutComplete
        ? 'Gracias por tu estancia.'
        : 'Programado para el $checkoutDate hasta las 11:00.';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 25),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              propertyName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const Divider(color: Colors.white54, height: 10, thickness: 1),
            Row(
              children: [
                Icon(cardIcon, color: Colors.white, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              subtitleText,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fotos Subidas: ${_uploadedPhotos.length} / ${_photoTypes.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _photoTypes.map((type) {
                bool isUploaded = _uploadedPhotos.contains(type);
                return ActionChip(
                  avatar: Icon(
                    isUploaded ? Icons.check_circle : Icons.camera_alt,
                    color: isUploaded ? Colors.green : Colors.grey,
                  ),
                  label: Text(type),
                  onPressed: _isLoading || isUploaded
                      ? null
                      : () => _handleUploadPhoto(type),
                  backgroundColor: isUploaded
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reporte de Incidencias (Opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _incidentsController,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Describa cualquier problema o daño encontrado...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null && _reservation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-out Digital')),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    if (_isLoading && _reservation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Check-out Digital')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Check-out Digital')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckoutStatusCard(context),
            const SizedBox(height: 20),
            _buildPhotoUploadSection(),
            const SizedBox(height: 30),
            _buildIncidentsSection(),
            const SizedBox(height: 30),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _finalizeCheckout,

                icon: Icon(
                  _uploadedPhotos.length < _photoTypes.length
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                ),

                label: Text(
                  _uploadedPhotos.length < _photoTypes.length
                      ? 'Finalizar (Faltan ${_photoTypes.length - _uploadedPhotos.length} fotos)'
                      : 'Confirmar Check-out y Salir',
                ),

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  // CAMBIO VISUAL:
                  // Naranja si faltan fotos (advertencia).
                  // Indigo (Azul) si está todo listo.
                  backgroundColor: _uploadedPhotos.length < _photoTypes.length
                      ? Colors.orange.shade800
                      : Colors.indigo,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
