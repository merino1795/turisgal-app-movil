import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para bloquear la orientación
import 'dart:ui' as ui; // Necesario para convertir el dibujo a imagen
import 'dart:convert'; // Para Base64
import 'package:turigal/services/checkin_service.dart'; // Servicio real

// --- WIDGET PERSONALIZADO PARA DIBUJAR LA FIRMA ---
class SignaturePainter extends CustomPainter {
  final List<List<Offset>> lines;

  SignaturePainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth =
          4.0 // Un poco más grueso para que se vea bien
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      for (int i = 0; i < line.length - 1; i++) {
        canvas.drawLine(line[i], line[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) {
    return oldDelegate.lines != lines;
  }
}

class SignaturePage extends StatefulWidget {
  final String reservationId;
  final String guestName;

  const SignaturePage({
    super.key,
    this.reservationId = '', // Opcional porque lo rellenamos en initState
    this.guestName = 'Huésped',
  });

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  // 1. Servicio API
  final CheckInService _checkInService = CheckInService();

  // Variables para el dibujo
  List<List<Offset>> _lines = []; // Almacena los trazos

  // Datos reales (se obtienen de los argumentos de navegación)
  late String _realReservationId;
  late String _realGuestName;

  bool _isSigned = false; // ¿Ha dibujado algo?
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recuperamos los datos pasados desde la pantalla anterior (IdentityVerificationPage)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Si vienen argumentos, los usamos. Si no, usamos los del constructor (o valores por defecto).
    _realReservationId = args?['reservationId'] ?? widget.reservationId;
    _realGuestName = args?['guestName'] ?? widget.guestName;
  }

  // --- CAPTURA DE TRAZOS ---
  void _onPanStart(DragStartDetails details) {
    if (_isLoading) return;
    setState(() {
      _lines.add([details.localPosition]);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isLoading) return;
    setState(() {
      final lastLine = _lines.last;
      lastLine.add(details.localPosition);
      _isSigned = true; // Ya hay contenido
    });
  }

  void _clearSignature() {
    setState(() {
      _lines = [];
      _isSigned = false;
      _errorMessage = '';
    });
  }

  // --- CONVERSIÓN DE TRAZOS A IMAGEN (BASE64) ---
  Future<String?> _convertSignatureToBase64() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      const size = Size(400, 200);

      // Fondo blanco (importante, si no sale transparente/negro)
      final paintBg = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBg);

      // Dibujar la firma
      final painter = SignaturePainter(lines: _lines);
      painter.paint(canvas, size);

      // Convertir a imagen
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        return base64Encode(buffer);
      }
      return null;
    } catch (e) {
      debugPrint('Error convirtiendo firma: $e');
      return null;
    }
  }

  // --- ENVÍO AL BACKEND ---
  void _submitSignature() async {
    if (!_isSigned) {
      setState(() => _errorMessage = 'Por favor, firme en el recuadro.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Convertir dibujo a imagen real
      final signatureBase64 = await _convertSignatureToBase64();

      if (signatureBase64 == null) {
        throw Exception('Error al procesar la imagen de la firma.');
      }

      // 2. LLAMADA REAL A LA API
      await _checkInService.submitSignature(
        reservationId: _realReservationId,
        signatureBase64: signatureBase64, // Enviamos el PNG en Base64
        guestName: _realGuestName,
        acceptedTerms: true,
      );

      // 3. Éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ¡Check-in Completado! Disfruta tu estancia.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // 4. Volver al Inicio (limpiando toda la pila de Check-in)
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bloquear rotación para facilitar la firma
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Firma del Contrato',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Título
            const Text(
              'Aceptación de Términos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Al firmar, $_realGuestName acepta las condiciones de la reserva $_realReservationId.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Contrato (Texto Legal)
            Container(
              height: 150,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade50,
              ),
              child: const SingleChildScrollView(
                child: Text(
                  'CONTRATO DE ALQUILER VACACIONAL\n\n'
                  '1. El huésped se compromete a cuidar el inmueble.\n'
                  '2. El check-out debe realizarse antes de las 11:00 AM.\n'
                  '3. No se permiten fiestas ni ruidos molestos.\n'
                  '4. La empresa no se hace responsable de objetos perdidos.\n'
                  '5. Al firmar este documento digital, usted acepta estos términos y declara que su identidad ha sido verificada correctamente.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Área de Firma
            const Text(
              'Su Firma:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              child: Container(
                height: 200, // Altura del área de firma
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepOrange, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                // Usamos ClipRect para que el dibujo no se salga del borde redondeado
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomPaint(
                    painter: SignaturePainter(lines: _lines),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Mensaje de Error
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '$_errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _clearSignature,
                  child: const Text(
                    'Borrar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: (_isSigned && !_isLoading)
                      ? _submitSignature
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isLoading ? 'Finalizando...' : 'FINALIZAR CHECK-IN',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
