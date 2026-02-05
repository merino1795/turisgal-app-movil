// controllers/public_controller.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * -------------------------------------------------------
 * CREAR RESERVA DESDE EXTERNO (WEB/WEBHOOK)
 * -------------------------------------------------------
 * Endpoint: POST /api/public/new-reservation
 * Descripción: Recibe datos de una reserva nueva (ej. desde la web de Turisgal)
 * y la guarda en la base de datos para que el usuario la vea en su App.
 */
const createReservation = async (req, res) => {
    const { 
        reservationId, 
        bookingEmail, 
        propertyName,
        nombre,
        apellido,
        checkInDate, 
        checkOutDate, 
        guests
    } = req.body;

    // 1. Validación Básica
    if (!reservationId || !bookingEmail || !propertyName || !checkInDate || !checkOutDate) {
        return res.status(400).json({ 
            message: 'Faltan campos esenciales (ID, Email, Propiedad, Fechas).' 
        });
    }

    try {
        // 2. Buscar si el usuario ya usa la App (por email)
        // Nota: Asegúrate de que tu tabla se llame 'user' o 'usuario' en schema.prisma.
        // Aquí uso 'user' para mantener consistencia con auth_controller.js.
        const existingUser = await prisma.user.findUnique({
            where: { email: bookingEmail },
            select: { id: true }
        });

        // 3. Crear la Reserva
        const newReservation = await prisma.reservation.create({
            data: {
                // Mapeo directo de campos
                id: reservationId, // O reservationId según tu schema
                bookingEmail: bookingEmail,
                propertyName: propertyName,
                guestName: `${nombre} ${apellido}`.trim(), // Concatenamos para simplificar visualización
                
                // Conversión de fechas (JS necesita objetos Date)
                checkInDate: new Date(checkInDate),
                checkOutDate: new Date(checkOutDate),
                
                guests: parseInt(guests) || 1,
                
                // Vinculación opcional: Si el usuario existe, conectamos la reserva a su ID.
                // Si no, userId se queda en null (la verá cuando se registre con ese email).
                userId: existingUser ? existingUser.id : null,
                
                // Valores por defecto
                status: "PENDIENTE_INICIO", // String directo en lugar de Enum TS
                uploadedPhotos: [], 
                incidents: null
            }
        });

        console.log(`[PUBLIC API] Nueva reserva creada: ${reservationId} para ${bookingEmail}`);
        
        return res.status(201).json({ 
            message: 'Reserva registrada con éxito.', 
            id: newReservation.id 
        });

    } catch (error) {
        // Manejo de duplicados (Error P2002 de Prisma)
        if (error.code === 'P2002') {
            return res.status(409).json({ 
                message: `La reserva con ID ${reservationId} ya existe.` 
            });
        }
        
        console.error('Error creando reserva externa:', error);
        return res.status(500).json({ message: 'Error interno del servidor.' });
    }
};

module.exports = { createReservation };