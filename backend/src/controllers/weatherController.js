const axios = require('axios');

/**
 * GET /api/weather?lat={lat}&lon={lon}
 * Cuaca terkini + hourly 24 jam + daily 7 hari dari Open-Meteo
 */
async function getCurrentWeather(req, res) {
  try {
    const { lat, lon } = req.query;

    if (!lat || !lon) {
      return res.status(400).json({
        success: false,
        message: 'Parameter lat dan lon wajib diisi.',
      });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lon);

    if (isNaN(latitude) || isNaN(longitude)) {
      return res.status(400).json({ success: false, message: 'lat dan lon harus angka.' });
    }
    if (latitude < -90 || latitude > 90) {
      return res.status(400).json({ success: false, message: 'Latitude harus -90 s/d 90.' });
    }
    if (longitude < -180 || longitude > 180) {
      return res.status(400).json({ success: false, message: 'Longitude harus -180 s/d 180.' });
    }

    const response = await axios.get('https://api.open-meteo.com/v1/forecast', {
      params: {
        latitude,
        longitude,
        // Data saat ini
        current: [
          'temperature_2m',
          'relative_humidity_2m',
          'apparent_temperature',
          'wind_speed_10m',
          'wind_direction_10m',
          'weather_code',
          'precipitation',
          'uv_index',
        ].join(','),
        // Data per jam — 168 jam ke depan (7 hari)
        hourly: [
          'temperature_2m',
          'weather_code',
          'wind_speed_10m',
          'precipitation_probability',
          'relative_humidity_2m',
          'uv_index',
        ].join(','),
        // Data harian — 7 hari
        daily: [
          'temperature_2m_max',
          'temperature_2m_min',
          'weather_code',
          'precipitation_sum',
          'wind_speed_10m_max',
          'uv_index_max',
          'sunrise',
          'sunset',
        ].join(','),
        timezone: 'auto',
        forecast_days: 7,
      },
      timeout: 12000,
    });

    const d = response.data;
    const cur = d.current;

    if (!cur) {
      return res.status(502).json({ success: false, message: 'Respons Open-Meteo tidak valid.' });
    }

    // ── Format hourly (ambil seluruh 168 jam dari API) ──
    const hourlyTimes = d.hourly?.time ?? [];
    const startIdx = 0;
    const endIdx = hourlyTimes.length;

    const hourly = [];
    for (let i = startIdx; i < endIdx; i++) {
      hourly.push({
        time: hourlyTimes[i],
        temperature: d.hourly.temperature_2m?.[i] ?? null,
        weather_code: d.hourly.weather_code?.[i] ?? null,
        wind_speed: d.hourly.wind_speed_10m?.[i] ?? null,
        precipitation_probability: d.hourly.precipitation_probability?.[i] ?? null,
        humidity: d.hourly.relative_humidity_2m?.[i] ?? null,
        uv_index: d.hourly.uv_index?.[i] ?? null,
      });
    }

    // ── Format daily 7 hari ──
    const daily = [];
    const dailyTimes = d.daily?.time ?? [];
    for (let i = 0; i < dailyTimes.length; i++) {
      daily.push({
        date: dailyTimes[i],
        temp_max: d.daily.temperature_2m_max?.[i] ?? null,
        temp_min: d.daily.temperature_2m_min?.[i] ?? null,
        weather_code: d.daily.weather_code?.[i] ?? null,
        precipitation: d.daily.precipitation_sum?.[i] ?? null,
        wind_speed_max: d.daily.wind_speed_10m_max?.[i] ?? null,
        uv_index_max: d.daily.uv_index_max?.[i] ?? null,
        sunrise: d.daily.sunrise?.[i] ?? null,
        sunset: d.daily.sunset?.[i] ?? null,
      });
    }

    res.json({
      success: true,
      message: 'Data cuaca berhasil diambil.',
      data: {
        latitude: d.latitude,
        longitude: d.longitude,
        timezone: d.timezone,
        // Current
        temperature: cur.temperature_2m,
        apparent_temperature: cur.apparent_temperature,
        relative_humidity: cur.relative_humidity_2m,
        wind_speed: cur.wind_speed_10m,
        wind_direction: cur.wind_direction_10m,
        weather_code: cur.weather_code,
        precipitation: cur.precipitation,
        uv_index: cur.uv_index,
        weather_time: cur.time,
        units: {
          temperature: d.current_units?.temperature_2m ?? '°C',
          wind_speed: d.current_units?.wind_speed_10m ?? 'km/h',
        },
        // Forecast
        hourly,
        forecast: daily,
      },
    });
  } catch (error) {
    console.error('[WeatherController] Error:', error.message);
    if (error.code === 'ECONNABORTED') {
      return res.status(504).json({ success: false, message: 'Open-Meteo API timeout.' });
    }
    if (error.response) {
      return res.status(502).json({
        success: false,
        message: `Open-Meteo error: ${error.response.data?.reason ?? 'Unknown'}`,
      });
    }
    res.status(500).json({ success: false, message: 'Internal server error.' });
  }
}

module.exports = { getCurrentWeather };
