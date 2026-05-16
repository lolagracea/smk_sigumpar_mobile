import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_names.dart';

// ─── Warna persis dari CSS :root LandingPage ─────────────────────────────────
const Color _biruToba  = Color(0xFF0B4F6C);
const Color _tealToba  = Color(0xFF0E7490);
const Color _navyToba  = Color(0xFF06364F);
const Color _kabutToba = Color(0xFFE4F4F8);
const Color _riakToba  = Color(0xFFB8E0EA);
const Color _bgPage    = Color(0xFFF8FAFC);


// ─── Data Berita (sama persis dengan BERITA_DATA di LandingPage.jsx) ─────────
class _BeritaItem {
  final int id;
  final String judul;
  final String tanggal;
  final String isi;
  final String tipe;
  final String src;
  final String? poster;

  const _BeritaItem({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.isi,
    required this.tipe,
    required this.src,
    this.poster,
  });
}

const List<_BeritaItem> _beritaData = [
  _BeritaItem(
    id: 1,
    judul: 'Kegiatan Praktik Pelajaran yang dilakukan Siswa ATPH',
    tanggal: '12 Mei 2026',
    isi: 'Siswa berpartisipasi aktif dalam mengikuti kegiatan belajar diluar kelas.',
    tipe: 'gambar',
    src: '/berita/1.jpeg',
  ),
  _BeritaItem(
    id: 2,
    judul: 'Pengelolaan Lingkungan Dalam Proses Pelajaran di Sekolah',
    tanggal: '10 Mei 2026',
    isi: 'Siswa SMK Negeri 1 Sigumpar memanfaatkan lingkungan sekolah dalam praktik mata pelajaran yang diikuti.',
    tipe: 'gambar',
    src: '/berita/2.jpeg',
  ),
  _BeritaItem(
    id: 3,
    judul: 'Pengujian Rangkaian Listrik Pada Mata Pelajaran SMK Negeri 1 Sigumpar',
    tanggal: '8 Mei 2026',
    isi: 'Siswa jurusan Teknik Instalasi Tenaga Listrik SMA Negeri 1 Sigumpar melakukan pengujian praktik rangkaian listrik.',
    tipe: 'gambar',
    src: '/berita/3.jpeg',
  ),
  _BeritaItem(
    id: 4,
    judul: 'Praktik Agrobisnis Tanaman Pangan dan Hortikultura pada Luar Kelas',
    tanggal: '5 Mei 2026',
    isi: 'Para siswa jurusan ATPH melakukan praktik pada jenis-jenis zat pangan diluar kelas.',
    tipe: 'gambar',
    src: '/berita/4.jpeg',
  ),
  _BeritaItem(
    id: 5,
    judul: 'Dokumentasi Kegiatan Praktikum Siswa TITL',
    tanggal: '2 Mei 2026',
    isi: 'Video dokumentasi pengujian praktik rangkaian listrik oleh siswa jurusan Teknik Instalasi Tenaga Listrik.',
    tipe: 'video',
    src: '/berita/video1.mp4',
    poster: '/berita/5.jpeg',
  ),
  _BeritaItem(
    id: 6,
    judul: 'Siswa TITL Praktik Rangkaian Listrik',
    tanggal: '28 Apr 2026',
    isi: 'Siswa jurusan TITL mendapat pelatihan praktik rangkaian listrik.',
    tipe: 'gambar',
    src: '/berita/6.jpeg',
  ),
  _BeritaItem(
    id: 7,
    judul: 'Kegiatan Praktik Mesin Otomotif yang dilakukan Siswa TBSM',
    tanggal: '25 Apr 2026',
    isi: 'Praktikum yang dilakukan siswa jurusan Teknik dan Bisnis Sepeda Motor dalam otomotif mesin.',
    tipe: 'video',
    src: '/berita/video2.mp4',
    poster: '/berita/7.jpeg',
  ),
  _BeritaItem(
    id: 8,
    judul: 'Praktikum Pelajaran Otomotif Motor SMA Negeri 1 Sigumpar',
    tanggal: '20 Apr 2026',
    isi: 'Dilakukannya praktikum oleh siswa jurusan TBSM.',
    tipe: 'gambar',
    src: '/berita/8.jpeg',
  ),
];

