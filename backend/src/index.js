require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { initializeSchema } = require('./db');

const weatherRoutes   = require('./routes/weather');
const locationsRoutes = require('./routes/locations');
const geocodeRoutes   = require('./routes/geocode');

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Middleware ──────────────────────────────────────────────────
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:5000',
  'http://localhost:8080',
  // Firebase Hosting — ganti dengan URL Firebase Anda setelah deploy
  process.env.FRONTEND_URL,
].filter(Boolean);

app.use(cors({
  origin: (origin, cb) => {
    // Allow requests with no origin (curl, Postman, mobile)
    if (!origin) return cb(null, true);
    // Allow semua localhost untuk development
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) return cb(null, true);
    // Allow Firebase / domain yang terdaftar
    if (allowedOrigins.includes(origin) || (process.env.FRONTEND_URL && origin.includes('web.app'))) {
      return cb(null, true);
    }
    cb(new Error(`CORS: Origin ${origin} tidak diizinkan.`));
  },
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  const ts = new Date().toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' });
  console.log(`[${ts}] ${req.method} ${req.url}`);
  next();
});

// ─── Routes ─────────────────────────────────────────────────────
app.use('/api/weather',    weatherRoutes);
app.use('/api/locations',  locationsRoutes);
app.use('/api/geocode',    geocodeRoutes);

// Render health check — WAJIB ada
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Health check
app.get('/', (req, res) => {
  res.json({
    name: '🌤 Skywheatr API',
    version: '2.0.0',
    status: 'running',
    endpoints: {
      weather:   'GET    /api/weather?lat={lat}&lon={lon}',
      geocode:   'GET    /api/geocode?q={nama_kota}',
      locations: {
        getAll:  'GET    /api/locations',
        getById: 'GET    /api/locations/:id',
        create:  'POST   /api/locations',
        update:  'PUT    /api/locations/:id',
        delete:  'DELETE /api/locations/:id',
        setPrimary: 'PATCH  /api/locations/:id/primary',
      },
    },
  });
});

app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.url} tidak ditemukan.` });
});

app.use((err, req, res, next) => {
  console.error('[Server Error]', err.stack);
  res.status(500).json({ success: false, message: 'Internal server error.' });
});

// ─── Start ──────────────────────────────────────────────────────
async function startServer() {
  try {
    await initializeSchema();
    app.listen(PORT, '0.0.0.0', () => {
      console.log('');
      console.log('╔══════════════════════════════════════════╗');
      console.log('║   🌤  Skywheatr API v2.0 — Running       ║');
      console.log('╠══════════════════════════════════════════╣');
      console.log(`║  URL  : http://0.0.0.0:${PORT}             ║`);
      console.log('╚══════════════════════════════════════════╝');
      console.log('');
      console.log('  GET    /api/weather?lat={lat}&lon={lon}');
      console.log('  GET    /api/geocode?q={nama_kota}');
      console.log('  GET    /api/locations');
      console.log('  POST   /api/locations');
      console.log('  PUT    /api/locations/:id');
      console.log('  DELETE /api/locations/:id');
      console.log('  PATCH  /api/locations/:id/primary');
      console.log('');
    });
  } catch (error) {
    console.error('[Server] Gagal start:', error.message);
    process.exit(1);
  }
}

startServer();
module.exports = app;
