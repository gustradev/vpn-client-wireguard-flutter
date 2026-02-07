samples, guidance on mobile development, and a full API reference.

# GVPN (Gateway VPN Client)

Flutter Android client for WireGuard VPN, designed for enterprise and internal use. Client-only, secure, and profile-driven.

## Features
- Import WireGuard config (.conf, QR, paste)
- Profile management (secure storage, local DB)
- Start/Stop tunnel (Android)
- Status monitoring (handshake, rx/tx, endpoint)
- Minimal logs, log masking
- Biometric lock (optional)

## Setup
1. Pastikan Flutter SDK sudah terinstall.
2. Clone repo ini.
3. Jalankan:
	```bash
	flutter pub get
	flutter run
	```
4. Untuk build Android:
	```bash
	flutter build apk
	```

## Struktur Project
- lib/app: app entry, router, theme
- lib/core: constants, validators, log masker
- lib/features: modular features (profile, tunnel, log, status, settings)

## Catatan
- ApplicationId: com.example.gvpn
- Branding: GVPN
- Semua config profile terenkripsi
- Tidak ada hardcoded credential

## Dokumentasi Lanjut
Lihat file:
- SECURITY.md
- PROFILE_FORMAT.md
- TROUBLESHOOTING.md

---
Copyright 2026 GVPN Project
