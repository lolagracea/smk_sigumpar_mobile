import 'package:flutter/material.dart';

class ItemLoanScreen extends StatelessWidget {
  const ItemLoanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peminjaman Barang')),
      body: const Center(
        child: Text('Halaman Peminjaman Barang\n(Dalam Pengembangan)', textAlign: TextAlign.center),
      ),
    );
  }
}
