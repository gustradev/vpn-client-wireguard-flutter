import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'features/tunnel/presentation/providers/tunnel_providers.dart';

void main() {
  runApp(const ProviderScope(child: GvpnApp()));
}

class GvpnApp extends ConsumerWidget {
  const GvpnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep a single stats stream subscription alive for the whole app.
    ref.watch(tunnelStatsSyncProvider);
    return MaterialApp.router(
      title: 'GVPN',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
