import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Conexion con el backend
import 'dart:async'; // Para Timer (actualizacion automatica)

// Modelo de mensaje de chat
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Convierte el JSON del servidor en un objeto Dart
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // 1: Asegurar ID unico (si el server no lo manda, generamos uno temporal)
    final String messageId =
        json['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    // 2. Procesar la fecha de forma robusta (soporta texto ISO o números)
    DateTime parsedTimestamp;
    final dynamic createdAt = json['createdAt'];

    if (createdAt is String) {
      try {
        parsedTimestamp = DateTime.parse(createdAt);
      } catch (e) {
        parsedTimestamp = DateTime.now();
      }
    } else if (createdAt is num) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(createdAt.toInt());
    } else {
      parsedTimestamp = DateTime.now();
    }

    // 3. Determinar quién envía el mensaje
    final String senderId = json['senderId']?.toString() ?? '';
    final String text = json['text']?.toString() ?? 'Mensaje vacío o nulo';

    // Si el ID es 'ai' o 'support', ponemos nombre bonito. Si no, usamos el del JSON
    final String senderName =
        json['senderName']?.toString() ??
        (senderId == 'ai' ? 'Soporte IA' : 'Usuario');

    return ChatMessage(
      id: messageId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: parsedTimestamp,
    );
  }
}

// Pantalla principal del chat
class ChatScreen extends StatefulWidget {
  // Variables dinamicas: se pasan desde el home, no estan escritas aqui
  final String reservationId;
  final String currentUserId;

  const ChatScreen({
    Key? key,
    required this.reservationId, // ID único de la reserva (ej: TUR-123)
    required this.currentUserId, // ID del usuario actual
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService(); // Instancia del servicio
  final TextEditingController _controller =
      TextEditingController(); // Control del input
  final ScrollController _scrollController =
      ScrollController(); // Control del scroll

  List<ChatMessage> _messages = []; // Lista local de mensajes
  bool _isLoading = false; // Cargando inicial
  bool _isSending = false; // Bloqueo mientras se envía

  // Variables para la actualización automática (Polling)
  Timer? _pollingTimer;
  int _initialMessageCount = 0;

  @override
  void initState() {
    super.initState(); // Aquí asignas el userId real
    print('DEBUG API: _currentUserId asignado: ${widget.currentUserId}');
    _fetchMessages(); // Cargar mensajes al iniciar
  }

  // Al cerrar el chat, limpiamos memoria y timers
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel(); // IMPORTANTE: Parar el timer si salimos
    super.dispose();
  }

  // Obtener historial de mensajes desde el backend
  Future<void> _fetchMessages() async {
    // Solo mostramos círculo de carga si la lista está vacía
    if (_messages.isEmpty) setState(() => _isLoading = true);

    try {
      // Llamada al backend usando el reservationId dinámico
      List<ChatMessage> fetchedMessages = await _apiService.fetchChatHistory(
        widget.reservationId,
      );

      // Ordenar por fecha (más viejos arriba, más nuevos abajo
      fetchedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (mounted) {
        setState(() {
          _messages = fetchedMessages;
          _isLoading = false;
        });
        // Bajar el scroll al último mensaje
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Error cargando chat: $e');
      }
    }
  }

  // LÓGICA DE POLLING (Escuchar respuesta de la IA)
  void _startPollingForAiResponse() {
    _initialMessageCount = _messages.length;

    // Ejecuta este código cada 1.5 segundos
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      // Pedimos al servidor la lista actualizada
      await _fetchMessages();

      // Si hay más mensajes que antes, asumimos que llegó la respuesta
      if (_messages.length > _initialMessageCount) {
        _pollingTimer?.cancel(); // Paramos el polling
        if (mounted) {
          setState(() => _isSending = false); // Desbloqueamos el input
          _scrollToBottom();
        }
      }
    });
  }

  // Enviar mensaje al backend
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear(); // Limpiar input
    FocusScope.of(context).unfocus(); // Ocultar teclado

    // 1. Optimistic UI: Añadimos el mensaje visualmente antes de que el servidor responda
    final userMessage = ChatMessage(
      senderId: widget.currentUserId,
      senderName: 'Tú',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isSending = true; // Bloqueamos input mientras se procesa
      _messages.add(userMessage);
    });
    _scrollToBottom();

    // 2. Llama al backend para enviar el mensaje del usuario (el backend guarda la IA síncronamente).
    try {
      await _apiService.sendMessage(widget.reservationId, text);

      // 3. Esperar respuesta (inicia el polling)
      _startPollingForAiResponse();
    } catch (e) {
      print('Error al enviar el mensaje: $e');
      // Si falla, quitamos el mensaje y avisamos
      setState(() {
        _isSending = false;
        _messages.remove(userMessage);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar el mensaje. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  // Función para bajar el scroll automáticamente
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- INTERFAZ VISUAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Turisgal'),
        backgroundColor: Colors.indigo.shade400, // Color unificado
        elevation: 1,
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i]),
                  ),
          ),
          // Caja de texto
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Burbuja de mensaje individual
  Widget _buildMessageBubble(ChatMessage message) {
    // Comparamos el ID del mensaje con el ID del usuario logueado para saber el lado (Izq/Der)
    final bool isMe = message.senderId == widget.currentUserId;
    final Color botColor = isMe
        ? Colors.indigo.shade400
        : Colors.grey.shade100; // Gris claro para el bot/otro usuario
    final Color textColor = isMe ? Colors.white : Colors.black87;
    print(
      'DEBUG: message.senderId=${message.senderId}, currentUserId=${widget.currentUserId}',
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: botColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              // Texto del mensaje
              Text(
                message.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            // Hora del mensaje
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Caja de texto para enviar mensajes
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isSending, // Deshabilitar mientras se espera la IA
              decoration: InputDecoration.collapsed(
                hintText: _isSending
                    ? 'Enviando y esperando respuesta (2s)...'
                    : 'Escribe tu mensaje...',
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: _isSending
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.indigo,
                    ),
                  )
                : const Icon(Icons.send, color: Colors.indigo),
            onPressed: _isSending
                ? null
                : _sendMessage, // Deshabilitar si está enviando
          ),
        ],
      ),
    );
  }
}
