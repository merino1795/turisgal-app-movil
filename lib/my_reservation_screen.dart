import 'package:flutter/material.dart';
import 'package:turigal/services/api_service.dart';
import 'package:turigal/services/reservations_service.dart';
import 'package:turigal/reservation_modal.dart';
import 'package:turigal/property_info_screen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  final ReservationsService _reservationsService = ReservationsService();
  final ApiService _apiService = ApiService();
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRealReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRealReservations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print("Iniciando carga de reservas...");
      // 1. Pedimos las ACTIVAS
      final activeJson = await _reservationsService.getActiveReservations();

      // 2. Pedimos el HISTORIAL (Esto es lo que faltaba)
      final historyJson = await _reservationsService.getHistoryReservations();

      print("Activas recibidas (JSON): ${activeJson.length}");
      print("Historial recibido (JSON): ${historyJson.length}");
      // 3. Convertimos los JSON a objetos Reservation
      // (Asumiendo que tienes un Reservation.fromJson, si no, usamos el mapper manual abajo)
      final List<Reservation> activeList = [];
      for (var item in activeJson) {
        try {
          activeList.add(_mapJsonToReservation(item));
        } catch (e) {
          print("Error procesando reserva activa: $e");
        }
      }
      final List<Reservation> historyList = [];
      for (var item in historyJson) {
        try {
          historyList.add(_mapJsonToReservation(item));
        } catch (e) {
          print("Error procesando reserva historial: $e\nDatos: $item");
        }
      }

      if (mounted) {
        setState(() {
          // 4. Combinamos todo en una sola lista para que tus filtros funcionen
          _reservations = [...activeList, ...historyList];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando reservas: $e");
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar tus reservas.';
          _isLoading = false;
        });
      }
    }
  }

  // Helper manual por si tu ReservationModal no tiene .fromJson robusto
  Reservation _mapJsonToReservation(Map<String, dynamic> json) {
    // Conversión segura de precio (acepta int o double)
    double safePrice = 0.0;
    if (json['totalPrice'] != null) {
      safePrice = (json['totalPrice'] is int)
          ? (json['totalPrice'] as int).toDouble()
          : (json['totalPrice'] as double);
    }
    return Reservation(
      id: json['id']?.toString() ?? '0',
      reservationId: json['reservationId']?.toString() ?? '',
      propertyName: json['propertyName']?.toString() ?? 'Apartamento',
      // Mapeo seguro de fechas
      checkInDate: json['checkInDate'] != null
          ? DateTime.tryParse(json['checkInDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      checkOutDate: json['checkOutDate'] != null
          ? DateTime.tryParse(json['checkOutDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? 'PENDIENTE',
      // Añade aquí más campos si tu modelo los requiere (ej: guests, price...)
      guests: int.tryParse(json['guests']?.toString() ?? '1') ?? 1,

      totalPrice: safePrice,
      // Listas vacías por defecto en el mapeo manual
      uploadedPhotos: [],
      incidents: null,
      // Pasamos el objeto checkin tal cual, verificando que sea un Mapa
      checkinProcess: (json['checkinProcess'] is Map)
          ? json['checkinProcess'] as Map<String, dynamic>
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  List<Reservation> _getFilteredList(bool isHistory) {
    return _reservations.where((res) {
      final isCompleted =
          res.status == 'COMPLETADA' ||
          res.status == 'CANCELADA' ||
          res.status == 'PENDIENTE_REVISION';
      return isHistory ? isCompleted : !isCompleted;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Mis Reservas',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFF4F46E5),
          tabs: const [
            Tab(text: 'Activas'),
            Tab(text: 'Historial'),
          ],
          onTap: (_) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoading ? null : _loadRealReservations,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationList(isHistory: false),
          _buildReservationList(isHistory: true),
        ],
      ),
    );
  }

  Widget _buildReservationList({required bool isHistory}) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            TextButton(
              onPressed: _loadRealReservations,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final filteredList = _getFilteredList(isHistory);

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHistory ? Icons.history : Icons.calendar_today,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isHistory
                  ? 'No hay historial disponible.'
                  : 'No tienes reservas activas.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRealReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (ctx, index) => _ReservationCard(
          reservation: filteredList[index],
          onRefresh: _loadRealReservations,
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onRefresh;

  const _ReservationCard({required this.reservation, required this.onRefresh});

  // --- FUNCIÓN CLAVE: CARGA DATOS REALES ANTES DE NAVEGAR ---
  Future<void> _handleViewApartment(BuildContext context) async {
    // 1. Mostrar loading circular
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      // 2. Llamada al API Scraper que creamos
      final api = ApiService();
      print('DEBUG: Solicitando info para el ID: ${reservation.reservationId}');
      final data = await api.getPropertyInfo(reservation.reservationId ?? '');

      if (context.mounted) Navigator.pop(context); // Quitar loading

      // 3. Abrir pantalla con datos reales del Scraper
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyInfoScreen(
              propertyName: data['propertyName'] ?? reservation.propertyName,
              inventory: List<String>.from(data['inventory'] ?? []),
              description: data['description'] ?? 'Sin descripción.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Quitar loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener datos del apartamento: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    if (status.contains('PENDIENTE')) return Colors.orange;
    if (status.contains('COMPLETADA')) return Colors.green;
    if (status.contains('CANCELADA')) return Colors.red;
    if (status == 'REGISTRO_COMPLETADO') return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reservation.status);
    final bool isCheckinDone =
        reservation.status == 'REGISTRO_COMPLETADO' ||
        reservation.status == 'COMPLETADA';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        reservation.propertyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      status: reservation.status,
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DateItem(label: 'ENTRADA', date: reservation.checkInDate),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
                    _DateItem(label: 'SALIDA', date: reservation.checkOutDate),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    if (isCheckinDone)
                      Expanded(
                        child: _ActionButton(
                          label: 'Ver Apartamento',
                          icon: Icons.apartment,
                          color: const Color(0xFF4F46E5),
                          onPressed: () => _handleViewApartment(context),
                        ),
                      ),
                    if (isCheckinDone) const SizedBox(width: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DateItem extends StatelessWidget {
  final String label;
  final DateTime? date;
  const _DateItem({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date != null
              ? '${date!.day}/${date!.month}/${date!.year}'
              : '--/--/--',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final bool isOutlined;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    this.isOutlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: isOutlined ? Colors.black54 : textColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isOutlined
              ? BorderSide(color: Colors.grey.shade300)
              : BorderSide.none,
        ),
      ),
    );
  }
}
