import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // AÑADIDO para obtener el token real.

// URL dinámica (Localhost si es web, 10.0.2.2 si es emulador Android).
final String kBaseUrl =
    kIsWeb || defaultTargetPlatform != TargetPlatform.android
    ? 'http://localhost:3000/api/checkin'
    : 'http://10.0.2.2:3000/api/checkin';

class CheckInService {
  // Obtenemos el token real almacenado por AuthService.
  Future<String?> _getRealToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  //Headers ahora es asíncrono porque espera a leer el disco.
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getRealToken();

    // Si no hay token, lanzamos error (el usuario debe estar logueado).
    if (token == null) {
      throw Exception('No estás autenticado.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Inyectamos el JWT real.
    };
  }

  // Manejador genérico de respuestas HTTP
  dynamic _handleResponse(http.Response response) {
    // 1. Intentamos decodificar el JSON
    Map<String, dynamic> body;
    try {
      body = json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      // Si falla, es un error técnico del servidor (no es JSON)
      throw Exception('Error técnico del servidor (${response.statusCode})');
    }

    // 2. Si el código es 2xx, todo bien
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // 3. Si hay error (400, 404, 500), leemos el mensaje del backend
    final backendMessage = body['message'];

    if (backendMessage != null && backendMessage.toString().isNotEmpty) {
      // LANZAMOS EL MENSAJE REAL DEL BACKEND
      throw Exception(backendMessage);
    } else {
      throw Exception('Error desconocido (${response.statusCode})');
    }
  }

  // --- 1. Validar Reserva con QR ---
  Future<Map<String, dynamic>> validateReservation(String qrCode) async {
    final uri = Uri.parse('$kBaseUrl/validate-reservation');

    try {
      // Obtenemos headers con el token real antes de la llamada
      final headers = await _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({'reservationCode': qrCode}),
      );

      // Usamos el handler nuevo
      final responseBody = _handleResponse(response);

      if (responseBody['data'] == null) return {};
      return responseBody['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // 2. Verificacion de identidad (OCR/Biometría)
  // Envia foto del DNI y selfie para verificación en Base64
  Future<Map<String, dynamic>> verifyIdentity({
    required String reservationId,
    required String documentBase64,
    required String selfieBase64,
  }) async {
    final uri = Uri.parse('$kBaseUrl/verify-identity');

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({
          'reservationId': reservationId,
          'documentBase64': documentBase64, // Base64 de la imagen del documento
          'selfieBase64': selfieBase64, // Base64 de la selfie
        }),
      );

      final responseBody = _handleResponse(response);
      return responseBody['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // 3. Envío de Firma y Finalización del Check-in
  // Envia la firma digital y finaliza el check-in
  Future<Map<String, dynamic>> submitSignature({
    required String reservationId,
    required String signatureBase64,
    required String guestName,
    required bool acceptedTerms,
  }) async {
    final uri = Uri.parse('$kBaseUrl/submit-signature');

    try {
      final headers = await _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({
          'reservationId': reservationId,
          'signatureBase64': signatureBase64,
          'guestName': guestName,
          'acceptedTerms': acceptedTerms,
        }),
      );

      final responseBody = _handleResponse(response);
      return responseBody['data'] as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
