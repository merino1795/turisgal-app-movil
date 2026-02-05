// controllers/chat_controller.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Constantes de Soporte
const SUPPORT_ID = 'turigal-support-agent-1';
const SUPPORT_NAME = 'Soporte Turigal';

/**
 * Función auxiliar para generar respuestas simuladas (Chatbot Básico)
 */
function generarRespuestaSimulada(textoUsuario, reservationId) {
    const texto = textoUsuario.toLowerCase();

    // 1. Respuestas por palabras clave
    if (texto.includes('precio') || texto.includes('coste') || texto.includes('pagar') || texto.includes('factura')) {
        return 'Para consultar detalles de pago y facturación, revisa la sección "Mis Reservas" o tu email.';
    }
    if (texto.includes('check-in') || texto.includes('entrada') || texto.includes('llegada')) {
        return 'El Check-in es digital desde el menú principal. Puedes acceder al alojamiento a partir de las 15:00h.';
    }
    if (texto.includes('cancelar') || texto.includes('anular') || texto.includes('modificar')) {
        return `Para cambios en la reserva ${reservationId}, revisa la política de cancelación en la app.`;
    }
    if (texto.includes('wifi') || texto.includes('internet') || texto.includes('contraseña')) {
        return 'La clave WiFi está en el manual de bienvenida dentro del alojamiento.';
    }
    if (texto.includes('horario') || texto.includes('atencion')) {
        return 'Soporte telefónico: L-V de 9:00 a 18:00. Urgencias por este chat 24/7.';
    }
    if (texto.includes('check-out') || texto.includes('salida')) {
        return 'Para el Check-out, usa la opción en el menú principal antes de las 11:00h.';
    }
    if (texto.includes('incidencia') || texto.includes('daño') || texto.includes('avería')) {
        return 'Reporta incidencias graves en la pantalla de Check-out adjuntando fotos.';
    }
    if (texto.includes('hola') || texto.includes('buenos')) {
        return '¡Hola! Soy el asistente virtual de Turigal. ¿En qué puedo ayudarte?';
    }

    // Respuesta por defecto
    return 'Entendido. Un agente revisará tu consulta y te responderá en breve.';
}

/**
 * POST /api/chat/send
 * Guarda el mensaje del usuario y genera una respuesta automática.
 */
const sendMessage = async (req, res) => {
    const { reservationId, text } = req.body;
    // req.user viene del middleware de autenticación
    const userId = req.user ? req.user.id : null; 

    if (!userId || !reservationId || !text) {
        return res.status(400).json({ message: 'Faltan datos.' });
    }

    try {
        // 1. Obtener nombre del usuario para guardarlo en el mensaje
        const user = await prisma.user.findUnique({ where: { id: userId } });
        const senderName = user ? `${user.nombre} ${user.apellido || ''}`.trim() : 'Usuario';

        // 2. Guardar mensaje del usuario
        const userMsg = await prisma.chatMessage.create({
            data: {
                reservationId,
                senderId: userId.toString(),
                senderName: senderName,
                text: text,
                createdAt: new Date()
            }
        });

        // 3. Generar respuesta automática
        const aiText = generarRespuestaSimulada(text, reservationId);

        // 4. Guardar respuesta de la IA (con un pequeño retardo simulado si quieres)
        await prisma.chatMessage.create({
            data: {
                reservationId,
                senderId: SUPPORT_ID,
                senderName: SUPPORT_NAME,
                text: aiText,
                createdAt: new Date()
            }
        });

        // Devolvemos el mensaje del usuario (la app mostrará el de la IA al refrescar o por socket)
        return res.status(201).json(userMsg);

    } catch (error) {
        console.error("Error chat:", error);
        return res.status(500).json({ error: "Error enviando mensaje." });
    }
};

/**
 * GET /api/chat/history/:reservationId
 * Obtiene todos los mensajes de una reserva.
 */
const getHistory = async (req, res) => {
    const { reservationId } = req.params;
    
    try {
        let messages = await prisma.chatMessage.findMany({
            where: { reservationId },
            orderBy: { createdAt: 'asc' }
        });

        // Si es el primer mensaje, mandamos bienvenida
        if (messages.length === 0) {
            const welcomeMsg = await prisma.chatMessage.create({
                data: {
                    reservationId,
                    senderId: SUPPORT_ID,
                    senderName: SUPPORT_NAME,
                    text: `¡Hola! Gracias por contactar sobre la reserva ${reservationId}. ¿Cómo podemos ayudarte?`,
                    createdAt: new Date()
                }
            });
            messages = [welcomeMsg];
        }

        return res.json(messages);
    } catch (error) {
        console.error("Error historial:", error);
        return res.status(500).json({ error: "Error cargando historial." });
    }
};

module.exports = { sendMessage, getHistory };