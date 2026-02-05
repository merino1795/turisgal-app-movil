// lib/services/api_service.dart
import 'dart:convert'; //Herramientas para convertir datos JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; //Paquete para realizar peticiones web (GET, POST, etc)
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart'; //Para guardar datos en el mmovil
import '../reservation_modal.dart'; //Importa el modelo de datos de Reserva
import 'dart:async'; //Para manejo de operaciones asincronas
import '../widgets/chat.dart'; // Importa el modelo de datos de ChatMessage

// URL BASE: Define a dónde se conectará la app.
// '10.0.2.2' es una dirección especial que permite al emulador de Android hablar con el 'localhost' de tu PC.
const String baseUrl = 'http://10.0.2.2:3000';

// Si usas un dispositivo físico, cambia la IP por la de tu PC en la red local.
//const String baseUrl = 'http://192.168.1.35:3000/api';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _tokenKey = 'authToken';
  static const String _userIdKey = 'userId';

  String? _currentUserId;
  String get userId => _currentUserId ?? 'unknown_user';

  // Dentro de la clase ApiService
  Future<List<String>> uploadPhotoMultipart(
    String reservationId,
    String photoType,
    File imageFile,
  ) async {
    final uri = Uri.parse('http://10.0.2.2:3000/api/checkout/photo');

    print("🚀 Intentando conectar con: $uri"); // Log para verificar
    var request = http.MultipartRequest('POST', uri);

    // 1. Añadir Headers (Token)
    String? token =
        await _getToken(); // Usa tu método existente para obtener token
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 2. Añadir campos de texto
    request.fields['reservationId'] = reservationId;
    request.fields['photoType'] = photoType;

    // 3. Añadir el archivo
    var stream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();

    var multipartFile = http.MultipartFile(
      'image', // Este nombre debe coincidir con upload.single('image') en el backend
      stream,
      length,
      filename: imageFile.path.split('/').last,
    );

    request.files.add(multipartFile);

    // 4. Enviar
    print("Enviando foto vía Multipart...");
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseBody);
      return List<String>.from(jsonResponse['uploadedPhotos']);
    } else {
      print("Error Servidor: $responseBody");
      throw Exception('Fallo subida: ${response.statusCode}');
    }
  }

  Future<void> initUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString(_userIdKey);

    // Si no tenemos ID pero tenemos token, intentamos decodificarlo (opcional)
    if (_currentUserId == null) {
      final token = prefs.getString(_tokenKey);
      if (token != null) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
            );
            _currentUserId = payload['id']?.toString();
            if (_currentUserId != null) {
              await prefs.setString(_userIdKey, _currentUserId!);
            }
          }
        } catch (e) {
          print('Error decodificando token al inicio: $e');
        }
      }
    }
    print('DEBUG API: Usuario actual ID: $_currentUserId');
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveAuthData(String token, dynamic user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    if (user != null && user['id'] != null) {
      _currentUserId = user['id'].toString();
      await prefs.setString(_userIdKey, _currentUserId!);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    _currentUserId = null;
  }

  Future<Map<String, String>> _getHeaders({bool useAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (useAuth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // -------------------------
  // AUTH (LOGIN & REGISTER)
  // -------------------------

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _getHeaders(useAuth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data['token'], data['user']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error login: $e');
      return false;
    }
  }

  // NUEVO: Registro de usuario
  Future<bool> register(
    String name,
    String surname,
    String email,
    String phone,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await _getHeaders(useAuth: false),
        body: jsonEncode({
          'name': name,
          'surname': surname, // Puede ser string vacío si no se usa
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data['token'], data['user']);
        return true;
      }
      print('Fallo registro: ${response.body}');
      return false;
    } catch (e) {
      print('Error registro: $e');
      return false;
    }
  }

  // -------------------------
  // RESET PASSWORD
  // -------------------------

  Future<bool> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/request-reset'),
      headers: await _getHeaders(useAuth: false),
      body: jsonEncode({'email': email}),
    );
    return response.statusCode == 200;
  }

  Future<String?> verifyResetToken(String email, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/verify-token'),
      headers: await _getHeaders(useAuth: false),
      body: jsonEncode({'email': email, 'token': token}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['resetKey']; // Retornamos la clave para el siguiente paso
    }
    return null;
  }

  Future<bool> confirmPasswordReset(
    String email,
    String resetKey,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/update-password'),
      headers: await _getHeaders(useAuth: false),
      body: jsonEncode({
        'email': email,
        'resetKey': resetKey,
        'newPassword': newPassword,
      }),
    );
    return response.statusCode == 200;
  }

  // -------------------------
  // RESERVAS (CORREGIDO)
  // -------------------------

  // CORREGIDO: Maneja respuesta de Lista directa [ ... ]
  Future<List<Reservation>> getActiveReservations() async {
    try {
      final url = Uri.parse('$baseUrl/api/reservations/active');
      print(
        'Flutter intentando llamar a: $url',
      ); // <--- AÑADIDO PARA VER LA URL

      final response = await http.get(url, headers: await _getHeaders());

      print(
        'DEBUG API Reservas: Código ${response.statusCode}',
      ); // Esto nos ayudará
      if (response.statusCode == 200) {
        // El backend devuelve una LISTA JSON, no un objeto con clave "reservations"
        List<dynamic> body = jsonDecode(response.body);

        return body.map((dynamic item) => Reservation.fromJson(item)).toList();
      } else {
        // 👇 AQUI ESTÁ LA CLAVE: Imprimimos QUÉ nos dice el servidor
        print('ERROR DEL SERVIDOR (${response.statusCode}): ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error crítico en getActiveReservations: $e');
      return []; // Retorna vacío en vez de romper la app
    }
  }

  Future<Reservation?> getReservationById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reservations/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Reservation.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // -------------------------
  // CHECKOUT
  // -------------------------

  Future<List<String>> uploadPhoto(
    String reservationId,
    String type,
    String base64,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/checkout/photo'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'reservationId': reservationId,
        'photoType':
            type, // Backend espera string simple "KITCHEN" o "BATHROOM"
        'photoBase64':
            base64, // Backend ajustado para recibir 'photoBase64' o 'image'
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Convertimos la lista dinámica a String
      return List<String>.from(data['uploadedPhotos'] ?? []);
    }
    throw Exception('Error subiendo foto');
  }

  Future<bool> finalizeCheckout(String reservationId, String incidents) async {
    // Asegúrate de que pone '/api/checkout/finalize'
    final uri = Uri.parse('http://10.0.2.2:3000/api/checkout/finalize');

    try {
      String? token = await _getToken();

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'reservationId': reservationId,
          'incidents': incidents,
        }),
      );

      if (response.statusCode == 200) {
        print("Checkout finalizado en servidor");
        return true;
      } else {
        print("Error al finalizar: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error de red: $e");
      return false;
    }
  }

  // -------------------------
  // CHAT
  // -------------------------

  Future<List<ChatMessage>> fetchChatHistory(String reservationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/history/$reservationId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => ChatMessage.fromJson(item)).toList();
    }
    return [];
  }

  Future<ChatMessage?> sendMessage(String reservationId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/send'),
      headers: await _getHeaders(),
      body: jsonEncode({'reservationId': reservationId, 'text': text}),
    );

    if (response.statusCode == 201) {
      return ChatMessage.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // -------------------------
  // CONTACTO
  // -------------------------
  Future<bool> contactUs({
    required String name,
    required String email,
    required String phone,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contact'),
      headers: await _getHeaders(useAuth: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> submitReview(
    String reservationId,
    int rating,
    String comment,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'reservationId': reservationId,
          'rating': rating,
          'comment': comment,
        }),
      );
      // Aceptamos 200 (OK) o 201 (Created)
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error enviando reseña: $e');
      return false;
    }
  }

  // En tu clase ApiService...

  Future<Map<String, dynamic>> getPropertyInfo(String reservationId) async {
    // 1. Construcción de URL (Evitamos doble barra // si baseUrl ya la tiene)
    final endpoint = '/api/reservations/info/$reservationId';
    final url = Uri.parse('$baseUrl$endpoint');

    print('[Flutter] Intentando conectar a: $url');

    try {
      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10)); // Timeout de 10 seg

      print('[Flutter] Respuesta recibida. Código: ${response.statusCode}');
      print('[Flutter] Cuerpo: ${response.body}');

      if (response.statusCode == 200) {
        // ÉXITO: Decodificamos el JSON
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception(
          'El servidor no encontró información para esta reserva (404).',
        );
      } else if (response.statusCode == 500) {
        throw Exception(
          'Error interno del servidor (500). Revisa la terminal del backend.',
        );
      } else {
        throw Exception('Error desconocido: ${response.statusCode}');
      }
    } catch (e) {
      print('[Flutter] Error CRÍTICO en getPropertyInfo: $e');
      // Re-lanzamos el error para que la pantalla lo muestre
      throw Exception('Fallo de conexión: $e');
    }
  }
}
