import 'package:flutter/material.dart';

// Tile pengaturan sederhana (toggle)
class SettingToggleTile extends StatefulWidget {
  const SettingToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.initialValue = false,
    this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  @override
  State<SettingToggleTile> createState() => _SettingToggleTileState();
}

class _SettingToggleTileState extends State<SettingToggleTile> {
  late bool value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        secondary: CircleAvatar(child: Icon(widget.icon)),
        value: value,
        onChanged: (v) {
          setState(() => value = v);
          widget.onChanged?.call(v);
        },
        title: Text(widget.title),
        subtitle: Text(widget.subtitle),
      ),
    );
  }
}
