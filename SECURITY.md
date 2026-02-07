# SECURITY.md

## Keamanan GVPN

- Semua profile WireGuard disimpan terenkripsi (flutter_secure_storage, Android Keystore).
- PrivateKey, PresharedKey, dan credential lain tidak pernah ditulis ke log.
- Log masking otomatis: field sensitif disembunyikan.
- Tidak ada analytics default, jika ada harus opt-in.
- Screenshot protection (opsional, Android FLAG_SECURE).
- Biometric lock untuk membuka profile (opsional).

## Storage
- Secret: flutter_secure_storage
- Metadata: Hive/Isar (tanpa secret)

## Audit
- Pastikan tidak ada hardcoded credential.
- Review log export sebelum share.

---
Copyright 2026 GVPN Project
