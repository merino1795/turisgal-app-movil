import 'package:flutter/material.dart'; // Flutter framework
import 'package:provider/provider.dart'; // Gestión de estado
import 'package:turigal/services/auth_service.dart'; // Servicio de autenticación
import 'package:turigal/services/api_service.dart'; // Servicio de API
import 'package:turigal/reservation_modal.dart'; // Modelo de reserva
import 'package:url_launcher/url_launcher.dart'; // Lanzador de URL
import 'package:turigal/local_map_screen.dart'; // O la ruta donde lo creaste
// Importaciones a los nuevos widgets de funcionalidad
import 'package:turigal/widgets/check-out.dart'; // Pantalla de Check-out
import 'package:turigal/widgets/chat.dart'; // Pantalla de Chat
import 'package:turigal/widgets/reseñas.dart'; // Pantalla de Reseñas

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Servicio de API para obtener datos de la reserva y el perfil.
  final ApiService _apiService = ApiService();

  // --- ESTADO DINÁMICO ---
  // Almacena la reserva más relevante para mostrar en la tarjeta principal
  //UserProfile? _userProfile;
  Reservation? _reservation;

  //String _reservationId = 'RES-98765'; // ID de reserva simulado para la demo
  // Control de carga y errores
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Ejecutamos la carga inicial después de que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  // Carga combinada: Perfil de usuario + Reservas activas
  Future<void> _loadAllData() async {
    // 1. Refrescar datos del usuario (Nombre, foto, etc.)
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isAuthenticated) {
      try {
        await authService.fetchUserProfile();
      } catch (e) {
        debugPrint('Error refrescando perfil: $e');
      }
    }

    // 2. Cargar Reservas
    await _fetchReservationData();
  }

  // Función que abre la URL
  Future<void> launchTurisgalWebsite() async {
    const url = 'https://www.turisgal.com';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir la web.')));
    }
  }

  // Función para obtener el estado de la reserva.
  Future<void> _fetchReservationData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Llamada real a la API: /api/reservations/active
      final List<Reservation> activeReservations = await _apiService
          .getActiveReservations();
      if (mounted) {
        setState(() {
          if (activeReservations.isNotEmpty) {
            // Tomamos la primera reserva como la "actual" para la tarjeta de inicio
            _reservation = activeReservations.first;
          } else {
            // Si no hay reservas, _reservation es null (se mostrará botón de "Reservar")
            _reservation = null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando reservas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _reservation = null;
          // Mostramos un mensaje amigable en lugar del error técnico
          //_errorMessage ='No se encontraron reservas activas o hubo un error de conexión.';
        });
      }
    }
  }

  // Función para cerrar sesión.
  void _logout(BuildContext context) {
    Provider.of<AuthService>(context, listen: false).logout();
    // Redirigir al Login y eliminar historial de navegación
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/', // La ruta del login
      (Route<dynamic> route) => false,
    );
  }

  // Función de navegación que refresca la home al volver
  Future<void> _navigateTo(Widget screen) async {
    // Esperamos a que la pantalla siguiente se cierre (Navigator.pop)
    // El 'result' será 'true' si el Checkout se completó exitosamente.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    // Si volvimos con éxito (true) o simplemente al volver, recargamos los datos
    if (result == true) {
      debugPrint("Check-out completado. Recargando Home...");
      await _loadAllData(); // Recarga completa
    } else {
      // Recarga opcional por si acaso cambió algo sin devolver true
      await _fetchReservationData();
    }
  }

  // --------------------------------------------------------------------
  // CONSTRUCTOR DE LA TARJETA DINÁMICA SEGÚN ESTADO
  // --------------------------------------------------------------------
  Widget _buildDynamicStatusCard() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // CASO 1: NO HAY RESERVA o ERROR -> Invitación a reservar
    if (_reservation == null) {
      return _buildActionCard(
        icon: Icons.search,
        title: '¿Buscas alojamiento?',
        subtitle: 'Explora nuestros apartamentos y villas en la web.',
        buttonText: 'Buscar en Turisgal.com',
        color: Colors.blue,
        onTap: launchTurisgalWebsite,
      );
    }

    // ÚNICO CAMBIO NECESARIO AQUÍ: Usamos _reservation!.reservationId (el ID público RES-XXX)
    // para pasar a las pantallas siguientes, ya que el backend espera ese formato.
    final String resId = _reservation!.reservationId;

    // CASO 2: RESERVA CREADA PERO SIN CHECK-IN
    // Estados posibles: PENDIENTE, PENDIENTE_INICIO, NUEVA
    if (_reservation!.status == 'PENDIENTE_INICIO' ||
        _reservation!.status == 'PENDIENTE' ||
        _reservation!.status == 'NUEVA') {
      return _buildActionCard(
        icon: Icons.vpn_key_outlined,
        title: '¡Tu reserva está lista!',
        subtitle:
            '${_reservation!.propertyName}\nRealiza el check-in para obtener tus llaves.',
        buttonText: 'Hacer Check-in',
        color: Colors.blue,
        onTap: () async {
          // Navegar al flujo de Check-in
          final result = await Navigator.of(context).pushNamed('/checkin');
          if (result == true) _loadAllData();
        },
      );
    }

    // Caso 3: Estancia activa
    if (_reservation!.status == 'REGISTRO_COMPLETADO' ||
        _reservation!.status == 'ACTIVA') {
      return _buildActionCard(
        icon: Icons.holiday_village_outlined,
        title: 'Disfruta tu estancia',
        subtitle:
            'Estás en: ${_reservation!.propertyName}.\nCuando te marches, finaliza aquí.',
        buttonText: 'Finalizar Estancia (Check-out)',
        color: Colors.green,
        onTap: () => _navigateTo(CheckoutScreen(reservationId: resId)),
      );
    }

    // CASO 4: ESTANCIA COMPLETADA (Pedir Reseña)
    if (_reservation!.status == 'COMPLETADA') {
      return _buildActionCard(
        icon: Icons.star_rate_rounded,
        title: '!Gracias por tu visita!',
        subtitle: 'Esperamos que te haya gustado. Déjanos tu opinión.',
        buttonText: 'Dejar una Reseña',
        color: Colors.purple,
        onTap: () => _navigateTo(ReviewScreen(reservationId: resId)),
      );
    }

    // Fallback generico
    return const SizedBox.shrink();
  }

  // Widget base para las tarjetas
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentResId = _reservation?.reservationId ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Turisgal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context), // Menú lateral desplegable
      body: RefreshIndicator(
        // Permite refrescar la página con gesto de deslizamiento
        onRefresh: () async {
          _loadAllData();
          //await _fetchReservationData();
          //await _refreshUserProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // CONSUMER AÑADIDO AQUÍ PARA RECOGER EL NOMBRE IGUAL QUE EN EL MENU
              Consumer<AuthService>(
                builder: (context, auth, _) {
                  final name = auth.currentUserName ?? 'Huésped';
                  return Text(
                    '¡Hola, $name!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestiona tu estancia de forma sencilla',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              _buildDynamicStatusCard(),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              // Accesos rápidos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(
                    Icons.chat_bubble_outline_rounded,
                    'Chat Ayuda',
                    () {
                      final userId = Provider.of<AuthService>(
                        context,
                        listen: false,
                      ).currentUserId;

                      if (currentResId.isNotEmpty) {
                        _navigateTo(
                          ChatScreen(
                            reservationId: currentResId,
                            currentUserId: userId ?? '',
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Necesitas una reserva para usar el chat.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildQuickAction(Icons.map_outlined, 'Mapa Local', () {
                    // Navegamos al mapa pasando la reserva actual (_reservation)
                    // Si _reservation es null, el mapa mostrará Galicia general.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LocalMapScreen(activeReservation: _reservation),
                      ),
                    );
                  }),
                  _buildQuickAction(
                    Icons.contact_support_outlined,
                    'Contacto',
                    () {
                      Navigator.of(context).pushNamed('/contact');
                    },
                  ),
                ],
              ),
              if (_errorMessage != null && _reservation == null)
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para construir accesos rápidos
  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Widget para construir el menú desplegable (Drawer)
  Widget _buildDrawer(BuildContext context) {
    // Usamos Consumer para escuchar los cambios de AuthService en tiempo real
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Obtenemos los datos directamente del servicio de autenticación
        final String accountNameText =
            'Bienvenido, ${authService.currentUserName ?? 'Cargando nombre...'}';
        final String accountEmailText =
            authService.currentEmail ?? 'Cargando email...';
        final String currentResId = _reservation?.id ?? '';
        // La lógica de la reserva aún depende del estado local (_reservation)
        final bool isCheckinComplete =
            _reservation?.status == 'REGISTRO_COMPLETADO';
        _reservation?.status == 'ACTIVA';
        //_reservationId.isNotEmpty;
        //final bool isReviewAvailable = _reservation?.status == 'COMPLETADA';

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                // Muestra el nombre real del huésped cargado de la BBDD
                accountName: Text(accountNameText),
                // Muestra el email real del cliente registrado cargado de la BBDD
                accountEmail: Text(accountEmailText),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.blue, size: 40),
                ),
                decoration: const BoxDecoration(color: Colors.blue),
              ),
              // --- Opciones Principales ---
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Inicio'),
                onTap: () {
                  Navigator.pop(context); // Cerrar Drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Mis Reservas'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/reservations');
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Buscar Alojamientos'),
                onTap: () {
                  Navigator.pop(context);
                  launchTurisgalWebsite(); //  Llamada a la función del punto 2
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Check-In'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.of(
                    context,
                  ).pushNamed('/checkin');
                  if (result == true) _loadAllData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Check-Out'),
                // La validación y manejo de errores se hace ahora en CheckoutScreen.
                onTap: () async {
                  Navigator.pop(context);
                  if (currentResId.isNotEmpty) {
                    // Usamos la lógica corregida de navegación
                    _navigateTo(CheckoutScreen(reservationId: currentResId));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No tienes una estancia activa para hacer Check-out.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } // Refresca el estado después de volver
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Chat de Soporte'),
                enabled: isCheckinComplete, // Habilitar solo si hay un check-in
                onTap: () {
                  Navigator.pop(context);
                  final userId = authService.currentUserId;

                  if (userId == null || userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario no autenticado.')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        reservationId: currentResId,
                        currentUserId: userId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_border),
                title: const Text('Dejar Reseña'),

                // Solo se habilita si la estancia ha sido completada
                onTap: () {
                  Navigator.pop(context);
                  if (currentResId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReviewScreen(reservationId: currentResId),
                      ),
                    );
                  }
                },
              ),

              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Gestión de Estancia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.contacts_outlined),
                title: const Text('Contacto'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/contact');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _logout(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
