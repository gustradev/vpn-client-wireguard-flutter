import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vpn_client_wireguard_flutter/core/log_masker.dart';
import 'package:vpn_client_wireguard_flutter/features/log/domain/entities/log_entry.dart';
import 'package:vpn_client_wireguard_flutter/features/log/presentation/providers/log_providers.dart';

// Screen sederhana buat lihat log client
class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: () => ref.read(logListProvider.notifier).clearLogs(),
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      body: logs.isEmpty
          ? Center(
              child: Text(
                'Belum ada log',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _LogTile(entry: log);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(logListProvider.notifier).addLog(
                level: LogLevel.info,
                message: 'Dummy log: PrivateKey = ABCDEFGHIJKLMNOP',
                tag: 'demo',
              );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah log'),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(entry.level);
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            entry.level.shortName,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(maskSensitive(entry.message)),
        subtitle: Text(entry.displayTimestamp),
      ),
    );
  }

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.blueGrey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.fatal:
        return Colors.redAccent;
    }
  }
}
