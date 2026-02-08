// Utility buat masking data sensitif di log.
// Fokus ke key WireGuard: PrivateKey, PresharedKey, PublicKey, Endpoint token.

String maskSensitive(String input) {
  var output = input;

  // Mask key-value WireGuard
  output = _maskKeyValue(output, 'PrivateKey');
  output = _maskKeyValue(output, 'PresharedKey');
  output = _maskKeyValue(output, 'PublicKey');

  // Mask base64-ish token panjang
  output = output.replaceAll(
    RegExp(r'([A-Za-z0-9+/]{20,}={0,2})'),
    '***masked***',
  );

  return output;
}

String _maskKeyValue(String input, String key) {
  final regex = RegExp(
    '${RegExp.escape(key)}\\s*=\\s*([^\\n\\r]+)',
    caseSensitive: false,
  );
  return input.replaceAllMapped(regex, (match) {
    return '$key = ***masked***';
  });
}
