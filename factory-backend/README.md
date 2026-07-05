# Factory Backend — Machine Health Monitoring API

Backend REST API buat sistem monitoring kesehatan mesin pabrik. Format response JSON standar, jadi bisa dipakai dari frontend apapun — web (React/Vue/Next), mobile (Flutter/React Native), atau sistem lain yang butuh integrasi.

## Setup

```bash
npm install
cp .env.example .env
# edit .env sesuai kredensial MySQL lo

# import schema ke MySQL
mysql -u root -p < schema.sql

npm run dev   # development (nodemon)
npm start     # production
```

## Struktur Folder

```
src/
  config/db.js          -> koneksi pool MySQL
  middleware/
    auth.js              -> verifikasi JWT + role-based authorize
    errorHandler.js       -> error handler global
  utils/
    crudFactory.js         -> generator CRUD generic buat tabel standar
    asyncHandler.js          -> wrapper try-catch async
    ApiError.js               -> custom error class
  services/
    alert.service.js          -> logic evaluasi alert rule + dedup + auto-resolve
  controllers/                -> handler tiap endpoint
  routes/                      -> definisi route tiap resource
  app.js                        -> setup express + gabungin semua routes
  server.js                      -> entry point
```

## Autentikasi

Semua endpoint (kecuali `/api/auth/register` dan `/api/auth/login`) butuh header:
```
Authorization: Bearer <token>
```

```bash
# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"rahasia123","nama_lengkap":"Alex","role_user":"admin"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"rahasia123"}'
```

## Endpoint Utama

| Method | Endpoint | Keterangan |
|---|---|---|
| GET/POST | `/api/stations` | CRUD station |
| GET/POST | `/api/machines` | CRUD mesin |
| GET/POST | `/api/komponen` | CRUD komponen fisik |
| GET/POST | `/api/parameters` | CRUD master parameter (suhu, rpm, dll) |
| GET/POST | `/api/komponen-parameters` | Mapping parameter apa aja yang dipantau di 1 komponen |
| POST | `/api/sensor-readings` | Insert reading baru — **otomatis trigger alert check** |
| GET | `/api/sensor-readings/history?id_komponen=&id_parameter=` | Histori time-series (buat grafik) |
| GET | `/api/sensor-readings/latest/:id_komponen` | Nilai terkini semua parameter di 1 komponen |
| GET/POST | `/api/alert-rules` | CRUD rule custom (threshold, operator, severity) |
| GET/POST | `/api/service-alerts` | List/insert alert |
| PATCH | `/api/service-alerts/:id/acknowledge` | Tandai alert udah dilihat |
| PATCH | `/api/service-alerts/:id/resolve` | Tandai alert udah selesai ditangani |
| GET/POST | `/api/service-history` | CRUD histori maintenance |

Semua endpoint list (`GET /`) support query param `?limit=&offset=` buat pagination, dan filter langsung pakai nama kolom (misal `?id_mesin=1`).

## Alur Kerja Alert (Penting)

1. Device (ESP32/sensor) kirim data ke endpoint `POST /api/sensor-readings`.
2. Backend insert ke `sensor_reading`, lalu otomatis:
   - Cari `alert_rule` aktif yang cocok (prioritas rule spesifik komponen > rule general).
   - Evaluasi nilai terhadap rule (`>`, `<`, `between`, `outside`, dst).
   - Kalau anomali & belum ada alert `open` yang sama → insert alert baru.
   - Kalau anomali & alert `open` udah ada → update nilai terdeteksi aja (gak dobel insert).
   - Kalau nilai normal & ada alert `open` sebelumnya → otomatis di-resolve.
3. Response dari endpoint ini include info `alert: { triggered, alert_id, deduped }` biar frontend langsung tau kalau ada alert baru tanpa perlu polling terpisah.

## Yang Masih Perlu Ditambahin Sebelum Full Production

- **Rate limiting** (misal `express-rate-limit`) di endpoint publik/auth.
- **Validasi input** lebih ketat (saat ini masih basic manual check) — bisa pakai `zod` atau `joi`.
- **WebSocket/SSE** kalau butuh push notification real-time ke frontend pas ada alert baru (sekarang masih pull-based via polling atau lewat response insert reading).
- **Refresh token** (sekarang cuma access token JWT biasa, expired ya harus login ulang).
- **Logging terstruktur** (winston/pino) buat production, morgan sekarang cuma buat access log dasar.
- Kalau volume `sensor_reading` udah besar, pertimbangkan partitioning tabel per bulan atau pindah ke time-series DB terpisah.
