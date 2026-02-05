const express = require('express');
const router = express.Router();

// Importamos el controlador que maneja la lógica de seguridad
const passwordController = require('../controllers/password_controller');

// ==========================================================
// RUTAS DE RECUPERACIÓN DE CONTRASEÑA
// ==========================================================

// 1. Solicitar reseteo (Envía el PIN al email/teléfono)
// POST /api/password/request-reset
router.post('/request-reset', passwordController.requestReset);

// 2. Verificar el PIN introducido
// POST /api/password/verify-token
router.post('/verify-token', passwordController.verifyToken);

// 3. Actualizar la contraseña (usando la clave segura generada en el paso 2)
// POST /api/password/update
router.post('/update', passwordController.updatePassword);

module.exports = router;