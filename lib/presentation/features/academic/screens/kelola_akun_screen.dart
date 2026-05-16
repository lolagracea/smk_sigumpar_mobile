// lib/presentation/features/academic/screens/kelola_akun_screen.dart
//
// Fitur: Kelola Akun Sistem (Tata Usaha)
// Identik dengan KelolaAkunPage.jsx + UserForm.jsx di web microservice.
//
// Kolom tabel  : Nama Lengkap | Username | NIP/NISN | Hak Akses (Role) | Aksi
// Aksi tabel   : Edit | Hapus (dengan dialog konfirmasi)
// Modal Tambah : username, namaLengkap, nip, password, roles (checkbox multi)
// Modal Edit   : namaLengkap, nip, password (opsional), roles (checkbox multi)
//               username disabled saat edit (persis seperti web)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/models/kelola_akun_model.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../../data/repositories/kelola_akun_repository.dart';
import '../providers/academic_provider.dart';

// ─── Daftar Role — sama persis dengan AVAILABLE_ROLES di UserForm.jsx ─────────
const _kAvailableRoles = [
  _RoleItem(id: 'kepala-sekolah', label: 'Kepala Sekolah'),
  _RoleItem(id: 'waka-sekolah', label: 'Wakil Kepala Sekolah'),
  _RoleItem(id: 'guru-mapel', label: 'Guru Mapel'),
  _RoleItem(id: 'wali-kelas', label: 'Wali Kelas'),
  _RoleItem(id: 'tata-usaha', label: 'Tata Usaha'),
  _RoleItem(id: 'pramuka', label: 'Pramuka'),
  _RoleItem(id: 'vokasi', label: 'Vokasi'),
];

class _RoleItem {
  final String id;
  final String label;
  const _RoleItem({required this.id, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — dipasang di router
// ─────────────────────────────────────────────────────────────────────────────
class KelolaAkunScreen extends StatelessWidget {
  const KelolaAkunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(
        repository: sl<AcademicRepository>(),
        kelolaAkunRepository: sl<KelolaAkunRepository>(),
      )..fetchUsers(),
      child: const _KelolaAkunView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View utama
// ─────────────────────────────────────────────────────────────────────────────
class _KelolaAkunView extends StatelessWidget {
  const _KelolaAkunView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header (sama dengan web: judul + subtitle + tombol Tambah Akun) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola Akun Sistem',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daftar semua pengguna beserta hak aksesnya\n(Sinkronisasi Keycloak otomatis)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _openModal(context, editingUser: null),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Akun'),
              ),
            ],
          ),
        ),

        // ── Konten utama ──────────────────────────────────────────────────
        Expanded(child: _buildBody(context, provider, isDark)),
      ],
    );
  }

  Widget _buildBody(
      BuildContext context, AcademicProvider provider, bool isDark) {
    if (provider.kelolaAkunState == AcademicLoadState.loading &&
        provider.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Mensinkronkan data dengan Keycloak...',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.kelolaAkunState == AcademicLoadState.error &&
        provider.users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48,
                  color: isDark ? AppColors.error : Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                provider.kelolaAkunError ?? 'Gagal memuat daftar akun',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => context.read<AcademicProvider>().fetchUsers(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AcademicProvider>().fetchUsers(),
      child: provider.users.isEmpty
          ? _buildEmpty(isDark)
          : _buildList(context, provider, isDark),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 160),
        Center(
          child: Text(
            'Belum ada akun terdaftar.',
            style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
      BuildContext context, AcademicProvider provider, bool isDark) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: provider.users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = provider.users[index];
        return _UserCard(
          user: user,
          isDark: isDark,
          onEdit: () => _openModal(context, editingUser: user),
          onDelete: () => _confirmDelete(context, user, isDark),
        );
      },
    );
  }

  // ── Buka Modal Tambah / Edit ───────────────────────────────────────────────
  void _openModal(BuildContext context,
      {required KelolaAkunModel? editingUser}) {
    final provider = context.read<AcademicProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: _UserFormSheet(editingUser: editingUser),
        );
      },
    );
  }

  // ── Dialog konfirmasi hapus — persis logika web ────────────────────────────
  void _confirmDelete(
      BuildContext context, KelolaAkunModel user, bool isDark) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Akun',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun ini secara permanen?',
          style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Batal',
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade700),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      if (!context.mounted) return;

      final prov = context.read<AcademicProvider>();
      final ok = await prov.deleteUser(user.idKeycloak);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Akun berhasil dihapus!'
                : prov.mutationAkunError ?? 'Gagal menghapus akun.',
          ),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card user — baris data (adaptasi tabel web ke kartu mobile)
