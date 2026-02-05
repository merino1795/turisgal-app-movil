// controllers/reviews_controller.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Endpoint: POST /api/reviews
 * Crea una reseña para una reserva completada.
 */
const createReview = async (req, res) => {
    // req.user viene del middleware de autenticación
    const userId = req.user ? req.user.id : null;
    const { reservationId, rating, comment } = req.body;

    // 1. Validaciones básicas
    if (!userId) {
        return res.status(401).json({ message: 'No autorizado.' });
    }
    if (!reservationId || !rating || rating < 1 || rating > 5) {
        return res.status(400).json({ message: 'Faltan datos o rating inválido (1-5).' });
    }

    try {
        // 2. Verificar que la reserva existe y pertenece al usuario
        // Y opcionalmente que está COMPLETADA
        const reservation = await prisma.reservation.findFirst({
            where: {
                reservationId: reservationId, // ID público (string)
                userId: userId, // Seguridad: El usuario debe ser el dueño
                // status: 'COMPLETADA' // Descomentar para forzar flujo estricto
            }
        });

        if (!reservation) {
            return res.status(404).json({ 
                message: 'Reserva no encontrada, no es tuya o no está lista para reseñar.' 
            });
        }

        // 3. Crear la reseña
        const newReview = await prisma.review.create({
            data: {
                rating: parseInt(rating),
                comment: comment || null,
                userId: userId,
                reservationId: reservation.reservationId
            }
        });

        console.log(`[REVIEW] Reseña creada para ${reservationId} por usuario ${userId}`);
        
        return res.status(201).json({ 
            success: true, 
            data: newReview 
        });

    } catch (error) {
        console.error("Error creating review:", error);
        
        // Error P2002: Unique constraint failed (ya existe reseña para esta reserva)
        if (error.code === 'P2002') {
            return res.status(409).json({ message: 'Ya has dejado una reseña para esta reserva.' });
        }

        return res.status(500).json({ message: "Error interno guardando la reseña." });
    }
};

/**
 * Endpoint: GET /api/reviews/:reservationId
 * Obtiene la reseña de una reserva específica.
 */
const getReview = async (req, res) => {
    const userId = req.user ? req.user.id : null;
    const { reservationId } = req.params;

    if (!userId) return res.status(401).json({ message: 'No autorizado.' });

    try {
        const review = await prisma.review.findFirst({
            where: {
                reservationId: reservationId,
                // userId: userId // Opcional: Si quieres que solo el dueño la vea
            },
            include: {
                user: { select: { nombre: true, apellido: true } }
            }
        });

        if (!review) {
            return res.status(404).json({ message: 'Reseña no encontrada.' });
        }

        return res.status(200).json(review);

    } catch (error) {
        console.error("Error fetching review:", error);
        return res.status(500).json({ message: "Error interno." });
    }
};

module.exports = { createReview, getReview };