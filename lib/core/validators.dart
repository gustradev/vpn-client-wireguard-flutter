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
  // Validasi: boleh satu atau beberapa CIDR dipisah koma.
  // Contoh: 10.0.0.2/32 atau 10.0.0.2/32, fd00::2/128
  final parts = address
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return false;
  for (final part in parts) {
    if (!part.contains('/')) return false;
    if (part.split('/').length != 2) return false;
  }
  return true;
}

bool validateAllowedIPs(String allowedIps) {
  // Validasi: minimal satu IP, format CIDR
  return allowedIps.split(',').any((ip) => ip.contains('/'));
}

bool validateEndpoint(String endpoint) {
  // Endpoint wajib punya host:port
  if (endpoint.trim().isEmpty) return false;
  return endpoint.contains(':');
}

// Bisa ditambah validasi lain sesuai kebutuhan
