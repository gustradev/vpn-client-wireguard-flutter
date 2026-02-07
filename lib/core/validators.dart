// Validators untuk WireGuard config

bool validatePrivateKey(String key) {
  // Validasi sederhana: panjang 32 byte base64 (44 karakter)
  return key.isNotEmpty && key.length == 44 && key.endsWith('=');
}

bool validatePublicKey(String key) {
  // Validasi sederhana: panjang 32 byte base64 (44 karakter)
  return key.isNotEmpty && key.length == 44 && key.endsWith('=');
}

bool validateAddress(String address) {
  // Validasi: harus ada '/' (CIDR), contoh: 10.0.0.2/32
  return address.contains('/') && address.split('/').length == 2;
}

bool validateAllowedIPs(String allowedIps) {
  // Validasi: minimal satu IP, format CIDR
  return allowedIps.split(',').any((ip) => ip.contains('/'));
}

// Bisa ditambah validasi lain sesuai kebutuhan
