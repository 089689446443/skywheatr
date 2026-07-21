const express = require('express');
const router = express.Router();
const {
  getAllLocations,
  getLocationById,
  createLocation,
  updateLocation,
  deleteLocation,
  setPrimaryLocation,
} = require('../controllers/locationController');

router.get('/',         getAllLocations);
router.get('/:id',      getLocationById);
router.post('/',        createLocation);
router.put('/:id',      updateLocation);
router.delete('/:id',   deleteLocation);
router.patch('/:id/primary', setPrimaryLocation);

module.exports = router;
