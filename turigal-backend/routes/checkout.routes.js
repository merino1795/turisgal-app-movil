const express = require('express');
const router = express.Router();

// Importamos los controladores necesarios
const checkoutController = require('../controllers/checkout_controller');
const reservationsController = require('../controllers/reservations_controller');
const authenticateToken = require('../middleware/auth_middleware');

// 1. IMPORTAR MULTER Y PATH
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// 2. CONFIGURAR DÓNDE SE GUARDAN LAS FOTOS
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        // Crea la carpeta uploads/checkout si no existe
        const dir = 'uploads/checkout/';
        if (!fs.existsSync(dir)){
            fs.mkdirSync(dir, { recursive: true });
        }
        cb(null, dir);
    },
    filename: function (req, file, cb) {
        // Nombre único: fecha-tipo.jpg
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

// PROTECCIÓN: Todas las rutas de checkout requieren estar logueado
router.use(authenticateToken);

// ==========================================================
// RUTAS DE CHECKOUT
// ==========================================================

// 1. Obtener datos de la reserva para la pantalla de Checkout
// GET /api/checkout/reservations/:id
// Reutilizamos la lógica del controlador de reservas para no duplicar código
router.get('/reservations/:id', checkoutController.getReservationById);

// 2. Subir una foto (Cocina, Baño, etc.)
// POST /api/checkout/photo
router.post('/photo', upload.single('image'), checkoutController.uploadCheckoutPhoto);

// 3. Guardar incidencias (texto)
// POST /api/checkout/incidents
router.post('/incidents', checkoutController.saveCheckoutIncident);

// 4. Finalizar el Checkout
// POST /api/checkout/finalize
router.post('/finalize', checkoutController.finalizeCheckout);

module.exports = router;