import 'package:flutter/services.dart';

// Bridge ke native Android (MethodChannel/EventChannel)
class WgPlatformChannel {
  static const MethodChannel _channel = MethodChannel('gvpn/wireguard');
  static const EventChannel _statsChannel =
      EventChannel('gvpn/wireguard_stats');

  Future<Map<String, dynamic>> startTunnel({
    required String profileId,
    String? config,
  }) async {
    final payload = <String, dynamic>{
      'profileId': profileId,
    };
    if (config != null) {
      payload['config'] = config;
    }
    final result = await _channel.invokeMethod('startTunnel', payload);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> stopTunnel() async {
    final result = await _channel.invokeMethod('stopTunnel');
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> getStatus() async {
    final result = await _channel.invokeMethod('getStatus');
    return Map<String, dynamic>.from(result as Map);
  }

  Future<bool> prepareVpn() async {
    final result = await _channel.invokeMethod('prepareVpn');
    return result == true;
  }

  Stream<Map<String, dynamic>> observeStats() {
    return _statsChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
  }
}
