import 'package:flutter/material.dart';
import 'package:vpn_client_wireguard_flutter/features/tunnel/domain/entities/tunnel_status.dart';

// Widget ringkas buat nampilin metrik status VPN
class StatusMetrics extends StatelessWidget {
  const StatusMetrics({super.key, required this.status});

  final TunnelStatus? status;

  @override
  Widget build(BuildContext context) {
    final isConnected = status?.isConnected ?? false;
    final handshake = status?.handshake;
    final stats = status?.transferStats;

    final handshakeText = handshake == null
        ? '-'
        : handshake.timestamp.toLocal().toString().split('.').first;

    final rxText = stats == null ? '-' : _formatBytes(stats.rxBytes);
    final txText = stats == null ? '-' : _formatBytes(stats.txBytes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricRow(
            label: 'Status', value: isConnected ? 'Connected' : 'Disconnected'),
        _MetricRow(label: 'Last handshake', value: handshakeText),
        _MetricRow(label: 'RX', value: rxText),
        _MetricRow(label: 'TX', value: txText),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
