# 🌤 Skywheatr — Aplikasi Catatan Cuaca Harian

Aplikasi mobile catatan cuaca harian yang terhubung dengan sistem penuh:
- **Open-Meteo API** — Data cuaca real dari API eksternal (gratis, tanpa API key)
- **Node.js + Express** — Backend REST API sendiri
- **SQLite** — Database server lokal
- **Flutter** — Antarmuka mobile Android/iOS

---

## Arsitektur Sistem

```
Flutter Mobile App
       │
       │ HTTP (REST API)
       ▼
Node.js + Express Backend (localhost:3000)
       │                    │
       │ SQLite             │ HTTP
       ▼                    ▼
  skywheatr.db     Open-Meteo API
                   api.open-meteo.com
```

---

## Struktur Direktori

```
skywheatr/
├── backend/                        ← REST API Server
│   ├── src/
│   │   ├── index.js                ← Entry point Express
│   │   ├── db.js                   ← SQLite koneksi & schema
│   │   ├── controllers/
│   │   │   ├── weatherController.js ← Proxy ke Open-Meteo
│   │   │   └── notesController.js   ← CRUD catatan
│   │   └── routes/
│   │       ├── weather.js
│   │       └── notes.js
│   ├── skywheatr.db                ← Database SQLite (auto-generated)
│   ├── package.json
│   └── .env
│
└── mobile/                         ← Flutter App
    └── lib/
        ├── main.dart
        ├── config/api_config.dart
        ├── models/weather_note.dart
        ├── services/api_service.dart
        ├── utils/weather_utils.dart
        ├── widgets/
        │   ├── note_card.dart
        │   └── weather_preview_card.dart
        └── screens/
            ├── home_screen.dart
            ├── add_note_screen.dart
            ├── detail_screen.dart
            └── edit_note_screen.dart
```

---

## REST API Endpoints

| Method   | Endpoint                       | Operasi   | Keterangan                         |
|----------|--------------------------------|-----------|------------------------------------|
| `GET`    | `/api/weather?lat=&lon=`       | —         | Ambil cuaca real dari Open-Meteo   |
| `GET`    | `/api/notes`                   | SELECT    | Ambil semua catatan                |
| `GET`    | `/api/notes/:id`               | SELECT    | Ambil detail 1 catatan             |
| `POST`   | `/api/notes`                   | INSERT    | Buat catatan baru                  |
| `PUT`    | `/api/notes/:id`               | UPDATE    | Perbarui catatan                   |
| `DELETE` | `/api/notes/:id`               | DELETE    | Hapus catatan                      |

---

## Cara Menjalankan

### 1. Backend (Node.js + Express + SQLite)

```bash
cd backend
npm install
node src/index.js
```

Server berjalan di: `http://localhost:3000`

Database SQLite dibuat otomatis di `backend/skywheatr.db`

**Test API dengan PowerShell:**
```powershell
# Test ambil cuaca Jakarta
Invoke-WebRequest "http://localhost:3000/api/weather?lat=-6.2088&lon=106.8456" | Select -ExpandProperty Content

# Test ambil semua catatan
Invoke-WebRequest "http://localhost:3000/api/notes" | Select -ExpandProperty Content

# Test tambah catatan (POST)
$body = @{
  title="Hari di Jakarta"; note_date="2026-07-14"; location="Jakarta Pusat"
  latitude=-6.2088; longitude=106.8456; temperature=34.9; wind_speed=11.6
  weather_code=3; mood="😊"; activity="Coding seharian"
} | ConvertTo-Json
Invoke-WebRequest -Method POST -Uri "http://localhost:3000/api/notes" -Body $body -ContentType "application/json"
```

### 2. Flutter Mobile App

**Konfigurasi URL Backend** di `mobile/lib/config/api_config.dart`:
```dart
// Android Emulator:
static const String baseUrl = 'http://10.0.2.2:3000';

// Perangkat fisik (ganti dengan IP komputer Anda):
static const String baseUrl = 'http://192.168.1.xxx:3000';

// iOS Simulator:
static const String baseUrl = 'http://localhost:3000';
```

**Jalankan Flutter:**
```bash
cd mobile
flutter pub get
flutter run
```

---

## Database Schema

```sql
CREATE TABLE weather_notes (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  title         TEXT    NOT NULL,           -- Judul catatan
  note_date     TEXT    NOT NULL,           -- Tanggal (YYYY-MM-DD)
  location      TEXT    NOT NULL,           -- Nama lokasi
  latitude      REAL    NOT NULL,           -- Koordinat latitude
  longitude     REAL    NOT NULL,           -- Koordinat longitude
  temperature   REAL,                       -- Suhu (dari Open-Meteo)
  wind_speed    REAL,                       -- Kec. angin (dari Open-Meteo)
  weather_code  INTEGER,                    -- Kode WMO (dari Open-Meteo)
  weather_time  TEXT,                       -- Waktu data cuaca
  timezone      TEXT,                       -- Zona waktu
  mood          TEXT,                       -- Mood pengguna (emoji)
  activity      TEXT,                       -- Aktivitas pengguna
  description   TEXT,                       -- Catatan tambahan
  created_at    TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at    TEXT DEFAULT CURRENT_TIMESTAMP
);
```

---

## Alur Kerja Aplikasi

1. **Home Screen** — Tampilkan semua catatan (`GET /api/notes`)
2. **Tambah Catatan** — Input koordinat → klik "Ambil Cuaca" → data dari `GET /api/weather` → isi form → simpan (`POST /api/notes`)
3. **Detail Catatan** — Lihat info lengkap catatan (`GET /api/notes/:id`)
4. **Edit Catatan** — Ubah data → opsional update cuaca → simpan (`PUT /api/notes/:id`)
5. **Hapus Catatan** — Konfirmasi → hapus (`DELETE /api/notes/:id`)

---

## Implementasi CRUD REST API

| Operasi | Flutter Method | HTTP Method | Backend Controller |
|---------|---------------|-------------|-------------------|
| SELECT ALL | `getAllNotes()` | GET | `getAllNotes` |
| SELECT BY ID | `getNoteById(id)` | GET | `getNoteById` |
| INSERT | `createNote(note)` | POST | `createNote` |
| UPDATE | `updateNote(id, note)` | PUT | `updateNote` |
| DELETE | `deleteNote(id)` | DELETE | `deleteNote` |

---

## Open-Meteo API

- **URL**: `https://api.open-meteo.com/v1/forecast`
- **Gratis**: Tidak perlu API key
- **Parameter**: `latitude`, `longitude`, `current=temperature_2m,wind_speed_10m,weather_code,relative_humidity_2m,apparent_temperature`, `timezone=auto`
- **Koordinat Jakarta**: lat=-6.2088, lon=106.8456

---

## Catatan Teknis

- Backend harus berjalan sebelum membuka aplikasi Flutter
- Untuk Android Emulator, gunakan IP `10.0.2.2` bukan `localhost`
- Database SQLite otomatis dibuat saat server pertama kali dijalankan
- Open-Meteo API tidak memerlukan API key dan gratis untuk penggunaan non-komersial