// Kolom: Nama Lengkap | Username | NIP/NISN | Hak Akses (Role) | Aksi
// ─────────────────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final KelolaAkunModel user;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Card(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Baris atas: Avatar + Nama + Aksi ──────────────────────────
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2563EB).withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: isDark ? const Color(0xFF60A5FA) : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.namaLengkap.isNotEmpty
                            ? user.namaLengkap
                            : user.username,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tombol Edit
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFF818CF8)
                        : const Color(0xFF4F46E5),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 4),
                // Tombol Hapus
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.red.shade400 : Colors.red.shade700,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Hapus'),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
            const SizedBox(height: 10),

            // ── NIP/NISN ──────────────────────────────────────────────────
            _InfoRow(
              label: 'NIP / NISN',
              value: user.nip?.isNotEmpty == true ? user.nip! : '-',
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            // ── Hak Akses (Role) ─────────────────────────────────────────
            _RoleChips(roles: user.roles, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleChips extends StatelessWidget {
  final List<String> roles;
  final bool isDark;

  const _RoleChips({required this.roles, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return Text(
        'Belum ada role',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: roles.map((role) {
        final display = role.replaceAll('-', ' ').toUpperCase();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            // indigo-50 / indigo-700 — persis warna web
            color: isDark
                ? const Color(0xFF3730A3).withOpacity(0.25)
                : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF4338CA).withOpacity(0.4)
                  : const Color(0xFFE0E7FF),
            ),
          ),
          child: Text(
            display,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFFA5B4FC)
                  : const Color(0xFF4338CA),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet Form — identik dengan UserForm.jsx
// ─────────────────────────────────────────────────────────────────────────────
class _UserFormSheet extends StatefulWidget {
  final KelolaAkunModel? editingUser;

  const _UserFormSheet({this.editingUser});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<String> _selectedRoles = [];
  bool _isLoadingRoles = false;
  bool _showPassword = false;
  bool _isSubmitting = false;

  bool get _isEdit => widget.editingUser != null;

  @override
  void initState() {
    super.initState();
    final user = widget.editingUser;
    if (user != null) {
      _usernameController.text = user.username;
      _namaController.text = user.namaLengkap;
      _nipController.text = user.nip ?? '';
      _loadRoles(user.idKeycloak);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _namaController.dispose();
    _nipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles(String idKeycloak) async {
    setState(() => _isLoadingRoles = true);
    final roles =
        await context.read<AcademicProvider>().getUserRoles(idKeycloak);
    if (mounted) {
      setState(() {
        _selectedRoles = List.from(roles);
        _isLoadingRoles = false;
      });
    }
  }

  void _toggleRole(String roleId) {
    setState(() {
      if (_selectedRoles.contains(roleId)) {
        _selectedRoles.remove(roleId);
      } else {
        _selectedRoles.add(roleId);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal pilih 1 Hak Akses'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<AcademicProvider>();
    bool ok;

    if (_isEdit) {
      ok = await provider.updateUser(
        widget.editingUser!.idKeycloak,
        UpdateAkunPayload(
          namaLengkap: _namaController.text.trim(),
          nipVal: _nipController.text.trim().isEmpty
              ? null
              : _nipController.text.trim(),
          password: _passwordController.text.trim().isEmpty
              ? null
              : _passwordController.text.trim(),
          roles: _selectedRoles,
        ),
      );
    } else {
      ok = await provider.createUser(
        CreateAkunPayload(
          username: _usernameController.text.trim(),
          namaLengkap: _namaController.text.trim(),
          nip: _nipController.text.trim().isEmpty
              ? null
              : _nipController.text.trim(),
          password: _passwordController.text.trim(),
          roles: _selectedRoles,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Perubahan akun berhasil disimpan!'
                : 'Akun baru berhasil dibuat!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.mutationAkunError ?? 'Terjadi kesalahan sistem.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Judul modal
                Text(
                  _isEdit ? 'Edit Akun' : 'Tambah Akun Baru',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Divider(
                    height: 28,
                    color: isDark ? Colors.white12 : Colors.grey.shade200),

                // ── Username (disabled saat edit — persis web) ─────────────
                _buildLabel('Username', required: true, isDark: isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _usernameController,
                  enabled: !_isEdit && !_isSubmitting,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: _inputDecoration(
                    hint: 'Masukkan username',
                    isDark: isDark,
                    disabled: _isEdit,
                  ),
                  validator: (v) {
                    if (!_isEdit && (v == null || v.trim().isEmpty)) {
                      return 'Username wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Nama Lengkap ───────────────────────────────────────────
                _buildLabel('Nama Lengkap', required: true, isDark: isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _namaController,
                  enabled: !_isSubmitting,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: _inputDecoration(
                      hint: 'Masukkan nama lengkap', isDark: isDark),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama Lengkap wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── NIP / NISN ────────────────────────────────────────────
                _buildLabel('NIP / NISN', isDark: isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nipController,
                  enabled: !_isSubmitting,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: _inputDecoration(
                      hint: 'NIP atau NISN (opsional)', isDark: isDark),
                ),
                const SizedBox(height: 14),

                // ── Password ──────────────────────────────────────────────
                _buildLabel(
                  'Password',
                  isDark: isDark,
                  subtitle: _isEdit ? '(Isi jika ingin diubah)' : null,
                  required: !_isEdit,
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isSubmitting,
                  obscureText: !_showPassword,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: _inputDecoration(
                    hint: _isEdit
                        ? 'Biarkan kosong jika tidak diubah'
                        : 'Masukkan password',
                    isDark: isDark,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color:
                            isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) {
                    if (!_isEdit && (v == null || v.trim().isEmpty)) {
                      return 'Password wajib diisi untuk akun baru';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Hak Akses / Role (checkbox multi, 2 kolom) ─────────────
                _buildLabel('Hak Akses (Role)',
                    required: true, isDark: isDark),
                const SizedBox(height: 8),

                if (_isLoadingRoles)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                      ),
                    ),
                    // Grid 2 kolom — sama seperti web (grid-cols-2 gap-3)
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 4,
                      childAspectRatio: 4.5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _kAvailableRoles.map((role) {
                        final checked = _selectedRoles.contains(role.id);
                        return InkWell(
                          onTap: _isSubmitting
                              ? null
                              : () => _toggleRole(role.id),
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            children: [
                              Checkbox(
                                value: checked,
                                onChanged: _isSubmitting
                                    ? null
                                    : (_) => _toggleRole(role.id),
                                activeColor: const Color(0xFF2563EB),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              Flexible(
                                child: Text(
                                  role.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 28),

                // ── Tombol Batal + Simpan ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300),
                          foregroundColor: isDark
                              ? Colors.white70
                              : Colors.grey.shade700,
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? Colors.white12
                              : Colors.grey.shade300,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Simpan Perubahan' : 'Buat Akun',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(
    String text, {
    bool required = false,
    String? subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        if (required) const Text(' *', style: TextStyle(color: Colors.red)),
        if (subtitle != null) ...[
          const SizedBox(width: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    bool disabled = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
      filled: true,
      fillColor: disabled
          ? (isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.shade100)
          : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade50),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade200),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}