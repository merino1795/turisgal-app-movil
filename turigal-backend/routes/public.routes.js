
const express = require('express');
const router = express.Router();

// Importamos el controlador
const publicController = require('../controllers/public_controller');

// ==========================================================
// RUTAS PÚBLICAS (SIN TOKEN DE USUARIO)
// ==========================================================

// POST /api/public/new-reservation
router.post('/new-reservation', publicController.createReservation);

module.exports = router;