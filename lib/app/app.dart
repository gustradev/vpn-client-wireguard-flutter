// Entry point GVPN app
import 'package:flutter/material.dart';

class GvpnApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GVPN',
      theme: ThemeData.light(),
      home: Scaffold(
        body: Center(child: Text('GVPN Home')),
      ),
    );
  }
}
