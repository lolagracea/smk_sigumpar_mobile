import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry; // 🔥 tambahin ini

  const ErrorStateWidget({
    required this.message,
    this.onRetry, // 🔥 tambahin ini
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message),
        const SizedBox(height: 10),

        // 🔥 tombol retry (opsional)
        if (onRetry != null)
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
      ],
    );
  }
}
