# TROUBLESHOOTING.md

## No Public IP / Endpoint Kosong
- WireGuard membutuhkan endpoint UDP yang bisa di-reach.
- Jika server tidak punya public IP:
  - Gunakan relay node/VPS/gateway yang menyediakan UDP endpoint.
  - Pastikan endpoint di profile tidak kosong.
- Error: "Endpoint kosong, WireGuard butuh tujuan. Jika server tidak punya public IP, gunakan relay endpoint."

## Common Errors & Fixes
- Config invalid: cek PrivateKey, PublicKey, AllowedIPs, Endpoint.
- Tidak bisa connect: cek permission VPN, status tunnel, log error.
- Log export: pastikan tidak ada secret di log.
- Profile tidak muncul: cek storage permission, validasi config.

## Diagnostics
- Gunakan status screen untuk melihat handshake, rx/tx, endpoint.
- Export log untuk troubleshooting lebih lanjut.

---
Copyright 2026 GVPN Project
