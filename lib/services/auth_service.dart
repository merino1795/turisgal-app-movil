import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:turigal/home_page.dart';

// URL del servidor (Localhost Android).
const String _SERVER_URL = 'http://10.0.2.2:3000';
const String _AUTH_PATH = '$_SERVER_URL/api/auth';
const String _PASSWORD_PATH = '$_SERVER_URL/api/password';

// Extendemos ChangeNotifier para poder avisar a los Widgets cuando cambian los datos.
class AuthService with ChangeNotifier {
  String? _token; //El JWT Token
  Map<String, dynamic>? _user; // Datos del usuario autenticado
  String? _temporaryResetKey; // Clave temporal para reseteo de contraseña

  // Getters para leer el estado
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;
  String? get temporaryResetKey => _temporaryResetKey;

  // Devuelve el ID del usuario como String
  String? get currentUserId {
    final id = _user?['id'];
    if (id == null) return null;
    return id.toString();
  }

  // Devuelve el email del usuario autenticado
  String? get currentEmail {
    return _user?['email'] as String?;
  }

  // Devuelve el nombre completo concatenado (nombre + apellido)
  String? get currentUserName {
    if (_user == null) return null;
    final name = _user!['nombre'] as String? ?? '';
    final surname = _user!['apellido'] as String? ?? '';

    // Si existe nombre o apellido, los concatenamos
    if (name.isNotEmpty || surname.isNotEmpty) {
      return '$name $surname'.trim();
    }

    // Si no, devolvemos el email o un texto genérico.
    return _user!['email'] as String? ?? 'Usuario no identificado';
  }

  // Devuelve el teléfono del usuario
  String? get currentUserPhone {
    return _user?['telefono'] as String?;
  }

  // Devuelve la ruta de la imagen de perfil del usuario
  String? get profileImagePath {
    return _user?['profileImagePath'] as String?;
  }

  // Constructor: Carga los datos guardados al iniciar.
  AuthService() {
    _loadStoredData();
  }

  // --- LÓGICA DE PERSISTENCIA ---
  // Carga el token y los datos del usuario guardados en SharedPreferences
  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final userData = prefs.getString('userData');

