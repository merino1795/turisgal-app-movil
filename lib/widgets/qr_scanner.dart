import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // Controlador para manejar la cámara
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false; // Evita lecturas múltiples

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos el tamaño del área de escaneo
    final double scanArea =
        (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 300.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escanear Código QR',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // ✅ CORREGIDO: Botón de Flash (Actualizado para mobile_scanner 5.x)
          ValueListenableBuilder(
            valueListenable:
                cameraController, // Escuchamos al controlador directamente
            builder: (context, state, child) {
              // Accedemos a torchState a través del estado
              final isTorchOn = state.torchState == TorchState.on;

              return IconButton(
                color: Colors.white,
                iconSize: 32.0,
                icon: Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: isTorchOn ? Colors.amber : Colors.grey,
                ),
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
          // Botón para cambiar cámara (frontal/trasera)
          IconButton(
            color: Colors.white,
            iconSize: 32.0,
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. La Cámara
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_isScanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    _isScanned = true;
                  });
                  final String code = barcode.rawValue!;
                  debugPrint('QR Detectado: $code');

                  // Devolvemos el código a la pantalla anterior
                  Navigator.pop(context, code);
                  break;
                }
              }
            },
          ),

          // 2. El Overlay (Capa oscura con hueco transparente)
          CustomPaint(
            painter: ScannerOverlayPainter(
              borderColor: Colors.blue,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: scanArea,
            ),
            child: Container(),
          ),

          // 3. Texto de ayuda
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: const Text(
              "Apunta el código QR dentro del marco",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clase para dibujar el marco (Overlay)
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    required this.borderRadius,
    required this.borderLength,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final Paint backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    // Fondo oscuro con recorte central
    final Path path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(width / 2, height / 2),
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );

    canvas.drawPath(path, backgroundPaint);

    // Bordes (Esquinas)
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final double halfSize = cutOutSize / 2;
    final Offset center = Offset(width / 2, height / 2);

    // Dibujar las 4 esquinas
    // ... (Código de dibujo optimizado)

    // Esquina Superior Izquierda
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - halfSize, center.dy - halfSize + borderLength)
        ..lineTo(center.dx - halfSize, center.dy - halfSize)
        ..lineTo(center.dx - halfSize + borderLength, center.dy - halfSize),
      borderPaint,
    );
    // Esquina Superior Derecha
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + halfSize - borderLength, center.dy - halfSize)
        ..lineTo(center.dx + halfSize, center.dy - halfSize)
        ..lineTo(center.dx + halfSize, center.dy - halfSize + borderLength),
      borderPaint,
    );
    // Esquina Inferior Derecha
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + halfSize, center.dy + halfSize - borderLength)
        ..lineTo(center.dx + halfSize, center.dy + halfSize)
        ..lineTo(center.dx + halfSize - borderLength, center.dy + halfSize),
      borderPaint,
    );
    // Esquina Inferior Izquierda
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - halfSize + borderLength, center.dy + halfSize)
        ..lineTo(center.dx - halfSize, center.dy + halfSize)
        ..lineTo(center.dx - halfSize, center.dy + halfSize - borderLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
