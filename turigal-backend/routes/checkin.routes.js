const express = require('express');
const router = express.Router();

// Importamos el controlador donde ya definimos toda la lógica (incluyendo las simulaciones)
const checkinController = require('../controllers/checkin_controller');

// ==========================================================
// RUTA DE DIAGNÓSTICO
// ==========================================================
router.get('/test-status', (req, res) => {
    res.status(200).json({ message: "Check-in router online y funcionando." });
});

// ==========================================================
// FLUJO DE CHECK-IN
// ==========================================================

// PASO 1: Validar Reserva (Escaneo de QR)
// POST /api/checkin/validate-reservation
router.post('/validate-reservation', checkinController.validateReservation);

// PASO 2: Verificar Identidad (Fotos DNI + Selfie)
// POST /api/checkin/verify-identity
router.post('/verify-identity', checkinController.verifyIdentity);

// PASO 3: Firmar y Finalizar
// POST /api/checkin/submit-signature
router.post('/submit-signature', checkinController.submitSignature);

module.exports = router;