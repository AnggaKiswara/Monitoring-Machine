# Monitoring by Mobile App - Framing

## Latar Belakang
Monitoring(form) pada gambar 2 adalah monitor manual per mesin dengan beberapa parameter sensor, HM, RPM, dan remarks. Fitur ini akan di-enable sebagai menu baru di mobile app dengan flow tetap menggunakan struktur station > machine > monitoring.

## Target Flow
- Station List
- Machine List
- Monitoring Detail (compact cards, bukan table mentah)

## Data Flow
- Sesi monitoring disimpan di `monitoring_session`
- Tiap input parameter disimpan di `monitoring_reading`
- Sesi bisa memiliki 1 record per parameter. `recorded_at` adalah timestamp sesi pengukuran.

## Rule Mapping dari Form
- Vibration `mm/s`: Good <= 2.8, Alert 2.8 < x < 4.8, Danger >= 4.8
- Bearing `gE`: Good <= 2.0, Alert 2.0 < x < 4.0, Danger >= 4.0
- Bearing Temp `°C`: Good <= 50, Alert 50 < x < 70, Danger >= 70

## Pertanyaan / Asumsi
- Semua mesin punya seluruh sensor.
- HM diset per sesi.
- RPM diset per sesi.
- Session punya timestamp masing-masing.
- UI compact cards untuk mobile, mudah dipaginasi/dipecah per section.

## Deliverables
- API + migration monitoring di backend.
- Model + API methods di Flutter.
- Monitoring detail screen di Flutter.
