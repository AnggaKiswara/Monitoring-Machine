# Monitoring Feature Brief

## Tujuan
Menambahkan modul monitoring manual untuk mesin industri secara terpisah dari flow inspeksi/lori.

## Flow yang benar
1. Factory List → pilih factory
2. **Module Select** → pilih antara:
   - **Station** → flow existing (Station List → Machine List → Machine Detail/Inspection)
   - **Monitoring / Vibration** → flow monitoring baru
3. Monitoring / Vibration → pilih station → pilih mesin → **Monitoring Session Screen**

## Poin penting
- Monitoring session adalah modul terpisah, bukan bagian dari Lori/Ramp loading
- Setiap mesin punya 5 sensor: vibration horizontal/vertikal, bearing inner/outer, bearing temp
- Semua role boleh akses monitoring
- Input manual semua field + timestamp masing-masing entri
- HM dan RPM disimpan per sesi monitoring

## Screen yang akan dibuat
1. `ModuleSelectScreen` - pilih Station atau Monitoring
2. `MonitoringFactoryEntryScreen` - list station + mesin di factory terpilih
3. `MonitoringSessionScreen` - form compact card input monitoring manual

## Perbaikan yang diperlukan
- Ubah routing `factory_list_screen.dart` agar menuju `ModuleSelectScreen` (sudah ada)
- Buat `module_select_screen.dart` (sudah ada)
- Buat `monitoring_factory_entry_screen.dart` (sudah ada)
- Buat `monitoring_screen.dart` (sudah ada - MonitoringSessionScreen)
- Hapus tab Monitoring dari `machine_detail_screen.dart` untuk lori/ramp loading
- Tambahkan permission `canAccessMonitoring()` di `auth_providers.dart` (sudah ada)
