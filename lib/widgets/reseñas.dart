import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Usamos el ApiService para enviar los datos

class ReviewScreen extends StatefulWidget {
  // ✅ DATO DINÁMICO: ID de la reserva que estamos valorando.
  // Viene desde el HomePage -> Tarjeta de Estado -> Botón "Dejar Reseña".
  final String reservationId;

  const ReviewScreen({Key? key, required this.reservationId}) : super(key: key);

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ApiService _apiService = ApiService(); // Instancia del servicio API
  int _rating = 0; // Puntuación de la reseña
  String _comment = ''; // Comentario de la reseña
  bool _isLoading = false; // Estado de carga al enviar la reseña
  String? _errorMessage; // Mensaje de error si ocurre algún problema

  void _setRating(int rating) {
    // Actualiza la puntuación seleccionada
    setState(() {
      // Usamos setState para actualizar la UI
      _rating = rating; // Actualiza la puntuación
    });
  }

  // Envía la reseña al backend
  Future<void> _submitReview() async {
    // Método asíncrono para enviar la reseña
    // Validación local: Debe haber al menos una estrella
    if (_rating == 0) {
      setState(() {
        _errorMessage = 'Por favor, selecciona una puntuación antes de enviar.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Llamada a la API real pasando el ID dinámico
    // Esto conectará con tu tabla 'Review' en la base de datos
    try {
      bool success = await _apiService.submitReview(
        widget.reservationId, // ID único de la reserva
        _rating,
        _comment,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (success) {
            // Éxito: Mensaje y volver atrás
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⭐ ¡Reseña enviada con éxito! Gracias.'),
              ),
            );
            Navigator.pop(context); // Volver a la pantalla principal
          } else {
            _errorMessage = 'Error desconocido al enviar la reseña.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error de conexión: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valora tu Estancia'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white, // Color de iconos y texto de retorno
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Titulo
            Text(
              'Ayúdanos a mejorar tu experiencia',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            // Puntuación con estrellas
            _buildRatingStars(),
            const SizedBox(height: 30),
            // Campo de comentario
            _buildCommentField(),
            const SizedBox(height: 30),
            // Mensaje de error si existe
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign
                      .center, // CORREGIDO: Movido a la propiedad directa del widget Text
                  style: const TextStyle(
                    color: Colors.red,
                  ), // Eliminado de TextStyle
                ),
              ),

            // Botón de enviar reseña
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : _submitReview, // Deshabilita el botón si está cargando
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isLoading ? 'Enviando...' : 'Enviar Reseña',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construye las estrellas para la puntuación
  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        // Lógica visual: Si el índice es menor que la puntuación actual, pinta llena
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 40,
          ),
          onPressed: () => _setRating(index + 1), // 1-based index
        );
      }),
    );
  }

  // Campo de texto para el comentario
  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comentario (Opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextFormField(
          onChanged: (value) => _comment = value,
          maxLines: 5, // Permite escribir varios párrafos
          decoration: const InputDecoration(
            hintText: '¿Qué te pareció tu estancia?',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
