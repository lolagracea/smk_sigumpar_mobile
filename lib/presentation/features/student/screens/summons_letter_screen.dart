// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import '../../../../data/models/summons_letter_model.dart';
// import '../../../../data/models/student_model.dart';
// import '../providers/student_provider.dart';
// import '../../academic/providers/academic_provider.dart';
// import '../../../common/widgets/loading_widget.dart';
// import '../../../common/widgets/error_widget.dart';
//
// class SummonsLetterScreen extends StatefulWidget {
//   const SummonsLetterScreen({super.key});
//
//   @override
//   State<SummonsLetterScreen> createState() => _SummonsLetterScreenState();
// }
//
// class _SummonsLetterScreenState extends State<SummonsLetterScreen> {
//   bool _isShowingForm = false;
//   String? _selectedClassId;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initData();
//     });
//   }
//
//   Future<void> _initData() async {
//     final academicProvider = context.read<AcademicProvider>();
//     await academicProvider.fetchClasses(refresh: true);
//     if (academicProvider.classes.isNotEmpty) {
//       setState(() {
//         _selectedClassId = academicProvider.classes.first.id;
//       });
//       _fetchLetters();
//     }
//   }
//
//   void _fetchLetters() {
//     context.read<StudentProvider>().fetchSummonsLetters(classId: _selectedClassId);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isShowingForm ? 'Tambah Surat Panggilan' : 'Riwayat Surat Panggilan'),
//         backgroundColor: const Color(0xFF1E6091),
//         foregroundColor: Colors.white,
//         leading: _isShowingForm
//             ? IconButton(
//                 icon: const Icon(Icons.arrow_back),
//                 onPressed: () => setState(() => _isShowingForm = false),
//               )
//             : null,
//       ),
//       body: _isShowingForm
//           ? AddSummonsForm(
//               initialClassId: _selectedClassId,
//               onSuccess: () {
//                 setState(() => _isShowingForm = false);
//                 _fetchLetters();
//               },
//             )
//           : _buildHistoryList(),
//       floatingActionButton: !_isShowingForm
//           ? FloatingActionButton(
//               onPressed: () => setState(() => _isShowingForm = true),
//               backgroundColor: const Color(0xFF1E6091),
//               child: const Icon(Icons.add, color: Colors.white),
//             )
//           : null,
//     );
//   }
//
//   Widget _buildHistoryList() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Consumer<AcademicProvider>(
//             builder: (context, academic, child) {
//               if (academic.classes.isEmpty) return const SizedBox.shrink();
//               return DropdownButtonFormField<String>(
//                 value: _selectedClassId,
//                 decoration: InputDecoration(
//                   labelText: 'Pilih Kelas',
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 ),
//                 items: academic.classes.map((c) {
//                   return DropdownMenuItem(value: c.id, child: Text(c.namaKelas));
//                 }).toList(),
//                 onChanged: (val) {
//                   setState(() => _selectedClassId = val);
//                   _fetchLetters();
//                 },
//               );
//             },
//           ),
//         ),
//         Expanded(
//           child: Consumer<StudentProvider>(
//             builder: (context, provider, child) {
//               if (provider.summonsState == StudentLoadState.loading && provider.summonsLetters.isEmpty) {
//                 return const LoadingWidget();
//               }
//
//               if (provider.summonsState == StudentLoadState.error && provider.summonsLetters.isEmpty) {
//                 return AppErrorWidget(
//                   message: provider.summonsError ?? 'Gagal memuat data',
//                   onRetry: _fetchLetters,
//                 );
//               }
//
//               final letters = provider.summonsLetters;
//
//               if (letters.isEmpty) {
//                 return const Center(child: Text('Belum ada riwayat surat panggilan'));
//               }
//
//               return RefreshIndicator(
//                 onRefresh: () async => _fetchLetters(),
//                 child: ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: letters.length,
//                   itemBuilder: (context, index) {
//                     final letter = letters[index];
//                     return _SummonsCard(letter: letter);
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _SummonsCard extends StatelessWidget {
//   final SummonsLetterModel letter;
//   const _SummonsCard({required this.letter});
//
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'selesai':
//         return Colors.green;
//       case 'dikirim':
//         return Colors.blue;
//       default:
//         return Colors.orange;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Siswa #1', // Fallback, idealnya nama siswa dari model jika ada
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 Text(
//                   letter.status.toUpperCase(),
//                   style: TextStyle(
//                     color: _getStatusColor(letter.status),
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 4),
//             Text(
//               '${DateFormat('dd/MM/yyyy').format(letter.tanggal)} • ${letter.status}',
//               style: const TextStyle(color: Colors.grey, fontSize: 12),
//             ),
//             const Divider(height: 24),
//             Text(
//               letter.alasan ?? '-',
//               style: const TextStyle(fontSize: 14),
//             ),
//             if (letter.tindakLanjut != null && letter.tindakLanjut!.isNotEmpty) ...[
//               const SizedBox(height: 8),
//               Text(
//                 'Tindak lanjut: ${letter.tindakLanjut}',
//                 style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.blueGrey),
//               ),
//             ],
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
//                   onPressed: () {
//                     context.read<StudentProvider>().deleteSummonsLetter(letter.id);
//                   },
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class AddSummonsForm extends StatefulWidget {
//   final String? initialClassId;
//   final VoidCallback onSuccess;
//   const AddSummonsForm({super.key, this.initialClassId, required this.onSuccess});
//
//   @override
//   State<AddSummonsForm> createState() => _AddSummonsFormState();
// }
//
// class _AddSummonsFormState extends State<AddSummonsForm> {
//   final _formKey = GlobalKey<FormState>();
//   DateTime _selectedDate = DateTime.now();
//   String? _selectedClassId;
//   String? _selectedStudentId;
//   final _alasanController = TextEditingController();
//   final _tindakLanjutController = TextEditingController();
//   String _status = 'draft';
//   bool _isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedClassId = widget.initialClassId;
//     if (_selectedClassId != null) {
//       _fetchStudents();
//     }
//   }
//
//   void _fetchStudents() {
//     if (_selectedClassId != null) {
//       context.read<AcademicProvider>().fetchStudents(classId: _selectedClassId, refresh: true);
//     }
//   }
//
//   Future<void> _pickDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       setState(() => _selectedDate = picked);
//     }
//   }
//
//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate() || _selectedClassId == null || _selectedStudentId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Mohon lengkapi semua field wajib')),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//     try {
//       final data = {
//         'kelas_id': _selectedClassId,
//         'siswa_id': _selectedStudentId,
//         'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
//         'alasan': _alasanController.text,
//         'tindak_lanjut': _tindakLanjutController.text,
//         'status': _status,
//       };
//
//       await context.read<StudentProvider>().addSummonsLetter(data);
//       widget.onSuccess();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Gagal: $e')),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20.0),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('KELAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//             const SizedBox(height: 8),
//             Consumer<AcademicProvider>(
//               builder: (context, academic, child) {
//                 return DropdownButtonFormField<String>(
//                   value: _selectedClassId,
//                   hint: const Text('-- Pilih Kelas --'),
//                   decoration: const InputDecoration(border: OutlineInputBorder()),
//                   items: academic.classes.map((c) {
//                     return DropdownMenuItem(value: c.id, child: Text(c.namaKelas));
//                   }).toList(),
//                   onChanged: (val) {
//                     setState(() {
//                       _selectedClassId = val;
//                       _selectedStudentId = null;
//                     });
//                     _fetchStudents();
//                   },
//                 );
//               },
//             ),
//             const SizedBox(height: 16),
//             const Text('SISWA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//             const SizedBox(height: 8),
//             Consumer<AcademicProvider>(
//               builder: (context, academic, child) {
//                 return DropdownButtonFormField<String>(
//                   value: _selectedStudentId,
//                   hint: const Text('-- Pilih Siswa --'),
//                   decoration: const InputDecoration(border: OutlineInputBorder()),
//                   items: academic.students.map((s) {
//                     return DropdownMenuItem(value: s.id, child: Text(s.namaLengkap));
//                   }).toList(),
//                   onChanged: (val) => setState(() => _selectedStudentId = val),
//                   disabledHint: const Text('Pilih kelas terlebih dahulu'),
//                 );
//               },
//             ),
//             const SizedBox(height: 16),
//             const Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//             const SizedBox(height: 8),
//             InkWell(
//               onTap: _pickDate,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
//                     const Icon(Icons.calendar_today, size: 20),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text('ALASAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//             const SizedBox(height: 8),
//             TextFormField(
//               controller: _alasanController,
//               maxLines: 3,
//               decoration: const InputDecoration(
//                 hintText: 'Contoh: Perlu pembinaan terkait kedisiplinan...',
//                 border: OutlineInputBorder(),
//               ),
//               validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
//             ),
//             const SizedBox(height: 16),
//             const Text('TINDAK LANJUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//             const SizedBox(height: 8),
//             TextFormField(
//               controller: _tindakLanjutController,
//               maxLines: 2,
//               decoration: const InputDecoration(
//                 hintText: 'Opsional',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//             const SizedBox(height: 8),
//             DropdownButtonFormField<String>(
//               value: _status,
//               decoration: const InputDecoration(border: OutlineInputBorder()),
//               items: const [
//                 DropdownMenuItem(value: 'draft', child: Text('Draft')),
//                 DropdownMenuItem(value: 'dikirim', child: Text('Dikirim')),
//                 DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
//               ],
//               onChanged: (val) => setState(() => _status = val!),
//             ),
//             const SizedBox(height: 32),
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _submit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1E6091),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }
