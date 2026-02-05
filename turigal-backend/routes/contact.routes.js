const express = require('express');
const router = express.Router();

// Importamos el controlador con la lógica de Nodemailer
const contactController = require('../controllers/contact_controller');
const authenticateToken = require('../middleware/auth_middleware');

// PROTECCIÓN (Opcional):
// Si quieres que solo usuarios logueados contacten, descomenta la siguiente línea.
// Si el formulario es público (como para registrarse), déjalo comentado.
router.use(authenticateToken); 

// POST /api/contact
router.post('/', contactController.submitContact);

module.exports = router;