
const express = require('express');
const router = express.Router();

const reviewsController = require('../controllers/reviews_controller');
const authenticateToken = require('../middleware/auth_middleware');

// PROTECCIÓN: Solo usuarios logueados pueden reseñar
router.use(authenticateToken);

// POST /api/reviews
router.post('/', reviewsController.createReview);

// GET /api/reviews/:reservationId
router.get('/:reservationId', reviewsController.getReview);

module.exports = router;