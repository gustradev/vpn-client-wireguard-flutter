samples, guidance on mobile development, and a full API reference.

<div align="center">
<pre>
░█▀█░█░█░█▀█░█▀█░█▄█░█▀█
░█▀▀░█░█░█▀█░█░█░█░█░█▀▀
░▀░░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀░░
</pre>
</div>

# GVPN — Gateway VPN Client

> Flutter Android client untuk WireGuard VPN. Aman, modern, dan siap dipakai untuk kebutuhan internal maupun enterprise.
>
> <i>"Koneksi aman, hidup tenang."</i>

---

## ✨ Fitur Utama

* Import profil WireGuard (paste / file .conf / QR)
* Manajemen profil (secure storage, database lokal)
* Start/Stop tunnel (khusus Android)
* Monitoring status (handshake, rx/tx, endpoint)
* Log screen + masking otomatis
* Kunci biometrik (opsional)

---

## 🚀 Cara Memulai

1. Pastikan Flutter SDK sudah terpasang.
2. Clone repo ini:
	```bash
	git clone https://github.com/gustradev/vpn-client-wireguard-flutter.git
	cd vpn-client-wireguard-flutter
	```
3. Install dependency:
	```bash
	flutter pub get
	```
4. Jalankan aplikasi:
	```bash
	flutter run
	```
5. Build APK Android:
	```bash
	flutter build apk
	```

---

## 🗂️ Struktur Project

* **lib/app**: entry point, router, tema
* **lib/core**: constants, validator, log masker
* **lib/features**: fitur modular (profile, tunnel, log, status, settings)

---

## 📝 Catatan Penting

* ApplicationId: `com.example.gvpn`
* Branding: GVPN
* Semua config profile terenkripsi
* Tidak ada credential hardcoded

---

## 📚 Dokumentasi Lanjut

Lihat file:
* [SECURITY.md](SECURITY.md)
* [PROFILE_FORMAT.md](PROFILE_FORMAT.md)
* [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

<div align="center">
<img src="https://media.giphy.com/media/3o7aD2saalBwwftBIY/giphy.gif" alt="Secure Animation" width="120"/>
</div>

---

<div align="center">
<b>Copyright 2026 GVPN Project</b>
</div>
