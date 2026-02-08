import 'package:vpn_client_wireguard_flutter/core/log_masker.dart';

// Wrapper biar domain log bisa pakai masker di core
String maskLogMessage(String message) {
  return maskSensitive(message);
}
