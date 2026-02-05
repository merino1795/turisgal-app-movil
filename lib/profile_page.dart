import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:turigal/services/auth_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Para manejar la plataforma web
import 'package:intl/intl.dart'; // Para formatear fechas
import 'package:image_picker/image_picker.dart'; // Para cambiar foto de perfil

// -------------------------------------------------------------
// MODELO DE PERFIL (Mapeado desde la respuesta del Backend)
// -------------------------------------------------------------
class UserProfile {
  final String nombre;
  final String email;
  final String telefono;
  final String createdAt;
  final String updatedAt;

  UserProfile({
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper para formatear fechas ISO (ej: 2023-12-01T10:00:00Z -> 01/12/2023)
  static String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'No disponible';
    final String dateString = dateValue.toString();
    if (dateString.isEmpty) return 'No disponible';
    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateString; // Si falla, devolvemos el string original
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Concatenamos nombre y apellido si existen
    final name = json['nombre'] as String? ?? '';
    final surname = json['apellido'] as String? ?? '';
    final fullName = (name + ' ' + surname).trim();

    return UserProfile(
      nombre: fullName.isEmpty ? 'Usuario' : fullName,
      email: json['email'] as String? ?? 'Email no disponible',
      telefono: json['telefono'] as String? ?? 'No registrado',
      createdAt: _formatDate(json['createdAt']),
      updatedAt: _formatDate(json['updatedAt']),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  // Variables para la foto de perfil (local)
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Carga inicial al construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
    });
  }

  // --- OBTENER DATOS DEL SERVIDOR ---
  Future<void> _fetchUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Verificación de seguridad
    if (!authService.isAuthenticated) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Usuario no autenticado.';
        });
      }
      return;
    }

    try {
      // 1. LLAMADA REAL A LA API (/api/auth/profile)
      final userData = await authService.fetchUserProfile();

      if (mounted) {
        setState(() {
          // 2. Mapeo de datos JSON -> Objeto UserProfile
          _userProfile = UserProfile.fromJson(userData);
          _isLoading = false;
        });
      }
    } catch (e) {
      // 3. Manejo de Errores (Red, Servidor, Token expirado)
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudo cargar el perfil completo.';
          // Fallback visual: Usamos los datos básicos que ya tiene AuthService en memoria
          _userProfile = UserProfile(
            nombre: authService.currentUserName ?? 'Usuario',
            email: authService.currentEmail ?? 'Email',
            telefono: authService.currentUserPhone ?? '---',
            createdAt: '---',
            updatedAt: '---',
          );
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  // --- SELECCIÓN DE IMAGEN (Cámara/Galería) ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Comprimir para ahorrar datos
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        // AQUÍ FALTARÍA: Subir esta imagen al servidor (endpoint pendiente)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada localmente.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al acceder a la imagen.')),
      );
    }
    // Cerrar el modal inferior
    if (mounted) Navigator.pop(context);
  }

  // Modal para elegir fuente de la imagen
  void _editProfileImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para que la pantalla se actualice si AuthService cambia
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Prioridad de datos: Perfil cargado > Auth en memoria > Placeholder
        final displayName =
            _userProfile?.nombre ??
            authService.currentUserName ??
            'Cargando...';
        final displayEmail =
            _userProfile?.email ?? authService.currentEmail ?? '...';

        // Construcción del Avatar
        Widget profileAvatar;
        if (_imageFile != null && !kIsWeb) {
          // Caso 1: Foto nueva seleccionada
          profileAvatar = ClipOval(
            child: Image.file(
              _imageFile!,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            ),
          );
        } else {
          // Caso 2: Foto por defecto (o URL remota si la tuviéramos)
          profileAvatar = const Icon(
            Icons.person,
            color: Colors.white,
            size: 60,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Mi Perfil',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // --- TARJETA DE USUARIO ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar con botón de editar
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.blue.shade300,
                                  child: profileAvatar,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _editProfileImage(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // Mensaje de error discreto
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            // Campos de Información
                            _buildInfoTile(
                              Icons.person_outline,
                              'Nombre',
                              displayName,
                            ),
                            _buildInfoTile(
                              Icons.email_outlined,
                              'Email',
                              displayEmail,
                            ),
                            _buildInfoTile(
                              Icons.phone_outlined,
                              'Teléfono',
                              _userProfile?.telefono ?? '---',
                            ),

                            const Divider(height: 30),

                            _buildInfoTile(
                              Icons.calendar_today,
                              'Miembro desde',
                              _userProfile?.createdAt ?? '---',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // Widget auxiliar para filas de información
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
