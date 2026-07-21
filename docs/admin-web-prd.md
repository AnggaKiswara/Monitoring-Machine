# PRD — Admin Web Panel "Monitoring Machine"

**Status:** Draft v1 (untuk review)
**Tanggal:** 2026-07-18
**Penulis:** Hermes (untuk Angga Kiswara / owner)
**Tujuan dokumen:** Menjadi acuan sebelum membangun web admin untuk mengelola seluruh data Monitoring Machine dari sisi admin.

---

## 1. Latar Belakang & Masalah

Saat ini pengelolaan data (pabrik, station, lori, inspeksi, user, alert) hanya bisa dilakukan lewat **mobile app** atau manipulasi DB langsung. Admin butuh satu **dashboard web** yang bisa:

- Melihat gambaran utuh (KPI) seluruh pabrik dari 1 layar.
- Mengelola master data (pabrik → station → lori → komponen) tanpa harus buka HP.
- Melihat & memverifikasi **riwayat inspeksi + foto** dari semua lori.
- Mengelola **user & role** (admin/staff/teknisi).
- Mengatur **alert/aturan peringatan** dan memantau sensor.

Mobile tetap untuk *field inspection*; web untuk *administrasi & pengawasan*.

## 2. Tujuan (Goals)

1. Admin bisa login aman (JWT, role `admin`).
2. Admin bisa CRUD pabrik, station, lori, komponen, user dari web.
3. Admin bisa melihat semua riwayat inspeksi (global) + detail + foto.
4. Admin punya dashboard KPI (total pabrik, lori breakdown, health rata-rata).
5. Admin bisa kelola alert rules & lihat service alerts.
6. Konsisten dengan tema mobile (clean, putih, aksen biru `#2196F3`, navy `#1a2332`).

## 3. User & Peran

| Role | Akses di web admin |
|------|--------------------|
| `admin` | Semua fitur (manajemen penuh + user) |
| `staff` | Lihat + kelola inspeksi/alert (tanpa hapus pabrik/user) — *opsional di v1* |
| `teknisi` | Hanya lihat — *opsional di v1* |

**v1 fokus: hanya `admin` yang bisa akses web panel.**

## 4. Tech Stack (usulan)

- **Frontend:** React 18 + Vite (sudah ada di `monitoring_web_app`), React Router, Axios (via `src/lib/api.js`), Tailwind CSS untuk konsistensi tema cepat.
- **State:** Context API (auth) + React Query *atau* fetch hook sederhana (hindari over-engineering).
- **Charts:** Recharts (KPI dashboard).
- **Backend:** reuse `factory-backend` (Express + MySQL) via REST API `http://103.93.135.108:3000/api`.
- **Auth:** JWT (`/auth/login`), token disimpan di `localStorage`, dikirim via header `Authorization: Bearer`.

## 5. Halaman & Fitur

### 5.1 Auth
- `/login` — form username/password, tema clean, tanpa social login.
- Redirect ke `/dashboard` jika sudah login.
- Logout menghapus token.

### 5.2 Dashboard (`/`)
KPI cards: Total Pabrik, Total Station, Total Lori, Rata-rata Health, Jumlah Breakdown (<70%).
Mini tabel: Pabrik terakhir di-update / lori dengan health terendah.
Grafik: distribusi health lori (pie: good/warning/breakdown).

### 5.3 Manajemen Pabrik (`/factories`)
- Tabel pabrik (nama, lokasi, health, jumlah station).
- Tambah/Edit/Hapus (cascade: hapus pabrik → station + lori ikut terhapus, sudah ada di backend).
- Klik pabrik → drill ke daftar station.

### 5.4 Manajemen Station (`/factories/:id/stations`)
- Tabel station dalam 1 pabrik (nama, lokasi, health, jumlah lori).
- CRUD station.

### 5.5 Manajemen Lori / Machine (`/stations/:id/machines`)
- Tabel lori (kode, nama, health).
- CRUD lori + auto-buat komponen (sudah ada di flow mobile).
- Klik lori → detail + komponen + riwayat inspeksi lori tersebut.

### 5.6 Riwayat Inspeksi Global (`/inspections`)
- Tabel semua inspeksi dari semua pabrik (join factory→station→lori): nama lori, pabrik, station, tanggal, teknisi, health after, ada/tidak foto.
- Filter: tanggal, pabrik, health.
- Klik baris → **detail inspeksi** (`/inspections/:id`) dengan komponen + nilai + **foto inspeksi** (dari `uploads/inspections`).

### 5.7 Manajemen User (`/users`) — *butuh backend baru*
- Tabel user (username, nama, role, aktif?).
- Tambah user (admin bisa set role admin/staff/teknisi — sesuai aturan `register`).
- Non-aktifkan user (soft delete / `is_active=false`).
- *Backend perlu:* `GET/PUT/DELETE /users`, `PATCH is_active`.

