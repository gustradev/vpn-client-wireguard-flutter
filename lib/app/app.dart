// Entry point GVPN app
import 'package:flutter/material.dart';

class GvpnLegacyApp extends StatelessWidget {
  const GvpnLegacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GVPN',
      theme: ThemeData.light(),
      home: const Scaffold(
        body: Center(child: Text('GVPN Home')),
      ),
    );
  }
}
