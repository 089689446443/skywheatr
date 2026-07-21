const { dbAll, dbGet, dbRun } = require('../db');

// ── GET /api/locations ─────────────────────────────────────────
async function getAllLocations(req, res) {
  try {
    const rows = await dbAll(
      'SELECT * FROM locations ORDER BY is_primary DESC, created_at ASC'
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

// ── GET /api/locations/:id ─────────────────────────────────────
async function getLocationById(req, res) {
  try {
    const row = await dbGet('SELECT * FROM locations WHERE id = ?', [req.params.id]);
    if (!row) return res.status(404).json({ success: false, message: 'Lokasi tidak ditemukan.' });
    res.json({ success: true, data: row });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

// ── POST /api/locations ────────────────────────────────────────
async function createLocation(req, res) {
  try {
    const { name, country = '', latitude, longitude, timezone = '' } = req.body;

    if (!name || latitude == null || longitude == null) {
      return res.status(400).json({
        success: false,
        message: 'Field name, latitude, dan longitude wajib diisi.',
      });
    }

    // Cek apakah sudah ada lokasi dengan lat/lon yang sama (toleransi 0.01°)
    const existing = await dbGet(
      'SELECT id FROM locations WHERE ABS(latitude - ?) < 0.01 AND ABS(longitude - ?) < 0.01',
      [latitude, longitude]
    );
    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'Lokasi dengan koordinat yang sama sudah tersimpan.',
      });
    }

    // Jika belum ada lokasi sama sekali, jadikan ini primary
    const count = await dbGet('SELECT COUNT(*) as cnt FROM locations');
    const isPrimary = count.cnt === 0 ? 1 : 0;

    const result = await dbRun(
      `INSERT INTO locations (name, country, latitude, longitude, timezone, is_primary)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [name.trim(), country, parseFloat(latitude), parseFloat(longitude), timezone, isPrimary]
    );

    const newRow = await dbGet('SELECT * FROM locations WHERE id = ?', [result.lastID]);
    res.status(201).json({
      success: true,
      message: 'Lokasi berhasil disimpan.',
      data: newRow,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

// ── PUT /api/locations/:id ─────────────────────────────────────
async function updateLocation(req, res) {
  try {
    const { name, country, timezone } = req.body;
    const id = req.params.id;

    const existing = await dbGet('SELECT * FROM locations WHERE id = ?', [id]);
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Lokasi tidak ditemukan.' });
    }

    await dbRun(
      `UPDATE locations SET
        name      = ?,
        country   = ?,
        timezone  = ?,
        updated_at = ?
       WHERE id = ?`,
      [
        name?.trim() ?? existing.name,
        country ?? existing.country,
        timezone ?? existing.timezone,
        new Date().toISOString(),
        id,
      ]
    );

    const updated = await dbGet('SELECT * FROM locations WHERE id = ?', [id]);
    res.json({ success: true, message: 'Lokasi berhasil diperbarui.', data: updated });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

// ── DELETE /api/locations/:id ──────────────────────────────────
async function deleteLocation(req, res) {
  try {
    const id = req.params.id;
    const existing = await dbGet('SELECT * FROM locations WHERE id = ?', [id]);
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Lokasi tidak ditemukan.' });
    }

    await dbRun('DELETE FROM locations WHERE id = ?', [id]);

    // Jika yang dihapus adalah primary, set lokasi pertama sebagai primary baru
    if (existing.is_primary === 1) {
      const first = await dbGet('SELECT id FROM locations ORDER BY created_at ASC LIMIT 1');
      if (first) {
        await dbRun('UPDATE locations SET is_primary = 1 WHERE id = ?', [first.id]);
      }
    }

    res.json({ success: true, message: 'Lokasi berhasil dihapus.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

// ── PATCH /api/locations/:id/primary ──────────────────────────
async function setPrimaryLocation(req, res) {
  try {
    const id = req.params.id;
    const existing = await dbGet('SELECT * FROM locations WHERE id = ?', [id]);
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Lokasi tidak ditemukan.' });
    }

    // Reset semua, set yang dipilih jadi primary
    await dbRun('UPDATE locations SET is_primary = 0');
    await dbRun('UPDATE locations SET is_primary = 1 WHERE id = ?', [id]);

    res.json({ success: true, message: 'Lokasi utama berhasil diubah.' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

module.exports = {
  getAllLocations,
  getLocationById,
  createLocation,
  updateLocation,
  deleteLocation,
  setPrimaryLocation,
};
