import 'package:flutter/material.dart';

class DropdownSelector extends StatelessWidget {
  final String label;
  final List<String> items;
  final Function(String?) onChanged;

  DropdownSelector({required this.label, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }
}