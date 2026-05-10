import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';

class _KelasOption {
  final String id;
  final String namaKelas;

  const _KelasOption({
    required this.id,
    required this.namaKelas,
  });

  factory _KelasOption.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['kelas_id'] ?? '').toString();

    return _KelasOption(
      id: id,
      namaKelas: (json['nama_kelas'] ??
          json['nama'] ??
          json['name'] ??
          'Kelas $id')
          .toString(),
    );
  }
}

class _SiswaPkl {
  final String id;
  final String nama;
  final String nisn;

  const _SiswaPkl({
    required this.id,
    required this.nama,
    required this.nisn,
  });

  factory _SiswaPkl.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['siswa_id'] ?? '').toString();

    return _SiswaPkl(
      id: id,
      nama: (json['nama_lengkap'] ??
          json['nama_siswa'] ??
          json['nama'] ??
          '-')
          .toString(),
      nisn: (json['nisn'] ?? json['nis'] ?? '-').toString(),
    );
  }
}

class _LokasiPkl {
  final int id;
  final String siswaId;
  final String namaSiswa;
  final String nisn;
  final String namaPerusahaan;
  final String alamat;
  final String posisi;
  final String deskripsiPekerjaan;
  final String pembimbingIndustri;
  final String kontakPembimbing;
  final String tanggal;
  final String tanggalSelesai;
  final String? fotoUrl;

  const _LokasiPkl({
    required this.id,
    required this.siswaId,
    required this.namaSiswa,
    required this.nisn,
    required this.namaPerusahaan,
    required this.alamat,
    required this.posisi,
    required this.deskripsiPekerjaan,
    required this.pembimbingIndustri,
    required this.kontakPembimbing,
    required this.tanggal,
    required this.tanggalSelesai,
    required this.fotoUrl,
  });

