import 'package:flutter/material.dart';

class FilePickerWidget extends StatelessWidget {
  const FilePickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: integrasi file_picker
      },
      icon: const Icon(Icons.attach_file),
      label: const Text('Pilih File'),
    );
  }
}
