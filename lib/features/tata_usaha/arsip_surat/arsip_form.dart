import 'package:flutter/material.dart';
import 'file_picker_widget.dart';

class ArsipForm extends StatelessWidget {
  const ArsipForm({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Form Arsip Surat'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(decoration: InputDecoration(labelText: 'Nomor Surat')),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Perihal')),
          SizedBox(height: 12),
          FilePickerWidget(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