  factory _LokasiPkl.fromJson(Map<String, dynamic> json) {
    return _LokasiPkl(
      id: _toInt(json['id']),
      siswaId: (json['siswa_id'] ?? '').toString(),
      namaSiswa: (json['nama_siswa'] ?? '-').toString(),
      nisn: (json['nisn'] ?? '-').toString(),
      namaPerusahaan: (json['nama_perusahaan'] ?? '-').toString(),
      alamat: (json['alamat'] ?? '-').toString(),
      posisi: (json['posisi'] ?? '-').toString(),
      deskripsiPekerjaan: (json['deskripsi_pekerjaan'] ?? '-').toString(),
      pembimbingIndustri: (json['pembimbing_industri'] ?? '-').toString(),
      kontakPembimbing: (json['kontak_pembimbing'] ?? '-').toString(),
      tanggal: (json['tanggal'] ?? '-').toString(),
      tanggalSelesai: (json['tanggal_selesai'] ?? '-').toString(),
      fotoUrl: json['foto_url']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

class _ProgresPkl {
  final int id;
  final String siswaId;
  final String namaSiswa;
  final String nisn;
  final int mingguKe;
  final String deskripsi;

  const _ProgresPkl({
    required this.id,
    required this.siswaId,
    required this.namaSiswa,
    required this.nisn,
    required this.mingguKe,
    required this.deskripsi,
  });

  factory _ProgresPkl.fromJson(Map<String, dynamic> json) {
    return _ProgresPkl(
      id: _toInt(json['id']),
      siswaId: (json['siswa_id'] ?? '').toString(),
      namaSiswa: (json['nama_siswa'] ?? '-').toString(),
      nisn: (json['nisn'] ?? '-').toString(),
      mingguKe: _toInt(json['minggu_ke']),
      deskripsi: (json['deskripsi'] ?? '-').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

class _NilaiPkl {
  final int id;
  final String siswaId;
  final String namaSiswa;
  final String nisn;
  final double? praktik;
  final double? sikap;
  final double? laporan;
  final double? nilaiAkhir;
  final String predikat;
  final String catatan;

  const _NilaiPkl({
    required this.id,
    required this.siswaId,
    required this.namaSiswa,
    required this.nisn,
    required this.praktik,
    required this.sikap,
    required this.laporan,
    required this.nilaiAkhir,
    required this.predikat,
    required this.catatan,
  });

  factory _NilaiPkl.fromJson(Map<String, dynamic> json) {
    final praktik = _toDoubleNullable(json['nilai_praktik']);
    final sikap = _toDoubleNullable(json['nilai_sikap']);
    final laporan = _toDoubleNullable(json['nilai_laporan']);

    final computed = praktik == null || sikap == null || laporan == null
        ? null
        : praktik * 0.4 + sikap * 0.3 + laporan * 0.3;

    return _NilaiPkl(
      id: _toInt(json['id']),
      siswaId: (json['siswa_id'] ?? '').toString(),
      namaSiswa: (json['nama_siswa'] ?? '-').toString(),
      nisn: (json['nisn'] ?? '-').toString(),
      praktik: praktik,
      sikap: sikap,
      laporan: laporan,
      nilaiAkhir: _toDoubleNullable(json['nilai_akhir']) ?? computed,
      predikat: (json['predikat'] ?? '-').toString(),
      catatan: (json['catatan'] ?? '-').toString(),
    );
  }

  bool get sudahDiinput {
    return praktik != null || sikap != null || laporan != null || nilaiAkhir != null;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString());
  }
}

class PklKepsekScreen extends StatefulWidget {
  const PklKepsekScreen({super.key});

  @override
  State<PklKepsekScreen> createState() => _PklKepsekScreenState();
}

class _PklKepsekScreenState extends State<PklKepsekScreen> {
  bool _loadingKelas = false;
  bool _loadingData = false;
  bool _sudahCari = false;
  String? _error;

  List<_KelasOption> _kelasList = [];
  List<_SiswaPkl> _siswaList = [];
  List<_LokasiPkl> _lokasiData = [];
  List<_ProgresPkl> _progresData = [];
  List<_NilaiPkl> _nilaiData = [];

  String? _selectedKelasId;
  String _activeTab = 'rekap';

  @override
  void initState() {
    super.initState();
    _loadKelas();
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;

    if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) return raw['data'] as List;

      if (raw['data'] is Map<String, dynamic>) {
        final data = raw['data'] as Map<String, dynamic>;

        if (data['data'] is List) return data['data'] as List;
        if (data['items'] is List) return data['items'] as List;
        if (data['rows'] is List) return data['rows'] as List;
      }

      if (raw['items'] is List) return raw['items'] as List;
      if (raw['rows'] is List) return raw['rows'] as List;
    }

    return [];
  }

  String get _namaKelas {
    for (final kelas in _kelasList) {
      if (kelas.id == _selectedKelasId) return kelas.namaKelas;
    }

    return '-';
  }

  Map<String, _LokasiPkl> get _lokasiBySiswaId {
    return {
      for (final lokasi in _lokasiData)
        if (lokasi.siswaId.isNotEmpty) lokasi.siswaId: lokasi,
    };
  }

  Map<String, List<_ProgresPkl>> get _progresBySiswaId {
    final map = <String, List<_ProgresPkl>>{};

    for (final progres in _progresData) {
      final key = progres.siswaId;
      map.putIfAbsent(key, () => []);
      map[key]!.add(progres);
    }

    return map;
  }

  Map<String, _NilaiPkl> get _nilaiBySiswaId {
    return {
      for (final nilai in _nilaiData)
        if (nilai.siswaId.isNotEmpty) nilai.siswaId: nilai,
    };
  }

  int get _totalSiswa => _siswaList.length;

  int get _sudahLokasi {
    int total = 0;

    for (final siswa in _siswaList) {
      if (_hasLokasi(siswa)) total++;
    }

    return total;
  }

  int get _sudahProgres {
    int total = 0;

    for (final siswa in _siswaList) {
      if ((_progresBySiswaId[siswa.id] ?? []).isNotEmpty) total++;
    }

    return total;
  }

  int get _sudahNilai {
    int total = 0;

    for (final siswa in _siswaList) {
      final nilai = _nilaiBySiswaId[siswa.id];
      if (nilai != null && nilai.sudahDiinput) total++;
    }

    return total;
  }

  bool _hasLokasi(_SiswaPkl siswa) {
    if (_lokasiBySiswaId[siswa.id] != null) return true;

    return _lokasiData.any(
          (lokasi) => lokasi.namaSiswa.toLowerCase() == siswa.nama.toLowerCase(),
    );
  }

  _LokasiPkl? _lokasiForSiswa(_SiswaPkl siswa) {
    return _lokasiBySiswaId[siswa.id] ??
        _lokasiData.cast<_LokasiPkl?>().firstWhere(
              (lokasi) =>
          lokasi?.namaSiswa.toLowerCase() == siswa.nama.toLowerCase(),
          orElse: () => null,
        );
  }

  _NilaiPkl? _nilaiForSiswa(_SiswaPkl siswa) {
    return _nilaiBySiswaId[siswa.id];
  }

  List<_ProgresPkl> _progresForSiswa(_SiswaPkl siswa) {
    return _progresBySiswaId[siswa.id] ?? [];
  }

  Future<void> _loadKelas() async {
    setState(() {
      _loadingKelas = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final response = await dio.get(ApiEndpoints.vocationalClasses);
      final rows = _extractList(response.data);

      setState(() {
        _kelasList = rows
            .whereType<Map>()
            .map(
              (item) => _KelasOption.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .where((item) => item.id.isNotEmpty)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = _messageFromError(
          e,
          fallback: 'Gagal memuat daftar kelas',
        );
        _kelasList = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingKelas = false;
        });
      }
    }
  }

  Future<void> _loadDataPkl() async {
    final kelasId = _selectedKelasId;

    if (kelasId == null || kelasId.isEmpty) {
      _showSnack('Pilih kelas terlebih dahulu');
      return;
    }

    setState(() {
      _loadingData = true;
      _sudahCari = true;
      _error = null;
    });

    try {
      final dio = sl<DioClient>();

      final responses = await Future.wait([
        dio.get(
          ApiEndpoints.vocationalStudents,
          queryParameters: {'kelas_id': kelasId},
        ),
        dio.get(
          ApiEndpoints.pklLocation,
          queryParameters: {'kelas_id': kelasId},
        ),
        dio.get(
          ApiEndpoints.pklProgress,
          queryParameters: {'kelas_id': kelasId},
        ),
        dio.get(
          ApiEndpoints.pklGrades,
          queryParameters: {'kelas_id': kelasId},
        ),
      ]);

      final siswaRows = _extractList(responses[0].data);
      final lokasiRows = _extractList(responses[1].data);
      final progresRows = _extractList(responses[2].data);
      final nilaiRows = _extractList(responses[3].data);

      setState(() {
        _siswaList = siswaRows
            .whereType<Map>()
            .map(
              (item) => _SiswaPkl.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .where((item) => item.id.isNotEmpty)
            .toList();

        _lokasiData = lokasiRows
            .whereType<Map>()
            .map(
              (item) => _LokasiPkl.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .where((item) => item.id > 0)
            .toList();

        _progresData = progresRows
            .whereType<Map>()
            .map(
              (item) => _ProgresPkl.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .where((item) => item.id > 0)
            .toList();

        _nilaiData = nilaiRows
            .whereType<Map>()
            .map(
              (item) => _NilaiPkl.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
            .where((item) => item.siswaId.isNotEmpty)
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = _messageFromError(
          e,
          fallback: 'Gagal memuat data PKL',
        );
        _siswaList = [];
        _lokasiData = [];
        _progresData = [];
        _nilaiData = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingData = false;
        });
      }
    }
  }

  String _messageFromError(
      Object error, {
        required String fallback,
      }) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }

      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
    }

    return fallback;
  }

  String _formatDate(String value) {
    if (value.isEmpty || value == '-') return '-';

    try {
      final parsed = DateTime.parse(value);
      return DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      return value;
    }
  }

  String _formatNumber(double? value) {
    if (value == null) return '-';

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  double? _hitungAkhir(_NilaiPkl? nilai) {
    if (nilai == null) return null;

    if (nilai.nilaiAkhir != null) return nilai.nilaiAkhir;

    if (nilai.praktik == null || nilai.sikap == null || nilai.laporan == null) {
      return null;
    }

    return nilai.praktik! * 0.4 + nilai.sikap! * 0.3 + nilai.laporan! * 0.3;
  }

  String _fullPhotoUrl(String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) return '';

    if (fotoUrl.startsWith('http')) return fotoUrl;

    return '${ApiEndpoints.baseUrl}$fotoUrl';
  }

  void _showPhotoPreview(String? fotoUrl) {
    final url = _fullPhotoUrl(fotoUrl);

    if (url.isEmpty) {
      _showSnack('Foto tidak tersedia');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Foto Lokasi PKL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Gagal memuat foto'),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refresh() async {
    await _loadKelas();

    if (_selectedKelasId != null && _selectedKelasId!.isNotEmpty) {
      await _loadDataPkl();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F7FA),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 12),
            _buildFilterCard(isDark),
            const SizedBox(height: 12),
            if (_error != null) ...[
              _buildError(),
              const SizedBox(height: 12),
            ],
            if (_loadingData)
              const Padding(
                padding: EdgeInsets.only(top: 56),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!_sudahCari)
              _buildEmpty(
                icon: Icons.work_history_outlined,
                message: 'Pilih kelas lalu tekan Tampilkan Data.',
              )
            else ...[
                _buildSummaryGrid(),
                const SizedBox(height: 10),
                Text(
                  'Kelas: $_namaKelas · Sumber data: Academic Service & Vocational Service',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTabs(),
                const SizedBox(height: 12),
                _buildActiveTabContent(isDark),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monitoring PKL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pantau lokasi, progres, nilai, dan status kelengkapan PKL siswa berdasarkan kelas.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedKelasId,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              labelText: _loadingKelas ? 'Memuat kelas...' : 'Kelas',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.class_outlined),
            ),
            items: _kelasList.map((kelas) {
              return DropdownMenuItem(
                value: kelas.id,
                child: Text(
                  kelas.namaKelas,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _loadingKelas
                ? null
                : (value) {
              setState(() {
                _selectedKelasId = value;
                _sudahCari = false;
                _siswaList = [];
                _lokasiData = [];
                _progresData = [];
                _nilaiData = [];
                _activeTab = 'rekap';
              });
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadingData ? null : _loadDataPkl,
              icon: const Icon(Icons.search),
              label: Text(_loadingData ? 'Memuat...' : 'Tampilkan Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryBox(
          icon: Icons.groups_outlined,
          label: 'Total Siswa',
          value: _totalSiswa,
          color: Colors.grey,
        ),
        _SummaryBox(
          icon: Icons.location_on_outlined,
          label: 'Input Lokasi',
          value: _sudahLokasi,
          color: const Color(0xFF2563EB),
        ),
        _SummaryBox(
          icon: Icons.timeline_outlined,
          label: 'Buat Laporan',
          value: _sudahProgres,
          color: const Color(0xFF16A34A),
        ),
        _SummaryBox(
          icon: Icons.grade_outlined,
          label: 'Sudah Dinilai',
          value: _sudahNilai,
          color: const Color(0xFF9333EA),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = [
      _TabItem(
        keyName: 'rekap',
        label: 'Rekap Siswa',
        icon: Icons.bar_chart_outlined,
        count: _siswaList.length,
      ),
      _TabItem(
        keyName: 'lokasi',
        label: 'Lokasi PKL',
        icon: Icons.location_on_outlined,
        count: _lokasiData.length,
      ),
      _TabItem(
        keyName: 'progres',
        label: 'Laporan Progres',
        icon: Icons.timeline_outlined,
        count: _progresData.length,
      ),
      _TabItem(
        keyName: 'nilai',
        label: 'Nilai PKL',
        icon: Icons.grade_outlined,
        count: _sudahNilai,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tabs.map((tab) {
        final active = _activeTab == tab.keyName;

        return ChoiceChip(
          selected: active,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 16,
                color: active ? Colors.white : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 6),
              Text(tab.label),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withOpacity(0.18) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tab.count}',
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          selectedColor: const Color(0xFF2563EB),
          onSelected: (_) {
            setState(() {
              _activeTab = tab.keyName;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildActiveTabContent(bool isDark) {
    switch (_activeTab) {
      case 'lokasi':
        return _buildLokasiTab(isDark);
      case 'progres':
        return _buildProgresTab(isDark);
      case 'nilai':
        return _buildNilaiTab(isDark);
      case 'rekap':
      default:
        return _buildRekapTab(isDark);
    }
  }

  Widget _buildRekapTab(bool isDark) {
    if (_siswaList.isEmpty) {
      return _buildEmpty(
        icon: Icons.groups_outlined,
        message: 'Belum ada data siswa pada kelas ini.',
      );
    }

    return Column(
      children: _siswaList.asMap().entries.map((entry) {
        final index = entry.key;
        final siswa = entry.value;
        final lokasi = _lokasiForSiswa(siswa);
        final progresList = _progresForSiswa(siswa);
        final nilai = _nilaiForSiswa(siswa);
        final nilaiAkhir = _hitungAkhir(nilai);
        final lengkap =
            lokasi != null && progresList.isNotEmpty && nilai?.sudahDiinput == true;

        return _buildRekapSiswaCard(
          index: index,
          siswa: siswa,
          lokasi: lokasi,
          progresCount: progresList.length,
          nilaiAkhir: nilaiAkhir,
          lengkap: lengkap,
          isDark: isDark,
        );
      }).toList(),
    );
  }

  Widget _buildRekapSiswaCard({
    required int index,
    required _SiswaPkl siswa,
    required _LokasiPkl? lokasi,
    required int progresCount,
    required double? nilaiAkhir,
    required bool lengkap,
    required bool isDark,
  }) {
    final statusColor = lengkap ? const Color(0xFF2563EB) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: statusColor.withOpacity(0.12),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StudentTitle(
                  nama: siswa.nama,
                  nisn: siswa.nisn,
                  isDark: isDark,
                ),
              ),
              _StatusBadge(
                text: lengkap ? 'Lengkap' : 'Belum Lengkap',
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStatus(
                label: 'Lokasi',
                value: lokasi != null ? 'Sudah' : 'Belum',
                success: lokasi != null,
              ),
              _MiniStatus(
                label: 'Progres',
                value: progresCount > 0 ? '$progresCount Minggu' : 'Belum',
                success: progresCount > 0,
              ),
              _MiniStatus(
                label: 'Nilai',
                value: nilaiAkhir == null ? 'Belum' : _formatNumber(nilaiAkhir),
                success: nilaiAkhir != null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLokasiTab(bool isDark) {
    if (_lokasiData.isEmpty) {
      return _buildEmpty(
        icon: Icons.location_off_outlined,
        message: 'Belum ada siswa yang menginput lokasi PKL.',
      );
    }

    return Column(
      children: _lokasiData.asMap().entries.map((entry) {
        final index = entry.key;
        final lokasi = entry.value;
        final progresCount = _progresBySiswaId[lokasi.siswaId]?.length ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(isDark),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoBox(lokasi.fotoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${lokasi.namaSiswa}',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lokasi.namaPerusahaan,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posisi: ${lokasi.posisi}',
                      style: _subTextStyle(isDark),
                    ),
                    Text(
                      'Pembimbing: ${lokasi.pembimbingIndustri}',
                      style: _subTextStyle(isDark),
                    ),
                    Text(
                      'Mulai: ${_formatDate(lokasi.tanggal)}',
                      style: _subTextStyle(isDark),
                    ),
                    const SizedBox(height: 6),
                    _StatusBadge(
                      text: progresCount > 0
                          ? '$progresCount Laporan Progres'
                          : 'Belum Ada Laporan',
                      color: progresCount > 0
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgresTab(bool isDark) {
    if (_progresData.isEmpty) {
      return _buildEmpty(
        icon: Icons.timeline_outlined,
        message: 'Belum ada laporan progres dari kelas ini.',
      );
    }

    return Column(
      children: _progresData.asMap().entries.map((entry) {
        final index = entry.key;
        final progres = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(isDark),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                child: Text(
                  '${progres.mingguKe}',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${progres.namaSiswa}',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Minggu ke-${progres.mingguKe}',
                      style: _subTextStyle(isDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      progres.deskripsi,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNilaiTab(bool isDark) {
    if (_siswaList.isEmpty) {
      return _buildEmpty(
        icon: Icons.grade_outlined,
        message: 'Belum ada data siswa.',
      );
    }

    return Column(
      children: _siswaList.asMap().entries.map((entry) {
        final index = entry.key;
        final siswa = entry.value;
        final nilai = _nilaiForSiswa(siswa);
        final akhir = _hitungAkhir(nilai);
        final tuntas = akhir != null && akhir >= 75;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(isDark).copyWith(
            border: Border(
              left: BorderSide(
                color: nilai?.sudahDiinput == true
                    ? (tuntas ? const Color(0xFF16A34A) : const Color(0xFFDC2626))
                    : Colors.grey,
                width: 4,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.purple.withOpacity(0.12),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StudentTitle(
                      nama: siswa.nama,
                      nisn: siswa.nisn,
                      isDark: isDark,
                    ),
                  ),
                  _StatusBadge(
                    text: nilai?.sudahDiinput == true
                        ? (tuntas ? 'Tuntas' : 'Belum Tuntas')
                        : 'Belum Dinilai',
                    color: nilai?.sudahDiinput == true
                        ? (tuntas ? const Color(0xFF16A34A) : const Color(0xFFDC2626))
                        : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniScore(label: 'Praktik', value: _formatNumber(nilai?.praktik)),
                  _MiniScore(label: 'Sikap', value: _formatNumber(nilai?.sikap)),
                  _MiniScore(label: 'Laporan', value: _formatNumber(nilai?.laporan)),
                  _MiniScore(label: 'Akhir', value: _formatNumber(akhir)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoBox(String? fotoUrl) {
    final url = _fullPhotoUrl(fotoUrl);

    if (url.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.photo_camera_outlined, color: Colors.grey),
      );
    }

    return InkWell(
      onTap: () => _showPhotoPreview(fotoUrl),
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 56,
              height: 56,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined),
            );
          },
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isDark ? Colors.white10 : Colors.grey.shade200,
      ),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
      ],
    );
  }

  TextStyle _subTextStyle(bool isDark) {
    return TextStyle(
      color: isDark ? Colors.white60 : Colors.grey.shade600,
      fontSize: 12,
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 8),
        Text(
          _error ?? 'Terjadi kesalahan',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loadDataPkl,
          child: const Text('Coba Lagi'),
        ),
      ],
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Icon(icon, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final String keyName;
  final String label;
  final IconData icon;
  final int count;

  const _TabItem({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.count,
  });
}

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _SummaryBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTitle extends StatelessWidget {
  final String nama;
  final String nisn;
  final bool isDark;

  const _StudentTitle({
    required this.nama,
    required this.nisn,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nama,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'NISN: $nisn',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  final String label;
  final String value;
  final bool success;

  const _MiniStatus({
    required this.label,
    required this.value,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      width: 102,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  final String label;
  final String value;

  const _MiniScore({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '-';
    final color = isEmpty ? Colors.grey : const Color(0xFF2563EB);

    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}