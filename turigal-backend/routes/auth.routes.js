const express = require('express');
const router = express.Router();

// Importamos el controlador que creamos en el paso anterior
const authController = require('../controllers/auth_controller');

// Importamos el middleware de autenticación
const authenticateToken = require('../middleware/auth_middleware');

// --- RUTAS PÚBLICAS ---

// POST /api/auth/register -> Crea un usuario nuevo
router.post('/register', authController.register);

// POST /api/auth/login -> Inicia sesión y devuelve token
router.post('/login', authController.login);

// --- RUTAS PROTEGIDAS ---

// GET /api/auth/profile -> Obtiene datos del usuario (requiere token)
router.get('/profile', authenticateToken, authController.getProfile);

module.exports = router;