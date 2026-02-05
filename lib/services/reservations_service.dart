import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// URL Base (Ajustada para Android Emulador vs Web/iOS)
final String kBaseUrl =
    kIsWeb || defaultTargetPlatform != TargetPlatform.android
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

class ReservationsService {
  // Obtener Token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Headers con Token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. OBTENER RESERVAS ACTIVAS (Pendientes, En curso)
  Future<List<dynamic>> getActiveReservations() async {
    final uri = Uri.parse('$kBaseUrl/reservations/active');

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Error al cargar activas: ${response.statusCode}');
      }
    } catch (e) {
      print("Error en getActiveReservations: $e");
      return []; // Devolvemos lista vacía si falla para no romper la UI
    }
  }

  // 2. OBTENER HISTORIAL (Completadas, Canceladas)
  Future<List<dynamic>> getHistoryReservations() async {
    final uri = Uri.parse('$kBaseUrl/reservations/history'); // Ojo a la ruta

    try {
      final headers = await _getHeaders();
      // Print para depurar en la consola de Flutter
      print("Llamando a: $uri");

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print("Historial recibido: ${data.length} elementos");
        return data;
      } else {
        print("Error del servidor: ${response.body}");
        throw Exception('Error al cargar historial: ${response.statusCode}');
      }
    } catch (e) {
      print("Error de conexión en historial: $e");
      return [];
    }
  }
}
