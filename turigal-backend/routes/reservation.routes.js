const express = require('express');
const router = express.Router();

// Importamos los controladores que ya tienen la lógica
const reservationController = require('../controllers/reservations_controller');
const authenticateToken = require('../middleware/auth_middleware');

// PROTECCIÓN: Todas estas rutas requieren token de usuario
router.use(authenticateToken);

// --- DEBUG DE EMERGENCIA ---
// Esto imprimirá en la consola si las funciones se cargaron bien o no.
console.log("Cargando controlador de reservas...");
if (!reservationController) {
    console.error("ERROR FATAL: No se encuentra el archivo '../controllers/reservations_controller'");
} else {
    console.log("getActiveReservations:", !!reservationController.getActiveReservations);
    console.log("getHistory:", !!reservationController.getHistory);
    console.log("getReservationById:", !!reservationController.getReservationById);
    console.log("Scraper (getPropertyInfo):", !!reservationController.getPropertyInfo);
}
// ==========================================================
// RUTAS DE CONSULTA (Para el Home y la lista)
// ==========================================================

// 1. Obtener reservas activas (Home)
// GET /api/reservations/active
router.get('/active', authenticateToken, reservationController.getActiveReservations);

// 2. Historial
// URL final: GET /api/reservations/history
router.get('/history', authenticateToken, reservationController.getHistory);
router.get('/info/:id', reservationController.getPropertyInfo);
// 3. Crear reserva (Admin/Pruebas)
router.post('/', authenticateToken, reservationController.createReservation);

// 4. Obtener una reserva por ID (Detalle)
// URL final: GET /api/reservations/TURISGAL-TEST
// IMPORTANTE: Esta debe ir AL FINAL para no confundir 'active' con un ID
router.get('/:id', authenticateToken, reservationController.getReservationById);
module.exports = router;