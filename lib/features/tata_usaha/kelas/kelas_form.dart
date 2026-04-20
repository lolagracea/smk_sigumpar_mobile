import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';

class KelasForm extends StatefulWidget {
  const KelasForm({super.key});

  @override
  State<KelasForm> createState() => _KelasFormState();
}

class _KelasFormState extends State<KelasForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _tingkatController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _tingkatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Form Kelas'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Kelas'),
                validator: (v) => Validators.requiredField(v, label: 'Nama kelas'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tingkatController,
                decoration: const InputDecoration(labelText: 'Tingkat'),
                validator: (v) => Validators.requiredField(v, label: 'Tingkat'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
