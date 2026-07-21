const { dbAll, dbGet, dbRun } = require('../db');

/**
 * GET /api/notes
 * SELECT semua catatan cuaca dari database
 */
async function getAllNotes(req, res) {
  try {
    const notes = await dbAll(
      'SELECT * FROM weather_notes ORDER BY note_date DESC, created_at DESC'
    );

    return res.status(200).json({
      success: true,
      message: `Berhasil mengambil ${notes.length} catatan cuaca.`,
      count: notes.length,
      data: notes,
    });
  } catch (error) {
    console.error('[NotesController] getAllNotes error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal mengambil data catatan.' });
  }
}

/**
 * GET /api/notes/:id
 * SELECT catatan berdasarkan ID
 */
async function getNoteById(req, res) {
  try {
    const { id } = req.params;
    const note = await dbGet('SELECT * FROM weather_notes WHERE id = ?', [id]);

    if (!note) {
      return res.status(404).json({
        success: false,
        message: `Catatan dengan id ${id} tidak ditemukan.`,
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Berhasil mengambil detail catatan.',
      data: note,
    });
  } catch (error) {
    console.error('[NotesController] getNoteById error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal mengambil detail catatan.' });
  }
}

/**
 * POST /api/notes
 * INSERT catatan baru ke database
 */
async function createNote(req, res) {
  try {
    const {
      title, note_date, location, latitude, longitude,
      temperature, wind_speed, weather_code, weather_time,
      timezone, mood, activity, description,
    } = req.body;

    // Validasi field wajib
    if (!title || !note_date || !location || latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Field wajib: title, note_date, location, latitude, longitude.',
      });
    }

    const sql = `
      INSERT INTO weather_notes (
        title, note_date, location, latitude, longitude,
        temperature, wind_speed, weather_code, weather_time, timezone,
        mood, activity, description
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const result = await dbRun(sql, [
      title, note_date, location, latitude, longitude,
      temperature ?? null, wind_speed ?? null, weather_code ?? null,
      weather_time ?? null, timezone ?? null,
      mood ?? null, activity ?? null, description ?? null,
    ]);

    // Ambil data yang baru dibuat
    const newNote = await dbGet('SELECT * FROM weather_notes WHERE id = ?', [result.lastID]);

    return res.status(201).json({
      success: true,
      message: 'Catatan cuaca berhasil disimpan ke database.',
      data: newNote,
    });
  } catch (error) {
    console.error('[NotesController] createNote error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal menyimpan catatan baru.' });
  }
}

/**
 * PUT /api/notes/:id
 * UPDATE catatan yang sudah ada di database
 */
async function updateNote(req, res) {
  try {
    const { id } = req.params;

    // Cek apakah catatan ada (SELECT BY ID)
    const existing = await dbGet('SELECT * FROM weather_notes WHERE id = ?', [id]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: `Catatan dengan id ${id} tidak ditemukan.`,
      });
    }

    const {
      title, note_date, location, latitude, longitude,
      temperature, wind_speed, weather_code, weather_time,
      timezone, mood, activity, description,
    } = req.body;

    // Validasi field wajib
    if (!title || !note_date || !location || latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Field wajib: title, note_date, location, latitude, longitude.',
      });
    }

    const sql = `
      UPDATE weather_notes SET
        title        = ?,
        note_date    = ?,
        location     = ?,
        latitude     = ?,
        longitude    = ?,
        temperature  = ?,
        wind_speed   = ?,
        weather_code = ?,
        weather_time = ?,
        timezone     = ?,
        mood         = ?,
        activity     = ?,
        description  = ?,
        updated_at   = datetime('now','localtime')
      WHERE id = ?
    `;

    await dbRun(sql, [
      title, note_date, location, latitude, longitude,
      temperature ?? null, wind_speed ?? null, weather_code ?? null,
      weather_time ?? null, timezone ?? null,
      mood ?? null, activity ?? null, description ?? null,
      id,
    ]);

    const updatedNote = await dbGet('SELECT * FROM weather_notes WHERE id = ?', [id]);

    return res.status(200).json({
      success: true,
      message: `Catatan id ${id} berhasil diperbarui.`,
      data: updatedNote,
    });
  } catch (error) {
    console.error('[NotesController] updateNote error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal memperbarui catatan.' });
  }
}

/**
 * DELETE /api/notes/:id
 * DELETE catatan dari database
 */
async function deleteNote(req, res) {
  try {
    const { id } = req.params;

    // Cek apakah catatan ada
    const existing = await dbGet('SELECT * FROM weather_notes WHERE id = ?', [id]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: `Catatan dengan id ${id} tidak ditemukan.`,
      });
    }

    await dbRun('DELETE FROM weather_notes WHERE id = ?', [id]);

    return res.status(200).json({
      success: true,
      message: `Catatan id ${id} berhasil dihapus dari database.`,
      data: existing,
    });
  } catch (error) {
    console.error('[NotesController] deleteNote error:', error.message);
    return res.status(500).json({ success: false, message: 'Gagal menghapus catatan.' });
  }
}

module.exports = { getAllNotes, getNoteById, createNote, updateNote, deleteNote };