### 5.8 Alert & Sensor — *sebagian butuh backend baru*
- `/alerts` — daftar `service_alert` (status, severity, terkait lori).
- `/alert-rules` — kelola `alert_rule` (threshold health/komponen).
- `/sensors` — pantau `sensor_reading` per komponen (latest/history).
- *Backend sudah ada:* `GET /service-alerts`, `GET /alert-rules`, `GET /sensor-readings/...`. *Perlu:* `POST/PUT/DELETE alert-rule`, `POST service-alert` (jika ingin buat manual).

### 5.9 Komponen & Parameter (master) — *read-only di v1*
- `/komponen`, `/parameter` — lihat daftar master komponen & parameter (sudah ada `GET`).
- Edit master opsional (butuh backend `PUT`).

## 6. Pemetaan API (Existing vs Perlu Baru)

**Sudah ada (bisa pakai langsung):**
- `POST /auth/login` ✓
- `GET /factories`, `POST/PUT/DELETE /factories/:id` ✓
- `GET /stations`, `POST/PUT/DELETE /stations/:id` ✓ (create sudah di-fix lokasi)
- `GET /machines`, `POST/PUT/DELETE /machines/:id` ✓
- `GET /service-history/global`, `/:id` ✓
- `GET /service-alerts`, `/alert-rules`, `/komponen`, `/parameter` ✓
- `GET /sensor-readings/...` ✓
- `POST /auth/register` (buat user, butuh requester admin) ✓

**Perlu ditambah di backend (estimasi kecil):**
- `GET /users`, `GET /users/:id`, `PUT /users/:id`, `PATCH /users/:id/active` (manajemen user + enable/disable).
- `POST/PUT/DELETE /alert-rules/:id` (CRUD alert rule).
- Pastikan foto inspeksi bisa di-serve ke web (sudah ada `app.use('/uploads', static)` di backend).

## 7. Alur Pengguna Utama (Admin)

1. Buka `/login` → isi `fallah@engineer-mtc` / `Fallah12345` → masuk dashboard.
2. Dashboard → lihat KPI → klik "Pabrik" untuk kelola.
3. Pabrik → Station → Lori → lihat detail & riwayat inspeksi + foto.
4. Tab "Inspeksi" → cari riwayat → buka detail → lihat foto & komponen.
5. Tab "User" → tambah teknisi baru, non-aktifkan user lama.
6. Tab "Alert" → cek peringatan, atur rule threshold.

## 8. Non-Functional

- **Responsive:** desktop-first (admin pakai laptop), tapi tetap usable di tablet.
- **Keamanan:** semua halaman dilindungi guard `authenticate`; token expired → redirect login.
- **Konsistensi UI:** warna & gaya mengikuti mobile (biru `#2196F3`, navy `#1a2332`, kartu putih rounded, badge health berwarna).
- **Feedback:** loading state + notifikasi sukses/error (toast, bukan alert mentah).
- **Performa:** tabel pakai pagination/limit (backend `getGlobalHistory` sudah support `limit/offset`).

## 9. Scope

**Masuk v1:**
- Login + guard, Dashboard KPI, CRUD Pabrik/Station/Lori, Riwayat Inspeksi Global + Detail + Foto, Manajemen User, Alert list + Rule CRUD, Sensor view.

**Keluar v1 (opsional nanti):**
- Edit master komponen/parameter dari web.
- Role staff/teknisi dengan permission terbatas di web.
- Export laporan ke PDF/Excel.
- Real-time websocket sensor.

## 10. Pertanyaan Terbuka (perlu konfirmasi Anda)

1. **User management**: mau admin bisa bikin/non-aktifkan user dari web, atau cukup lewat DB? (PRD asumsikan lewat web.)
2. **Alert rule**: perlu admin bisa buat aturan threshold sendiri, atau cukup lihat alert yang sudah ada?
3. **Deployment**: web di-deploy di server yang sama (port lain, mis. `:3001` / `:5173`) atau domain terpisah?
4. **Bahasa UI**: Indonesia (sesuai mobile) — benar?
5. Apakah ada field/role selain admin yang wajib didukung di v1?

---

## 11. Rencana Eksekusi (setelah PRD disetujui)

1. Tambah endpoint backend: user management + alert-rule CRUD.
2. Setup `monitoring_web_app`: Tailwind, router, api client + auth context.
3. Bangun per halaman: Login → Dashboard → Factories → Stations → Machines → Inspections → Users → Alerts.
4. Deploy ke server, test end-to-end dengan user `fallah@engineer-mtc`.