    if (token != null && userData != null) {
      _token = token;
      _user = json.decode(userData);
      notifyListeners(); //¡Importante! Avisa a la App que ya estamos logueados.
    }
  }

  // Guarda el token y los datos del usuario en SharedPreferences
  Future<void> _storeData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('userData', json.encode(user));
    _token = token;
    _user = user;
    notifyListeners();
  }

  // Limpia la clave de reseteo de contraseña
  void clearAuthState() {
    _temporaryResetKey = null;
  }

  // =========================================================================
  // RUTAS DE AUTENTICACIÓN
  // =========================================================================

  // Registro de usuario
  Future<void> register({
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('$_AUTH_PATH/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'surname': surname,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      // Registro exitoso: Guardamos datos y entramos automáticamente.
      final responseData = json.decode(response.body);
      final token = responseData['token'];
      final user = responseData['user'];
      await _storeData(token, Map<String, dynamic>.from(user));
    } else {
      final errorBody = json.decode(response.body);
      String errorMessage =
          errorBody['message'] ?? 'Error desconocido en el registro.';
      throw Exception(errorMessage);
    }
  }

  // Inicio de sesión
  Future<void> login({required String email, required String password}) async {
    final url = Uri.parse('$_AUTH_PATH/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final token = responseData['token'];
      final user = responseData['user'];

      await _storeData(token, Map<String, dynamic>.from(user));
    } else {
      final errorBody = json.decode(response.body);
      String errorMessage =
          errorBody['message'] ?? 'Error desconocido durante el login.';
      throw Exception(errorMessage);
    }
  }

  // Restablecimiento de contraseña
  // Paso 1: Pedir codigo al email/telefono
  Future<String> requestPasswordReset({
    required String email,
    required String phone,
  }) async {
    final url = Uri.parse('$_PASSWORD_PATH/request-reset');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'phone': phone}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = json.decode(response.body);

        // Buscamos el token en varios campos posibles por seguridad.
        dynamic pinValue =
            responseBody['debugToken']; // <-- NUEVA CLAVE PRIMARIA
        pinValue ??= responseBody['pin'];
        pinValue ??= responseBody['code'];
        pinValue ??= responseBody['otp'];

        if (pinValue != null) {
          if (pinValue is String && pinValue.isNotEmpty) {
            return pinValue;
          }
          if (pinValue is int) {
            // Convierte el número entero a cadena para su uso.
            return pinValue.toString();
          }
        }

        // Se ejecuta si no se encontró ninguna de las claves o el valor es inválido.
        throw Exception(
          'El servidor no devolvió el código de verificación en las claves esperadas ("debugToken", "pin", "code" u "otp"). '
          'Respuesta del servidor: ${response.body}',
        );
      }

      // Si llegamos aquí, es un error 4xx o 5xx.
      if (response.statusCode >= 400) {
        const String friendlyMessage =
            'El Email o Teléfono proporcionados no están registrados o no coinciden.';
        throw Exception(friendlyMessage);
      }

      // Fallback para otros errores de estado
      final responseBody = json.decode(response.body);
      final errorMessage =
          responseBody['message'] ??
          'Error desconocido del servidor (${response.statusCode}).';

      throw Exception(errorMessage);
    } on http.ClientException {
      // Si hay un error de red
      throw Exception(
        'Fallo la conexión de red. Verifica tu conexión o que el servidor Express esté activo en $_SERVER_URL',
      );
    } catch (e) {
      // Re-lanzamos cualquier otra excepción
      rethrow;
    }
  }

  // Paso 2: Verificar el codigo recibido
  Future<void> verifyPasswordResetToken({
    required String email,
    required String token,
  }) async {
    final url = Uri.parse('$_PASSWORD_PATH/verify-token');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'token': token}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final resetKey = responseBody['resetKey'];

        if (resetKey == null) {
          throw Exception('Falta la clave de reseteo (resetKey).');
        }

        _temporaryResetKey = resetKey; // Guardamos la clave para el paso final
        return;
      }

      final responseBody = json.decode(response.body);
      final errorMessage =
          responseBody['message'] ??
          'Código incorrecto o expirado (${response.statusCode}).';

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Fallo la comunicación con el servidor: $e');
    }
  }

  // Paso 3: Cambiar la contraseña usando la clave verificada
  Future<void> updatePassword({
    required String email,
    required String newPassword,
  }) async {
    final url = Uri.parse('$_PASSWORD_PATH/update');

    if (_temporaryResetKey == null) {
      throw Exception('Clave de reseteo no válida. Reinicia el proceso.');
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'resetKey': _temporaryResetKey,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        clearAuthState(); // Limpiamos la clave temporal tras el éxito
        debugPrint('=====================================================');
        debugPrint(
          'LOG DEBUG: ¡Contraseña actualizada con éxito en el servidor!',
        );
        debugPrint('Usuario afectado: $email');
        debugPrint('Contraseña Nueva (SOLO DEBUG): $newPassword');
        debugPrint('Token de Reseteo Usado: $_temporaryResetKey');
        debugPrint('=====================================================');
        return;
      }

      final responseBody = json.decode(response.body);
      final errorMessage =
          responseBody['message'] ??
          'Fallo al actualizar la contraseña (${response.statusCode}).';

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Fallo la comunicación con el servidor: $e');
    }
  }

  // Perfil de usuario
  // Obtiene los datos mas recientes del usuario desde el servidor.
  Future<Map<String, dynamic>> fetchUserProfile() async {
    if (_token == null) {
      throw Exception('Usuario no autenticado. Inicia sesión primero.');
    }

    final url = Uri.parse('$_AUTH_PATH/profile');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $_token', // Token obligatorio para rutas protegidas
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);

        debugPrint(
          'LOG DEBUG: Datos crudos del usuario desde /profile: $userData',
        );

        // Actualizamos estado local y persistente
        _user = Map<String, dynamic>.from(userData);
        await _storeData(_token!, _user!);
        notifyListeners(); // Actualizamos la UI

        return _user!;
      } else {
        final errorBody = json.decode(response.body);
        String errorMessage =
            errorBody['message'] ??
            'Error al obtener el perfil: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } on http.ClientException {
      throw Exception(
        'Fallo la conexión de red al intentar obtener el perfil.',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Cierre de sesión
  Future<void> logout() async {
    // 1. Limpia Shared Preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userData');

    // 2. Limpia el estado local.
    _token = null;
    _user = null; // Limpiar los datos del usuario
    _temporaryResetKey = null; // Limpiar el token de reseteo

    // 3. Notifica a los oyentes (widgets) que el estado ha cambiado.
    notifyListeners();
    debugPrint('LOGOUT: Sesión de usuario cerrada y estado limpiada.');
  }
}
