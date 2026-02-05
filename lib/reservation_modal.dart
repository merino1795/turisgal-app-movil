class Reservation {
  final String
  id; // Convertimos el Int de la DB a String para facilitar uso en UI
  final String reservationId; // El ID público (Ej: RES-001)
  final String propertyName;
  final String status;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalPrice;
  final int guests;
  final double? latitude;
  final double? longitude;

  // Datos de Check-out
  final List<String> uploadedPhotos;
  final String? incidents;

  final Map<String, dynamic>? checkinProcess;

  Reservation({
    required this.id,
    required this.reservationId,
    required this.propertyName,
    required this.status,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalPrice,
    required this.guests,
    required this.uploadedPhotos,
    this.incidents,
    this.checkinProcess,
    this.latitude, // Añadir al constructor
    this.longitude, // Añadir al constructor
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      // 1. Manejo seguro de IDs (DB envía Int, App usa String)
      id: json['id']?.toString() ?? '0',
      reservationId: json['reservationId']?.toString() ?? 'Sin ID',

      propertyName: json['propertyName']?.toString() ?? 'Alojamiento Turigal',

      // 2. Mapeo de estado usando la función auxiliar
      status: _mapStatus(json['status']),

      // 3. Fechas reales (Evitamos el null)
      checkInDate: json['checkInDate'] != null
          ? DateTime.parse(json['checkInDate'])
          : DateTime.now(),
      checkOutDate: json['checkOutDate'] != null
          ? DateTime.parse(json['checkOutDate'])
          : DateTime.now().add(const Duration(days: 1)),

      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,

      guests: json['guests'] is int ? json['guests'] : 1,

      // 4. Listas y Check-out
      uploadedPhotos:
          (json['uploadedPhotos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      incidents: json['incidents']?.toString(),

      // 5. CONEXIÓN CRÍTICA CON EL BACKEND
      // Aquí recogemos lo que el servidor envía como 'checkinProcess'
      checkinProcess: json['checkinProcess'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  // --- Lógica para traducir los estados de la BD a los de la App ---
  static String _mapStatus(dynamic rawStatus) {
    final status = rawStatus?.toString().toUpperCase().trim() ?? '';

    // Mapeamos los estados de Prisma (ReservationStatus) a los de la UI
    switch (status) {
      case 'PENDIENTE_INICIO':
      case 'PENDIENTE':
        return 'PENDIENTE'; // Mostrar botón "Hacer Check-in"

      case 'REGISTRO_COMPLETADO':
      case 'IDENTIDAD_VERIFICADA':
        return 'REGISTRO_COMPLETADO'; // Mostrar botón "Check-out" o "Ver Info"

      case 'PENDIENTE_REVISION':
        return 'PENDIENTE_REVISION';

      case 'COMPLETADA':
        return 'COMPLETADA'; // Historial

      case 'CANCELADA':
        return 'CANCELADA';

      default:
        return 'PENDIENTE';
    }
  }
}
