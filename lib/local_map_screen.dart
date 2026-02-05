import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // El mapa nuevo
import 'package:latlong2/latlong.dart'; // Para coordenadas
import 'package:turigal/reservation_modal.dart';

class LocalMapScreen extends StatefulWidget {
  final Reservation? activeReservation;

  const LocalMapScreen({super.key, this.activeReservation});

  @override
  State<LocalMapScreen> createState() => _LocalMapScreenState();
}

class _LocalMapScreenState extends State<LocalMapScreen> {
  // 1. EL MANDO A DISTANCIA DEL MAPA
  final MapController _mapController = MapController();

  // Coordenadas por defecto (Solo se usan si NO hay reserva activa)
  final LatLng _galiciaCenter = const LatLng(42.8782, -8.5448);

  // Variables dinámicas (se llenarán con datos reales)
  late LatLng _initialCenter;
  late double _initialZoom;
  bool _hasSpecificLocation = false; // Bandera para saber si pintar marcador

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  // --- LÓGICA REAL: Usamos los datos del objeto Reservation ---
  void _setupMapData() {
    // 1. Comprobamos si el objeto reserva existe
    // 2. Comprobamos si tiene latitud y longitud (que vienen de la BD)
    if (widget.activeReservation != null &&
        widget.activeReservation!.latitude != null &&
        widget.activeReservation!.longitude != null) {
      // CASO REAL: Usamos las coordenadas de la base de datos
      _hasSpecificLocation = true;
      _initialCenter = LatLng(
        widget.activeReservation!.latitude!,
        widget.activeReservation!.longitude!,
      );
      _initialZoom = 16.0; // Zoom cercano para ver la casa
    } else {
      // CASO GENÉRICO: No hay reserva o la BD no tiene coordenadas
      _hasSpecificLocation = false;
      _initialCenter = _galiciaCenter;
      _initialZoom = 8.0; // Zoom lejano
    }
  }

  // --- FUNCIONES DE ZOOM ---
  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Si hay ubicación exacta, mostramos el nombre del apartamento en el título
        title: Text(
          _hasSpecificLocation
              ? (widget.activeReservation?.propertyName ?? 'Ubicación')
              : 'Mapa Local',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // 2. BOTONES FLOTANTES DE ZOOM (+ y -)
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "zoomIn",
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _zoomIn,
            child: const Icon(Icons.add, color: Colors.deepOrange),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "zoomOut",
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _zoomOut,
            child: const Icon(Icons.remove, color: Colors.deepOrange),
          ),
        ],
      ),

      body: FlutterMap(
        // 3. VINCULAMOS EL CONTROLADOR
        mapController: _mapController,

        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: _initialZoom,
          minZoom: 5.0,
          maxZoom: 18.5,
        ),
        children: [
          // CAPA 1: MAPA
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.turisgal.app',
            additionalOptions: const {'attribution': '© OpenStreetMap'},
          ),

          // CAPA 2: MARCADORES (Solo si tenemos ubicación real)
          if (_hasSpecificLocation)
            MarkerLayer(
              markers: [
                Marker(
                  point: _initialCenter,
                  width: 120, // Un poco más ancho para el texto
                  height: 90,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.deepOrange,
                        size: 45,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(blurRadius: 3, color: Colors.black26),
                          ],
                        ),
                        child: Text(
                          // LÓGICA DE TEXTO INTELIGENTE
                          (widget.activeReservation?.status ==
                                      'REGISTRO_COMPLETADO' ||
                                  widget.activeReservation?.status == 'ACTIVA')
                              ? "¡Aquí estás!" // Si ya hizo check-in
                              : "Tu Alojamiento", // Si aún va de camino
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // CAPA 3: CRÉDITOS
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      ),
    );
  }
}
