# Algoritma Project WireGuard VPN Client Flutter

Berikut adalah algoritma dan struktur proses utama project dalam format tree, lengkap dan detil:

```
Project WireGuard VPN Client Flutter
|
├── Inisialisasi Proyek
│   ├── flutter create
│   ├── Set applicationId/package name
│   └── Setup struktur folder modular (app, core, features)
|
├── Dependency Setup
│   ├── Tambah dependencies (Riverpod, GoRouter, Hive, Secure Storage, dll)
│   └── flutter pub get
|
├── Domain Layer
│   ├── Entity
│   │   ├── Profile
│   │   ├── TunnelStatus
│   │   └── LogEntry
│   ├── Repository Interface
│   │   ├── ProfileRepository
│   │   ├── TunnelRepository
│   │   └── LogRepository
│   └── Usecase
│       ├── ImportProfile
│       ├── ListProfiles
│       ├── SaveProfile
│       ├── ConnectTunnel
│       ├── DisconnectTunnel
│       └── ObserveStatus
|
├── Data Layer
│   ├── Secure Storage
│   │   └── ProfileSecureStorage (private key, pre-shared key)
│   ├── Local DB
│   │   └── ProfileLocalDB (Hive, metadata profile)
│   ├── Repository Implementation
│   │   ├── ProfileRepositoryImpl (gabung secure storage + local db)
│   │   └── LogRepositoryImpl (Hive log)
|
├── Config Parser & Validator
│   ├── wg_config_parser.dart (parser config WG)
│   └── core/validators.dart (validasi field)
|
├── UI Layer
│   ├── Router (GoRouter)
│   ├── HomeScreen
│   ├── ProfileListScreen
│   ├── ProfileDetailScreen
│   ├── ImportProfileScreen
│   ├── StatusScreen
│   └── SettingsScreen
|
├── State Management
│   ├── Riverpod provider untuk profile, tunnel, log
|
├── WireGuard Engine Integration (Android)
│   ├── Platform Channel (method channel)
│   ├── TunnelRepositoryImpl (call platform channel)
│   ├── Android VPN permission flow
│   └── WireGuard backend integration (start/stop tunnel, stats)
|
├── Observability & Polish
│   ├── Status & monitoring UI
│   ├── Log system (masking, export)
│   ├── Settings (theme, biometric, auto-reconnect)
│   └── Error UX (no public IP)
|
├── Dokumentasi
│   ├── README.md
│   ├── SECURITY.md
│   ├── PROFILE_FORMAT.md
│   └── TROUBLESHOOTING.md
```

Setiap node di tree di atas bisa dikembangkan lebih detil sesuai kebutuhan pengembangan dan audit.

---

## Penjelasan Algoritma Sistem

Sistem VPN Client ini dibangun dengan arsitektur modular dan clean architecture. Setiap bagian (domain, data, UI) punya tanggung jawab sendiri, sehingga mudah dikembangkan dan di-maintain.

- **Domain Layer:** Berisi entity, interface repository, dan usecase. Semua logika inti (misal: CRUD profile, connect tunnel) ada di sini.
- **Data Layer:** Menghubungkan domain dengan storage (Hive/local DB & secure storage). Semua data sensitif (private key) disimpan terenkripsi.
- **UI Layer:** Menyajikan tampilan dan interaksi user, terhubung ke domain lewat provider (Riverpod).
- **Integrasi Android:** Komunikasi dengan engine WireGuard via platform channel untuk start/stop tunnel dan ambil status.
- **Observability:** Ada sistem log, status monitoring, dan error UX agar troubleshooting mudah.

---

## User Flow (Alur Pengguna)

1. **Install & Setup**
   - User install aplikasi, aplikasi inisialisasi storage dan dependency.
2. **Import Profile**
   - User bisa import profile WireGuard via paste, file, atau QR code.
   - Data profile dan key disimpan: metadata ke local DB, private key ke secure storage.
3. **Lihat & Kelola Profile**
   - User bisa lihat daftar profile, detail, edit, atau hapus profile.
4. **Connect ke VPN**
   - User pilih profile, klik connect.
   - App validasi config, lalu kirim perintah ke engine WireGuard (via platform channel Android).
   - Status koneksi dan statistik tampil di UI.
5. **Monitoring & Log**
   - User bisa lihat status tunnel, statistik, dan log aktivitas.
6. **Settings & Export**
   - User bisa atur tema, export profile/log, dan fitur lain (biometric, auto-reconnect).

---

## Steps Visualisasi (Ringkas)

```
[Start]
  |
  v
[Install & Setup]
  |
  v
[Import Profile] <--- [Settings/Export]
  |
  v
[Lihat/Kelola Profile]
  |
  v
[Connect ke VPN]
  |
  v
[Monitoring & Log]
  |
  v
[Disconnect/Exit]
```

---

## Keterangan Visualisasi
- Setiap blok adalah langkah utama user.
- Panah menunjukkan urutan proses.
- User bisa kembali ke Settings/Export kapan saja.
- Monitoring & Log bisa diakses selama tunnel aktif.
- Semua data sensitif selalu dienkripsi dan tidak pernah keluar device.

Penjelasan ini bisa dipakai untuk onboarding tim, dokumentasi, atau presentasi ke stakeholder.
