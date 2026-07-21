const express = require('express');
const router = express.Router();
const { getCurrentWeather } = require('../controllers/weatherController');

/**
 * GET /api/weather?lat={lat}&lon={lon}
 * Ambil data cuaca terkini dari Open-Meteo API
 */
router.get('/', getCurrentWeather);

module.exports = router;
