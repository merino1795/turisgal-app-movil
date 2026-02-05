const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chat_controller');
const authenticateToken = require('../middleware/auth_middleware');

// Todas las rutas de chat requieren estar logueado
router.use(authenticateToken);

// POST /api/chat/send -> Enviar mensaje
router.post('/send', chatController.sendMessage);

// GET /api/chat/history/:reservationId -> Ver historial
router.get('/history/:reservationId', chatController.getHistory);

module.exports = router;