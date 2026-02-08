import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';

void main() {
  runApp(const ProviderScope(child: GvpnApp()));
}

class GvpnApp extends StatelessWidget {
  const GvpnApp({super.key});

  @override
  Widget build(BuildContext context) {
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
