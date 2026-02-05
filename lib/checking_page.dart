import 'package:flutter/material.dart';
import 'package:turigal/services/checkin_service.dart'; // Servicio real
// Asegúrate de importar el archivo que creamos antes
import 'package:turigal/widgets/qr_scanner.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState(); // Estado mutable
}

class _CheckInPageState extends State<CheckInPage> {
  // 1. Instancia del servicio de API (Conectado al backend real)
  final CheckInService _checkInService = CheckInService();

  // Controlador para la entrada manual del código QR/ID de reserva
  final TextEditingController _qrController = TextEditingController();

  // 2. Variables de estado para la UI
  bool _isLoading = false; // Controla el spinner de carga
  String _errorMessage = ''; // Almacena mensajes de error del backend

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  // NUEVA FUNCIÓN: ABRE LA CÁMARA
  Future<void> _openQrScanner() async {
    // 1. Navegamos a la pantalla del escáner y esperamos el resultado
    final codigoLeido = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    // 2. Si volvió con un código (no es null)
    if (codigoLeido != null && codigoLeido is String) {
      setState(() {
        // Rellenamos el campo de texto automáticamente
        _qrController.text = codigoLeido;
        _errorMessage = ''; // Limpiamos errores previos
      });

      // Feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("¡Código detectado: $codigoLeido!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // LÓGICA PRINCIPAL: VALIDACIÓN CON BACKEND
  void _validateAndNavigate() async {
    // 1. Intentamos obtener el código
    final qrCode = await _qrController.text.trim();

    // Validación local: Si no hay código, avisamos al usuario.
    if (qrCode.isEmpty) {
      setState(() {
        _errorMessage = 'El campo no puede estar vacío.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, escanea un QR o escribe el ID.'),
          backgroundColor: Colors.orange,
        ),
      );
      return; // Cortamos aquí, no llamamos al servidor
    }

    // 2. Iniciar estado de carga (UI Bloqueada)
    setState(() {
      _isLoading = true; // Mostrar spinner
      _errorMessage = ''; // Limpiar errores previos
    });

    try {
      // 3. LLAMADA A LA API REAL
      final Map<String, dynamic> data = await _checkInService
          .validateReservation(qrCode);

      // Si la llamada es exitosa (código 200), navegamos.
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reserva validada. Iniciando verificación de identidad.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 4. NAVEGACIÓN DINÁMICA
        // Vamos a la pantalla de Identidad pasando los datos REALES recibidos del servidor.
        Navigator.of(context).pushNamed(
          '/checkin/verify-identity',
          arguments: {
            'reservationId': data['reservationId'], // ID real de la reserva
            'guestName': data['guestName'] ?? 'Huésped', // Nombre del huésped
          },
        );
      }
    } catch (e) {
      // 1. Limpieza del mensaje
      // Quitamos "Exception:" y el código de error tipo "(Código: 400)"
      String cleanError = e.toString().replaceFirst('Exception:', '').trim();
      cleanError = cleanError.replaceAll(RegExp(r'\(Código: \d+\)'), '').trim();

      // Debug para que veas en consola qué llega exactamente
      print("DEBUG ERROR LIMPIO: $cleanError");

      String technicalError = e.toString().toLowerCase();
      String userMessage = '';

      // 2. LÓGICA SIMPLIFICADA

      // A. Error de conexión (Internet)
      if (technicalError.contains('socket') ||
          technicalError.contains('connection') ||
          technicalError.contains('clientexception')) {
        userMessage = 'No tienes conexión a internet.';
      }
      // B. Error 404 (No encontrado) - Mensaje amigable
      else if (technicalError.contains('404') ||
          technicalError.contains('no encontramos')) {
        userMessage = 'No encontramos ninguna reserva con ese código.';
      }
      // C. Error 500 (Servidor roto)
      else if (technicalError.contains('500')) {
        userMessage = 'Error técnico en el servidor. Inténtalo más tarde.';
      }
      // D. CUALQUIER OTRO ERROR (Incluido el "Ya realizado")
      // Aquí está el cambio: Mostramos directamente lo que mandó el backend
      else {
        // Si el mensaje viene vacío o es muy técnico, ponemos uno por defecto
        if (cleanError.isEmpty || cleanError.contains('XMLHttpRequest')) {
          userMessage = 'El código no es válido.';
        } else {
          // MOSTRAMOS EL MENSAJE REAL DEL BACKEND ("¡Atención! El Check-in...")
          userMessage = '$cleanError';
        }
      }

      // Mostramos el mensaje traducido
      if (mounted) {
        setState(() {
          _errorMessage = userMessage;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // 5. Finalizar carga
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // UI DEL CHECK-IN
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check-in Digital',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Icono Central del QR
              Icon(
                Icons.qr_code_2,
                size: 100,
                color: Colors.deepOrange.shade600,
              ),
              const SizedBox(height: 30),

              // Título
              const Text(
                'Inicio de Check-in',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Descripción del Proceso
              Text(
                'Escanee el código QR o introduzca el ID de reserva para iniciar el proceso de validación con el sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // Campo para introducir el código manualmente
              TextField(
                controller: _qrController,
                decoration: InputDecoration(
                  labelText: 'ID de Reserva',
                  hintText: 'Ej: TURISGAL-12345',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    color: Colors.deepOrange,
                    tooltip: 'Escanear QR',
                    onPressed: _isLoading
                        ? null
                        : _openQrScanner, // Abre la cámara
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                // Deshabilitamos input si está cargando
                enabled: !_isLoading,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) =>
                    _validateAndNavigate(), // Permite enviar con "Enter"
                //keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              // Botón de Acción (Scan/Validate)
              ElevatedButton.icon(
                // Si carga, deshabilitamos el botón
                onPressed: _isLoading ? null : _validateAndNavigate,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt_outlined, size: 28),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  child: Text(
                    _isLoading ? 'VALIDANDO...' : 'VALIDAR RESERVA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
              ),
              const SizedBox(height: 20),

              // Mensaje de Error
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // Pasos Siguientes
              const Text(
                'Pasos siguientes en el Check-in:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              _buildStepTile(Icons.security, '1. Verificación de Identidad'),
              _buildStepTile(Icons.edit, '2. Firma Digital de Contrato'),
              _buildStepTile(Icons.check_circle, '3. Confirmación de Entrada'),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para los pasos
  Widget _buildStepTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Colors.deepOrange.shade400, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