// ════════════════════════════════════════════════════════════════════════════
//  LANDING PAGE SCREEN
// ════════════════════════════════════════════════════════════════════════════
class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _scrolled    = false;
  bool _menuOpen    = false;
  String _activeSection = 'beranda';
  _BeritaItem? _selectedBerita;

  final _keyBeranda = GlobalKey();
  final _keyProfil  = GlobalKey();
  final _keyJurusan = GlobalKey();
  final _keyBerita  = GlobalKey();
  final _keyKontak  = GlobalKey();

  static const _navItems = [
    {'label': 'Beranda',       'id': 'beranda'},
    {'label': 'Profil Sekolah','id': 'profil'},
    {'label': 'Jurusan',       'id': 'jurusan'},
    {'label': 'Berita',        'id': 'berita'},
    {'label': 'Kontak',        'id': 'kontak'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final y = _scrollController.offset;
    if (y > 20 && !_scrolled) setState(() => _scrolled = true);
    if (y <= 20 && _scrolled) setState(() => _scrolled = false);
    _detectActiveSection();
  }

  void _detectActiveSection() {
    final sections = {
      'beranda': _keyBeranda,
      'profil' : _keyProfil,
      'jurusan': _keyJurusan,
      'berita' : _keyBerita,
      'kontak' : _keyKontak,
    };
    for (final entry in sections.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      if (pos.dy <= 150 && pos.dy + box.size.height >= 150) {
        if (_activeSection != entry.key) {
          setState(() => _activeSection = entry.key);
        }
        break;
      }
    }
  }

  void _scrollToSection(String id) {
    final keyMap = {
      'beranda': _keyBeranda,
      'profil' : _keyProfil,
      'jurusan': _keyJurusan,
      'berita' : _keyBerita,
      'kontak' : _keyKontak,
    };
    final ctx = keyMap[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 72),
                _buildBeranda(),
                _buildProfil(),
                _buildJurusan(),
                _buildBerita(),
                _buildKontak(),
              ],
            ),
          ),
          _buildNavbar(),
          if (_menuOpen) _buildMobileMenu(),
          if (_selectedBerita != null) _buildBeritaModal(_selectedBerita!),
        ],
      ),
    );
  }

  // ── NAVBAR ─────────────────────────────────────────────────────────────────
  Widget _buildNavbar() {
    final isWide = MediaQuery.of(context).size.width > 992;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _scrolled ? 64 : 72,
      decoration: BoxDecoration(
        color: _scrolled ? Color.fromRGBO(11,79,108,0.95) : _biruToba,
        boxShadow: _scrolled
            ? [BoxShadow(color: Color.fromRGBO(0,0,0,0.15), blurRadius: 20, offset: const Offset(0, 4))]
            : [],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
        child: Row(
          children: [
            // Brand
            GestureDetector(
              onTap: () => _scrollToSection('beranda'),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Color.fromRGBO(0,0,0,0.1), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Center(
                      child: Text(
                        'SMK\nN1',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _biruToba, height: 1.1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'SMK NEGERI 1 SIGUMPAR',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Desktop links
            if (isWide) ...[
              Row(
                children: _navItems.map((item) {
                  final isActive = _activeSection == item['id'];
                  return GestureDetector(
                    onTap: () => _scrollToSection(item['id']!),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? Color.fromRGBO(255,255,255,0.18) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['label']!,
                        style: TextStyle(
                          color: isActive ? Colors.white : Color.fromRGBO(255,255,255,0.85),
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 24),
              _loginButton(),
            ] else ...[
              // Hamburger
              GestureDetector(
                onTap: () => setState(() => _menuOpen = !_menuOpen),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _hamburgerLine(
                        transform: _menuOpen
                            ? (Matrix4.rotationZ(0.785)..translateByDouble(0, 7, 0, 0))
                            : Matrix4.identity(),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _menuOpen ? 0 : 1,
                        child: _hamburgerLine(),
                      ),
                      _hamburgerLine(
                        transform: _menuOpen
                            ? (Matrix4.rotationZ(-0.785)..translateByDouble(0, -7, 0, 0))
                            : Matrix4.identity(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hamburgerLine({Matrix4? transform}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      width: 24,
      height: 2,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
      transform: transform,
    );
  }

  Widget _loginButton() {
    return GestureDetector(
      onTap: () => context.go(RouteNames.login),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Color.fromRGBO(0,0,0,0.1), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: const Text('Login Portal', style: TextStyle(color: _biruToba, fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ── MOBILE MENU ────────────────────────────────────────────────────────────
  Widget _buildMobileMenu() {
    return Positioned(
      top: _scrolled ? 64 : 72,
      left: 0,
      right: 0,
      child: Container(
        color: _navyToba,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._navItems.map((item) {
              final isActive = _activeSection == item['id'];
              return GestureDetector(
                onTap: () { _scrollToSection(item['id']!); setState(() => _menuOpen = false); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? Color.fromRGBO(255,255,255,0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['label']!,
                    style: TextStyle(
                      color: isActive ? Colors.white : Color.fromRGBO(255,255,255,0.85),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () { setState(() => _menuOpen = false); context.go(RouteNames.login); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Center(
                  child: Text('Login Portal', style: TextStyle(color: _biruToba, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BERANDA ────────────────────────────────────────────────────────────────
  Widget _buildBeranda() {
    final isWide = MediaQuery.of(context).size.width > 768;
    return Container(
      key: _keyBeranda,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1FAFD), _kabutToba],
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, isWide ? 100 : 60, 24, 100),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _berandaText()),
                const SizedBox(width: 60),
                Expanded(child: _berandaImage()),
              ],
            )
          : Column(
              children: [
                _berandaImage(),
                const SizedBox(height: 32),
                _berandaText(centered: true),
              ],
            ),
    );
  }

  Widget _berandaText({bool centered = false}) {
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Mencetak Lulusan Unggul & Berdaya Saing Global',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _navyToba, height: 1.2),
        ),
        const SizedBox(height: 20),
        Text(
          'SMK Negeri 1 Sigumpar berkomitmen tinggi menghasilkan lulusan yang kompeten, berkarakter, dan siap beradaptasi di era transformasi industri digital maupun melanjutkan pendidikan ke jenjang yang lebih tinggi dengan modal keahlian praktis teruji.',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(fontSize: 16, color: Color(0xFF4A5568), height: 1.8),
        ),
      ],
    );
  }

  Widget _berandaImage() {
    return Container(
      decoration: BoxDecoration(
        color: _kabutToba,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Color.fromRGBO(6,54,79,0.12), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.asset(
        'assets/images/foto-sekolah.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 280,
          color: _kabutToba,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_rounded, size: 64, color: _biruToba),
                SizedBox(height: 12),
                Text('SMK Negeri 1 Sigumpar', style: TextStyle(color: _biruToba, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── PROFIL ─────────────────────────────────────────────────────────────────
  Widget _buildProfil() {
    final isWide = MediaQuery.of(context).size.width > 768;
    return Container(
      key: _keyProfil,
      color: _navyToba,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: _profilKepala()),
                const SizedBox(width: 60),
                Expanded(child: _profilContent()),
              ],
            )
          : Column(
              children: [_profilKepala(), const SizedBox(height: 32), _profilContent()],
            ),
    );
  }

  Widget _profilKepala() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Color.fromRGBO(255,255,255,0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color.fromRGBO(255,255,255,0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_tealToba, _biruToba],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Color.fromRGBO(255,255,255,0.15), width: 4),
              boxShadow: [BoxShadow(color: Color.fromRGBO(0,0,0,0.2), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.person_rounded, size: 64, color: Colors.white60),
          ),
          const SizedBox(height: 20),
          const Text('Anny Sijayung, S.Pd, M.Pd',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Kepala Sekolah',
              style: TextStyle(color: _riakToba, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text('anny.sijayung@gmail.com',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _profilContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Visi & Misi Sekolah',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 24),
        // Visi
        Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Color.fromRGBO(255,255,255,0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color.fromRGBO(255,255,255,0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Visi',
                  style: TextStyle(color: Color(0xFF7DD4E4), fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Text(
                'Menjadi Sekolah Menengah Kejuruan yang unggul, berkarakter, dan berdaya saing global dalam menghasilkan lulusan yang kompeten, profesional, serta siap kerja, siap melanjutkan pendidikan, dan siap berwirausaha.',
                style: TextStyle(fontSize: 15, color: Color.fromRGBO(255,255,255,0.9), height: 1.8),
              ),
            ],
          ),
        ),
        // Misi
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Color.fromRGBO(255,255,255,0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color.fromRGBO(255,255,255,0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Misi',
                  style: TextStyle(color: Color(0xFF7DD4E4), fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ...[
                'Menyelenggarakan pendidikan dan pelatihan berbasis kompetensi sesuai kebutuhan dunia usaha dan dunia Industri (DUDI).',
                'Mengembangkan pembelajaran yang inovatif, kreatif, dan berbasis teknologi terkini.',
                'Meningkatkan kualitas tata kelola kelembagaan dan sumber daya pendidik yang profesional.',
              ].asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e.key + 1}. ',
                            style: TextStyle(fontSize: 15, color: Color.fromRGBO(255,255,255,0.9), height: 1.8, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Text(e.value,
                              style: TextStyle(fontSize: 15, color: Color.fromRGBO(255,255,255,0.9), height: 1.8)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ── JURUSAN ────────────────────────────────────────────────────────────────
  Widget _buildJurusan() {
    final isWide = MediaQuery.of(context).size.width > 992;
    final jurusanList = [
      {
        'nama': 'Teknik Instalasi Tenaga Listrik (TITL)',
        'deskripsi': 'Mempelajari perencanaan, pemasangan, hingga pemeliharaan instalasi listrik domestik dan industrial. Siswa dibekali keahlian sistem kontrol kelistrikan mekanis maupun digital dengan standar K3 ketat.',
        'asset': 'assets/images/foto-titl.png',
        'icon': Icons.electrical_services_rounded,
      },
      {
        'nama': 'Agribisnis Tanaman Pangan & Hortikultura (ATPH)',
        'deskripsi': 'Fokus pada pembudidayaan tanaman bernilai ekonomi tinggi menggunakan teknik modern, hidroponik, mekanisasi pertanian, serta pengolahan agribisnis hulu ke hilir yang ramah lingkungan.',
        'asset': 'assets/images/foto-atph.png',
        'icon': Icons.eco_rounded,
      },
      {
        'nama': 'Teknik & Bisnis Sepeda Motor (TBSM)',
        'deskripsi': 'Mengulas tuntas teknologi perawatan mesin roda dua, diagnosis sistem injeksi elektronik komputerisasi, serta strategi pengelolaan manajemen operasional bisnis bengkel otomotif mandiri.',
        'asset': 'assets/images/foto-tbsm.png',
        'icon': Icons.two_wheeler_rounded,
      },
    ];

    return Container(
      key: _keyJurusan,
      color: const Color(0xFFF1FAFD),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Column(
        children: [
          _sectionTitle('Kompetensi Keahlian'),
          const SizedBox(height: 48),
          if (isWide) ...[
            Row(
              children: [
                Expanded(child: _jurusanCard(jurusanList[0], isWide: true)),
                const SizedBox(width: 32),
                Expanded(child: _jurusanCard(jurusanList[1], isWide: true)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 2 - 8,
              child: _jurusanCard(jurusanList[2], isWide: true),
            ),
          ] else ...[
            _jurusanCard(jurusanList[0], isWide: false),
            const SizedBox(height: 24),
            _jurusanCard(jurusanList[1], isWide: false),
            const SizedBox(height: 24),
            _jurusanCard(jurusanList[2], isWide: false),
          ],
        ],
      ),
    );
  }

  Widget _jurusanCard(Map<String, dynamic> item, {required bool isWide}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Color.fromRGBO(0,0,0,0.04), blurRadius: 30, offset: const Offset(0, 10))],
        border: Border.all(color: Color.fromRGBO(14,116,144,0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE4F4F8), Colors.white]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0x1A0E7490))),
            ),
            child: Text(item['nama'] as String,
                style: const TextStyle(fontWeight: FontWeight.w700, color: _navyToba, fontSize: 16)),
          ),
          if (isWide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 180,
                    child: ClipRRect(
                      child: Image.asset(
                        item['asset'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _kabutToba,
                          child: Center(child: Icon(item['icon'] as IconData, size: 48, color: _biruToba)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(item['deskripsi'] as String,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568), height: 1.7)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.asset(
                    item['asset'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _kabutToba,
                      child: Center(child: Icon(item['icon'] as IconData, size: 48, color: _biruToba)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(item['deskripsi'] as String,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568), height: 1.7)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── BERITA ─────────────────────────────────────────────────────────────────
  Widget _buildBerita() {
    final isWide = MediaQuery.of(context).size.width > 768;
    return Container(
      key: _keyBerita,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Column(
        children: [
          _sectionTitle('Kabar & Kegiatan Sekolah'),
          const SizedBox(height: 48),
          if (isWide) _beritaGrid() else _beritaGridMobile(),
        ],
      ),
    );
  }

  Widget _beritaGrid() {
    final List<Widget> rows = [];
    for (int i = 0; i < _beritaData.length; i += 2) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _beritaCard(_beritaData[i])),
          const SizedBox(width: 24),
          if (i + 1 < _beritaData.length)
            Expanded(child: _beritaCard(_beritaData[i + 1]))
          else
            const Expanded(child: SizedBox()),
        ],
      ));
      if (i + 2 < _beritaData.length) rows.add(const SizedBox(height: 24));
    }
    return Column(children: rows);
  }

  Widget _beritaGridMobile() {
    return Column(
      children: _beritaData
          .map((item) => Padding(padding: const EdgeInsets.only(bottom: 24), child: _beritaCard(item)))
          .toList(),
    );
  }

  Widget _beritaCard(_BeritaItem item) {
    return GestureDetector(
      onTap: () => setState(() => _selectedBerita = item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      item.tipe == 'video' ? (item.poster ?? item.src) : item.src,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _kabutToba,
                        child: const Center(child: Icon(Icons.image_rounded, size: 48, color: _biruToba)),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: _kabutToba,
                          child: const Center(child: CircularProgressIndicator(color: _biruToba, strokeWidth: 2)),
                        );
                      },
                    ),
                    if (item.tipe == 'video') ...[
                      Container(color: Color.fromRGBO(6,54,79,0.25)),
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(255,255,255,0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Color.fromRGBO(0,0,0,0.2), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: _biruToba, size: 28),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(11,79,108,0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 10, color: Colors.white),
                              SizedBox(width: 4),
                              Text('VIDEO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.tanggal, style: const TextStyle(fontSize: 11, color: Color(0xFFA0AEC0))),
                  const SizedBox(height: 6),
                  Text(item.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _navyToba, height: 1.5)),
                  const SizedBox(height: 8),
                  Text(item.isi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF718096), height: 1.6)),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Text('Selengkapnya',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _tealToba)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: _tealToba),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── KONTAK ─────────────────────────────────────────────────────────────────
  Widget _buildKontak() {
    final isWide = MediaQuery.of(context).size.width > 768;
    return Container(
      key: _keyKontak,
      color: _navyToba,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 60),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _kontakInfo()),
                      const SizedBox(width: 40),
                      Expanded(child: _kontakMap()),
                    ],
                  )
                : Column(children: [_kontakInfo(), const SizedBox(height: 32), _kontakMap()]),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Color.fromRGBO(255,255,255,0.1))),
              color: Color.fromRGBO(0,0,0,0.2),
            ),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                '© ${DateTime.now().year} SMK Negeri 1 Sigumpar. All Rights Reserved.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kontakInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hubungi Kami',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF7DD4E4))),
        const SizedBox(height: 24),
        _kontakItem(Icons.location_on_rounded, 'Jl. Sipungguk No. 1, Sigumpar, Kab. Toba, Sumatera Utara'),
        const SizedBox(height: 20),
        _kontakItem(Icons.phone_rounded, '(0632) 21234'),
        const SizedBox(height: 20),
        _kontakItem(Icons.email_rounded, 'smkn1sigumpar@gmail.com'),
      ],
    );
  }

  Widget _kontakItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color.fromRGBO(255,255,255,0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.white70),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text,
              // Colors.white85 tidak ada di Flutter → pakai Color langsung
              style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 15)),
        ),
      ],
    );
  }

  Widget _kontakMap() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Color.fromRGBO(255,255,255,0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.fromRGBO(255,255,255,0.1)),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            '[ Google Maps Location SMKN 1 Sigumpar ]',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ),
      ),
    );
  }

  // ── MODAL BERITA ───────────────────────────────────────────────────────────
  Widget _buildBeritaModal(_BeritaItem item) {
    return GestureDetector(
      onTap: () => setState(() => _selectedBerita = null),
      child: Container(
        color: Color.fromRGBO(6,54,79,0.75),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 680),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Color.fromRGBO(0,0,0,0.3), blurRadius: 64, offset: const Offset(0, 32))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: item.tipe == 'video'
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  item.poster ?? item.src,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: _kabutToba),
                                ),
                                const Center(child: Icon(Icons.play_circle_rounded, size: 72, color: Colors.white70)),
                              ],
                            )
                          : Image.network(
                              item.src,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: _kabutToba,
                                child: const Center(child: Icon(Icons.image_rounded, size: 64, color: _biruToba)),
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.tanggal, style: const TextStyle(fontSize: 12, color: Color(0xFFA0AEC0))),
                        const SizedBox(height: 8),
                        Text(item.judul,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _navyToba, height: 1.3)),
                        const SizedBox(height: 16),
                        Text(item.isi,
                            style: const TextStyle(fontSize: 15, color: Color(0xFF4A5568), height: 1.8)),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => setState(() => _selectedBerita = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                            decoration: BoxDecoration(color: _biruToba, borderRadius: BorderRadius.circular(10)),
                            child: const Text('Tutup',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── HELPER section title ───────────────────────────────────────────────────
  Widget _sectionTitle(String text) {
    return Column(
      children: [
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _navyToba)),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(color: _tealToba, borderRadius: BorderRadius.circular(2)),
        ),
      ],
    );
  }
}