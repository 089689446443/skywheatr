const axios = require('axios');

/**
 * GET /api/geocode?q={nama_kota}&lang=id
 * Cari nama kota/daerah → koordinat via Open-Meteo Geocoding API
 * Gratis, tanpa API key
 */
async function searchLocation(req, res) {
  try {
    const { q, lang = 'id' } = req.query;

    if (!q || q.trim().length < 2) {
      return res.status(400).json({
        success: false,
        message: 'Parameter q (nama kota) minimal 2 karakter.',
      });
    }

    const response = await axios.get('https://geocoding-api.open-meteo.com/v1/search', {
      params: {
        name: q.trim(),
        count: 8,
        language: lang,
        format: 'json',
      },
      timeout: 10000,
    });

    const results = response.data?.results ?? [];

    if (results.length === 0) {
      return res.json({
        success: true,
        message: `Tidak ada lokasi yang ditemukan untuk "${q}".`,
        data: [],
      });
    }

    // Format ke struktur yang dipakai frontend
    const locations = results.map((r) => ({
      name: r.name,
      country: r.country ?? '',
      country_code: r.country_code ?? '',
      admin1: r.admin1 ?? '',   // Provinsi/State
      latitude: r.latitude,
      longitude: r.longitude,
      timezone: r.timezone ?? '',
      elevation: r.elevation ?? null,
      population: r.population ?? null,
    }));

    res.json({
      success: true,
      data: locations,
      total: locations.length,
    });
  } catch (error) {
    console.error('[GeocodeController] Error:', error.message);

    if (error.code === 'ECONNABORTED') {
      return res.status(504).json({
        success: false,
        message: 'Koneksi ke Geocoding API timeout.',
      });
    }

    res.status(500).json({
      success: false,
      message: 'Gagal melakukan pencarian lokasi.',
    });
  }
}

module.exports = { searchLocation };
