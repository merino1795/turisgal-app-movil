
const { PrismaClient } = require('@prisma/client');
const { getReservationById } = require('./reservations_controller');
const prisma = new PrismaClient();

/**
 * -------------------------------------------------------
 * 1. SUBIR FOTO DE CHECKOUT (Base64)
 * -------------------------------------------------------
 * Endpoint: POST /api/checkout/photo
 * Descripción: Recibe una imagen en Base64 desde Flutter y la guarda en la BD.
 * Devuelve la lista actualizada de fotos subidas para refrescar la UI.
 */
const uploadCheckoutPhoto = async (req, res) => {
    try {
        console.log("[BACKEND] Recibiendo subida de foto...");

        if (!req.file) {
            return res.status(400).json({ error: "No se recibió ningún archivo de imagen." });
        }

        const { reservationId, photoType } = req.body;

        if (!reservationId || !photoType) {
            return res.status(400).json({ error: "Falta reservationId o photoType." });
        }

        const fileUrl = `/uploads/checkout/${req.file.filename}`;
        console.log(`Archivo guardado en: ${fileUrl}`);

        const reservation = await prisma.reservation.findUnique({
            where: { reservationId: reservationId } 
        });

        if (!reservation) {
            return res.status(404).json({ error: "Reserva no encontrada." });
        }

        let currentPhotos = reservation.uploadedPhotos || [];
        if (!currentPhotos.includes(photoType)) {
            currentPhotos.push(photoType);
        }

        await prisma.reservation.update({
            where: { reservationId: reservationId }, 
            data: { 
                uploadedPhotos: currentPhotos,
            }
        });

        return res.json({
            success: true,
            message: `Foto de ${photoType} subida correctamente.`,
            uploadedPhotos: currentPhotos
        });

    } catch (error) {
        console.error("Error en uploadCheckoutPhoto:", error);
        return res.status(500).json({ error: "Error interno subiendo foto." });
    }
};

/**
 * -------------------------------------------------------
 * 2. GUARDAR INCIDENCIAS
 * -------------------------------------------------------
 * Endpoint: POST /api/checkout/incidents
 * Descripción: Guarda el texto de reporte de daños.
 */
const saveCheckoutIncident = async (req, res) => {
    try {
        const { reservationId, incidentText } = req.body;

        if (!reservationId) {
            return res.status(400).json({ error: "Falta reservationId" });
        }

        await prisma.reservation.update({
            where: { reservationId: reservationId }, 
            data: {
                incidents: incidentText || ""
            }
        });

        return res.status(200).json({ success: true, message: "Incidencia registrada." });

    } catch (error) {
        console.error("Error en saveCheckoutIncident:", error);
        return res.status(500).json({ error: "Error al guardar incidencia." });
    }
};

// -------------------------------------------------------
// 3. FINALIZAR EL CHECKOUT (CORREGIDO)
// -------------------------------------------------------
const finalizeCheckout = async (req, res) => {
    try {
        const { reservationId, incidents } = req.body;

        if (!reservationId) {
            return res.status(400).json({ error: "Falta reservationId" });
        }

        console.log(`🏁 Finalizando checkout para: ${reservationId}`);

        await prisma.reservation.update({
            where: { reservationId: reservationId }, 
            data: {
                checkOutDate: new Date(),
                status: "COMPLETADA", 
                updatedAt: new Date(),
                ...(incidents && { incidents: incidents }) 
            }
        });

        return res.status(200).json({ 
            success: true, 
            message: "Checkout completado correctamente." 
        });

    } catch (error) {
        console.error("Error en finalizeCheckout:", error);
        return res.status(500).json({ error: "Error interno al finalizar checkout." });
    }
};

module.exports = {
    uploadCheckoutPhoto,
    saveCheckoutIncident,
    finalizeCheckout,
    getReservationById
};