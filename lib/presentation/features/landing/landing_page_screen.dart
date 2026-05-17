// lib/presentation/features/landing/landing_page_screen.dart
//
// Landing Page SMK Negeri 1 Sigumpar
// Identik dengan LandingPage.jsx di web microservice.
//
// Seksi : Navbar | Beranda | Profil | Jurusan | Berita | Kontak & Footer
// Warna : --biru-toba #0B4F6C | --teal-toba #0E7490 | --navy-toba #06364F
//         --kabut-toba #E4F4F8 | --riak-toba #B8E0EA

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';

// ── Warna brand identik dengan CSS vars di LandingPage.jsx ──────────────────
const _kBiruToba  = Color(0xFF0B4F6C);
const _kTealToba  = Color(0xFF0E7490);
const _kNavyToba  = Color(0xFF06364F);
const _kKabutToba = Color(0xFFE4F4F8);
const _kRiakToba  = Color(0xFFB8E0EA);

// ── Data berita — identik dengan BERITA_DATA di LandingPage.jsx ─────────────
class _BeritaItem {
  final int id;
  final String judul;
  final String tanggal;
  final String isi;
  final bool isVideo;

  const _BeritaItem({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.isi,
    this.isVideo = false,
  });
}

const _kBeritaData = [
  _BeritaItem(
    id: 1,
    judul: 'Kegiatan Praktik Pelajaran yang dilakukan Siswa ATPH',
    tanggal: '12 Mei 2026',
    isi: 'Siswa berpartisipasi aktif dalam mengikuti kegiatan belajar diluar kelas.',
  ),
  _BeritaItem(
    id: 2,
    judul: 'Pengelolaan Lingkungan Dalam Proses Pelajaran di Sekolah',
    tanggal: '10 Mei 2026',
    isi: 'Siswa SMK Negeri 1 Sigumpar memanfaatkan lingkungan sekolah dalam praktik mata pelajaran yang diikuti.',
  ),
  _BeritaItem(
    id: 3,
    judul: 'Pengujian Rangkaian Listrik Pada Mata Pelajaran SMK Negeri 1 Sigumpar',
    tanggal: '8 Mei 2026',
    isi: 'Siswa jurusan Teknik Instalasi Tenaga Listrik SMA Negeri 1 Sigumpar melakukan pengujian praktik rangkaian listrik.',
  ),
  _BeritaItem(
    id: 4,
    judul: 'Praktik Agrobisnis Tanaman Pangan dan Hortikultura pada Luar Kelas',
    tanggal: '5 Mei 2026',
    isi: 'Para siswa jurusan ATPH melakukan praktik pada jenis-jenis zat pangan diluar kelas.',
  ),
  _BeritaItem(
    id: 5,
    judul: 'Dokumentasi Kegiatan Praktikum Siswa TITL',
    tanggal: '2 Mei 2026',
    isi: 'Video dokumentasi pengujian praktik rangkaian listrik oleh siswa jurusan Teknik Instalasi Tenaga Listrik.',
    isVideo: true,
  ),
  _BeritaItem(
    id: 6,
    judul: 'Siswa TITL Praktik Rangkaian Listrik',
    tanggal: '28 Apr 2026',
    isi: 'Siswa jurusan TITL mendapat pelatihan praktik rangkaian listrik.',
  ),
  _BeritaItem(
    id: 7,
    judul: 'Kegiatan Praktik Mesin Otomotif yang dilakukan Siswa TBSM',
    tanggal: '25 Apr 2026',
    isi: 'Praktikum yang dilakukan siswa jurusan Teknik dan Bisnis Sepeda Motor dalam otomotif mesin.',
    isVideo: true,
  ),
  _BeritaItem(
    id: 8,
    judul: 'Praktikum Pelajaran Otomotif Motor SMA Negeri 1 Sigumpar',
    tanggal: '20 Apr 2026',
    isi: 'Dilakukannya praktikum oleh siswa jurusan TBSM.',
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
// SCREEN UTAMA
// ═════════════════════════════════════════════════════════════════════════════
class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {
    'beranda': GlobalKey(),
    'profil':  GlobalKey(),
    'jurusan': GlobalKey(),
    'berita':  GlobalKey(),
    'kontak':  GlobalKey(),
  };

  bool _scrolled = false;
  String _activeSection = 'beranda';
  bool _menuOpen = false;
  _BeritaItem? _selectedBerita;

  final _navItems = const [
    ('Beranda',       'beranda'),
    ('Profil Sekolah','profil'),
    ('Jurusan',       'jurusan'),
    ('Berita',        'berita'),
    ('Kontak',        'kontak'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollCtrl.offset;
    setState(() {
      _scrolled = offset > 20;
    });

    // Deteksi seksi aktif — sama seperti IntersectionObserver web
    for (final entry in _sectionKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      if (pos.dy <= 120 && pos.dy + box.size.height >= 120) {
        if (_activeSection != entry.key) {
          setState(() => _activeSection = entry.key);
        }
        break;
      }
    }
  }

  // Scroll smooth ke seksi — identik dengan scrollTo() web
  void _scrollTo(String id) {
    final ctx = _sectionKeys[id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _menuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Konten scroll ────────────────────────────────────
          CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              // Spacer untuk navbar fixed
              const SliverToBoxAdapter(child: SizedBox(height: 72)),

              // ══ BERANDA ══
              SliverToBoxAdapter(child: _buildBeranda()),

              // ══ PROFIL ══
              SliverToBoxAdapter(child: _buildProfil()),

              // ══ JURUSAN ══
              SliverToBoxAdapter(child: _buildJurusan()),

              // ══ BERITA ══
              SliverToBoxAdapter(child: _buildBerita()),

              // ══ KONTAK & FOOTER ══
              SliverToBoxAdapter(child: _buildKontak()),
            ],
          ),

          // ── Navbar fixed di atas ─────────────────────────────
          _buildNavbar(),

          // ── Dropdown menu mobile ──────────────────────────────
          if (_menuOpen) _buildMobileMenu(),

          // ── Modal detail berita ───────────────────────────────
          if (_selectedBerita != null)
            _BeritaModal(
              item: _selectedBerita!,
              onClose: () => setState(() => _selectedBerita = null),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // NAVBAR — identik dengan .lp-navbar di web
  // ════════════════════════════════════════════
  Widget _buildNavbar() {
    final isWide = MediaQuery.of(context).size.width > 992;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _scrolled ? 64 : 72,
      decoration: BoxDecoration(
        color: _scrolled
            ? _kBiruToba.withValues(alpha: 0.95)
            : _kBiruToba,
        boxShadow: _scrolled
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 4))]
            : [],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
        child: Row(
          children: [
            // Brand — logo + nama sekolah
            GestureDetector(
              onTap: () => _scrollTo('beranda'),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                    ),
                    child: const Center(
                      child: Text(
                        'SMK\nN1',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _kBiruToba,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'SMK NEGERI 1 SIGUMPAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Desktop: nav links + tombol login
            if (isWide) ...[
              Row(
                children: _navItems.map((item) {
                  final isActive = _activeSection == item.$2;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: TextButton(
                      onPressed: () => _scrollTo(item.$2),
                      style: TextButton.styleFrom(
                        backgroundColor: isActive
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        item.$1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 16),
              _LoginButton(onTap: () => context.go(RouteNames.login)),
            ]
            // Mobile: hamburger
            else
              _HamburgerButton(
                isOpen: _menuOpen,
                onTap: () => setState(() => _menuOpen = !_menuOpen),
              ),
          ],
        ),
      ),
    );
  }

  // Menu mobile dropdown — identik dengan .lp-nav-links.open di web
  Widget _buildMobileMenu() {
    return Positioned(
      top: _scrolled ? 64 : 72,
      left: 0,
      right: 0,
      child: Material(
        color: _kNavyToba,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._navItems.map((item) {
                final isActive = _activeSection == item.$2;
                return TextButton(
                  onPressed: () => _scrollTo(item.$2),
                  style: TextButton.styleFrom(
                    backgroundColor: isActive
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                    foregroundColor: Colors.white,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    item.$1,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              _LoginButton(
                onTap: () { setState(() => _menuOpen = false); context.go(RouteNames.login); },
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // BERANDA — identik dengan #beranda section
  // ════════════════════════════════════════════
  Widget _buildBeranda() {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Container(
      key: _sectionKeys['beranda'],
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1FAFD), _kKabutToba],
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, isWide ? 100 : 60, 24, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
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
                    _berandaText(center: true),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _berandaText({bool center = false}) {
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Mencetak Lulusan Unggul & Berdaya Saing Global',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: center ? 28 : 38,
            fontWeight: FontWeight.w800,
            color: _kNavyToba,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'SMK Negeri 1 Sigumpar berkomitmen tinggi menghasilkan lulusan yang kompeten, berkarakter, dan siap beradaptasi di era transformasi industri digital maupun melanjutkan pendidikan ke jenjang yang lebih tinggi dengan modal keahlian praktis teruji.',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4A5568),
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _berandaImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _kNavyToba.withValues(alpha: 0.12), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      clipBehavior: Clip.antiAlias,
      child: _SchoolImagePlaceholder(
        label: 'Foto Sekolah SMK Negeri 1 Sigumpar',
        height: 340,
        icon: Icons.school_outlined,
      ),
    );
  }

  // ════════════════════════════════════════════
  // PROFIL — identik dengan #profil section
  // ════════════════════════════════════════════
  Widget _buildProfil() {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Container(
      key: _sectionKeys['profil'],
      color: _kNavyToba,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
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
                  children: [
                    _profilKepala(),
                    const SizedBox(height: 32),
                    _profilContent(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _profilKepala() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Foto placeholder — avatar icon seperti web (svg person)
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kTealToba, _kBiruToba],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 4),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.person_outline_rounded, size: 64, color: Colors.white60),
          ),
          const SizedBox(height: 20),
          const Text(
            'Anny Sijayung, S.Pd, M.Pd',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kepala Sekolah',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kRiakToba),
          ),
          const SizedBox(height: 4),
          const Text(
            'anny.sijayung@gmail.com',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _profilContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visi & Misi Sekolah',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 24),
        // Visi
        _ProfilBox(
          judul: 'Visi',
          child: const Text(
            'Menjadi Sekolah Menengah Kejuruan yang unggul, berkarakter, dan berdaya saing global dalam menghasilkan lulusan yang kompeten, profesional, serta siap kerja, siap melanjutkan pendidikan, dan siap berwirausaha.',
            style: TextStyle(fontSize: 15, color: Color(0xE6FFFFFF), height: 1.8),
          ),
        ),
        const SizedBox(height: 24),
        // Misi
        _ProfilBox(
          judul: 'Misi',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _MisiItem(nomor: '1', teks: 'Menyelenggarakan pendidikan dan pelatihan berbasis kompetensi sesuai kebutuhan dunia usaha dan dunia Industri (DUDI).'),
              SizedBox(height: 10),
              _MisiItem(nomor: '2', teks: 'Mengembangkan pembelajaran yang inovatif, kreatif, dan berbasis teknologi terkini.'),
              SizedBox(height: 10),
              _MisiItem(nomor: '3', teks: 'Meningkatkan kualitas tata kelola kelembagaan dan sumber daya pendidik yang profesional.'),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════
  // JURUSAN — identik dengan #jurusan section
  // ════════════════════════════════════════════
  Widget _buildJurusan() {
    final isWide = MediaQuery.of(context).size.width > 992;

    return Container(
      key: _sectionKeys['jurusan'],
      color: const Color(0xFFF1FAFD),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _SectionTitle(title: 'Kompetensi Keahlian'),
              const SizedBox(height: 48),
              // 2 jurusan atas
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _JurusanCard(
                      nama: 'Teknik Instalasi Tenaga Listrik (TITL)',
                      deskripsi: 'Mempelajari perencanaan, pemasangan, hingga pemeliharaan instalasi listrik domestik dan industrial. Siswa dibekali keahlian sistem kontrol kelistrikan mekanis maupun digital dengan standar K3 ketat.',
                      icon: Icons.electrical_services_outlined,
                      imageLabel: 'Foto TITL',
                    )),
                    const SizedBox(width: 32),
                    Expanded(child: _JurusanCard(
                      nama: 'Agribisnis Tanaman Pangan & Hortikultura (ATPH)',
                      deskripsi: 'Fokus pada pembudidayaan tanaman bernilai ekonomi tinggi menggunakan teknik modern, hidroponik, mekanisasi pertanian, serta pengolahan agribisnis hulu ke hilir yang ramah lingkungan.',
                      icon: Icons.eco_outlined,
                      imageLabel: 'Foto ATPH',
                    )),
                  ],
                )
              else
                Column(
                  children: [
                    _JurusanCard(
                      nama: 'Teknik Instalasi Tenaga Listrik (TITL)',
                      deskripsi: 'Mempelajari perencanaan, pemasangan, hingga pemeliharaan instalasi listrik domestik dan industrial. Siswa dibekali keahlian sistem kontrol kelistrikan mekanis maupun digital dengan standar K3 ketat.',
                      icon: Icons.electrical_services_outlined,
                      imageLabel: 'Foto TITL',
                    ),
                    const SizedBox(height: 32),
                    _JurusanCard(
                      nama: 'Agribisnis Tanaman Pangan & Hortikultura (ATPH)',
                      deskripsi: 'Fokus pada pembudidayaan tanaman bernilai ekonomi tinggi menggunakan teknik modern, hidroponik, mekanisasi pertanian, serta pengolahan agribisnis hulu ke hilir yang ramah lingkungan.',
                      icon: Icons.eco_outlined,
                      imageLabel: 'Foto ATPH',
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              // Jurusan ketiga — di tengah (jurusan-row-bottom)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide
                      ? (MediaQuery.of(context).size.width - 48) / 2
                      : double.infinity,
                ),
                child: _JurusanCard(
                  nama: 'Teknik & Bisnis Sepeda Motor (TBSM)',
                  deskripsi: 'Mengulas tuntas teknologi perawatan mesin roda dua, diagnosis sistem injeksi elektronik komputerisasi, serta strategi pengelolaan manajemen operasional bisnis bengkel otomotif mandiri.',
                  icon: Icons.two_wheeler_outlined,
                  imageLabel: 'Foto TBSM',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // BERITA — identik dengan #berita section
  // ════════════════════════════════════════════
  Widget _buildBerita() {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Container(
      key: _sectionKeys['berita'],
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _SectionTitle(title: 'Kabar & Kegiatan Sekolah'),
              const SizedBox(height: 48),
              // Grid 2 kolom (desktop) / 1 kolom (mobile)
              isWide
                  ? _buildBeritaGrid()
                  : _buildBeritaList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeritaGrid() {
    // Susun 2 kolom seperti CSS grid-template-columns: repeat(2, 1fr)
    final rows = <Widget>[];
    for (int i = 0; i < _kBeritaData.length; i += 2) {
      final left = _kBeritaData[i];
      final right = i + 1 < _kBeritaData.length ? _kBeritaData[i + 1] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _BeritaCard(item: left, onTap: () => setState(() => _selectedBerita = left))),
            const SizedBox(width: 24),
            Expanded(
              child: right != null
                  ? _BeritaCard(item: right, onTap: () => setState(() => _selectedBerita = right))
                  : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < _kBeritaData.length) rows.add(const SizedBox(height: 24));
    }
    return Column(children: rows);
  }

  Widget _buildBeritaList() {
    return Column(
      children: _kBeritaData.asMap().entries.map((e) => Padding(
        padding: EdgeInsets.only(bottom: e.key < _kBeritaData.length - 1 ? 24 : 0),
        child: _BeritaCard(
          item: e.value,
          onTap: () => setState(() => _selectedBerita = e.value),
        ),
      )).toList(),
    );
  }

  // ════════════════════════════════════════════
  // KONTAK & FOOTER — identik dengan #kontak section
  // ════════════════════════════════════════════
  Widget _buildKontak() {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Container(
      key: _sectionKeys['kontak'],
      color: _kNavyToba,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 60),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _kontakInfoSide()),
                          const SizedBox(width: 40),
                          Expanded(child: _kontakMapSide()),
                        ],
                      )
                    : Column(
                        children: [
                          _kontakInfoSide(),
                          const SizedBox(height: 32),
                          _kontakMapSide(),
                        ],
                      ),
              ),
            ),
          ),
          // Copyright bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Text(
              '© ${DateTime.now().year} SMK Negeri 1 Sigumpar. All Rights Reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kontakInfoSide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hubungi Kami',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF7DD4E4)),
        ),
        const SizedBox(height: 24),
        _KontakItem(emoji: '📍', teks: 'Jl. Sipungguk No. 1, Sigumpar, Kab. Toba, Sumatera Utara'),
        const SizedBox(height: 20),
        _KontakItem(emoji: '📞', teks: '(0632) 21234'),
        const SizedBox(height: 20),
        _KontakItem(emoji: '✉️', teks: 'smkn1sigumpar@gmail.com'),
      ],
    );
  }

  Widget _kontakMapSide() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Text(
          '[ Google Maps Location SMKN 1 Sigumpar ]',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGET HELPERS
// ═════════════════════════════════════════════════════════════════════════════

class _LoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool fullWidth;
  const _LoginButton({required this.onTap, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _kBiruToba,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          elevation: 2,
        ),
        child: const Text('Login Portal'),
      ),
    );
  }
}

class _HamburgerButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  const _HamburgerButton({required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 2,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
              transform: isOpen
                  ? ((Matrix4.translationValues(0.0, 7.0, 0.0)..rotateZ(0.785)))
                  : Matrix4.identity(),
            ),
            const SizedBox(height: 5),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isOpen ? 0 : 1,
              child: Container(width: 24, height: 2, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 2,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
              transform: isOpen
                  ? ((Matrix4.translationValues(0.0, -7.0, 0.0)..rotateZ(-0.785)))
                  : Matrix4.identity(),
            ),
          ],
        ),
      ),
    );
  }
}

// Section title dengan garis bawah teal — identik dengan .section-title::after
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: _kNavyToba,
          ),
        ),
        const SizedBox(height: 12),
        Container(width: 60, height: 4, decoration: BoxDecoration(color: _kTealToba, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }
}

// Profil box (visi / misi)
class _ProfilBox extends StatelessWidget {
  final String judul;
  final Widget child;
  const _ProfilBox({required this.judul, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7DD4E4),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MisiItem extends StatelessWidget {
  final String nomor;
  final String teks;
  const _MisiItem({required this.nomor, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$nomor. ', style: const TextStyle(fontSize: 15, color: Color(0xE6FFFFFF), height: 1.8, fontWeight: FontWeight.w600)),
        Expanded(child: Text(teks, style: const TextStyle(fontSize: 15, color: Color(0xE6FFFFFF), height: 1.8))),
      ],
    );
  }
}

// Jurusan card — identik dengan .jurusan-card
class _JurusanCard extends StatefulWidget {
  final String nama;
  final String deskripsi;
  final IconData icon;
  final String imageLabel;
  const _JurusanCard({required this.nama, required this.deskripsi, required this.icon, required this.imageLabel});

  @override
  State<_JurusanCard> createState() => _JurusanCardState();
}

class _JurusanCardState extends State<_JurusanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 992;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: _hovered
            ? (Matrix4.translationValues(0.0, -6.0, 0.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered ? _kTealToba : _kTealToba.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? _kBiruToba.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _hovered ? 36 : 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_kKabutToba, Colors.white]),
                border: Border(bottom: BorderSide(color: Color(0x1A0E7490))),
              ),
              child: Text(
                widget.nama,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kNavyToba),
              ),
            ),
            // Body — gambar + teks
            isWide
                ? SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 180,
                          child: _SchoolImagePlaceholder(
                            label: widget.imageLabel,
                            icon: widget.icon,
                            height: 160,
                            borderRadius: 0,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              widget.deskripsi,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568), height: 1.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _SchoolImagePlaceholder(label: widget.imageLabel, icon: widget.icon, height: 200, borderRadius: 0),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(widget.deskripsi, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568), height: 1.7)),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// Berita card — identik dengan .berita-card
class _BeritaCard extends StatefulWidget {
  final _BeritaItem item;
  final VoidCallback onTap;
  const _BeritaCard({required this.item, required this.onTap});

  @override
  State<_BeritaCard> createState() => _BeritaCardState();
}

class _BeritaCardState extends State<_BeritaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: _hovered
              ? (Matrix4.translationValues(0.0, -3.0, 0.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? _kTealToba : const Color(0xFFE2E8F0)),
            boxShadow: _hovered
                ? [BoxShadow(color: _kBiruToba.withValues(alpha: 0.10), blurRadius: 32, offset: const Offset(0, 12))]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail — 180px tinggi
              SizedBox(
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _SchoolImagePlaceholder(
                      label: widget.item.judul,
                      icon: widget.item.isVideo ? Icons.play_circle_outline_rounded : Icons.image_outlined,
                      height: 180,
                      borderRadius: 0,
                    ),
                    if (widget.item.isVideo) ...[
                      // Play overlay — identik dengan .berita-play-overlay
                      Container(color: _kNavyToba.withValues(alpha: 0.25)),
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16)],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: _kBiruToba, size: 24),
                        ),
                      ),
                      // Video badge — identik dengan .berita-video-badge
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kBiruToba.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Teks — identik dengan .berita-body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.tanggal,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFA0AEC0)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kNavyToba, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.item.isi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF718096), height: 1.6),
                    ),
                    const SizedBox(height: 12),
                    // "Selengkapnya →" — identik dengan .berita-readmore
                    Row(
                      children: const [
                        Text('Selengkapnya', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kTealToba)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: _kTealToba),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Kontak item
class _KontakItem extends StatelessWidget {
  final String emoji;
  final String teks;
  const _KontakItem({required this.emoji, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            teks,
            style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.85), height: 1.6),
          ),
        ),
      ],
    );
  }
}

// Placeholder gambar sekolah (karena assets belum ada)
// Saat gambar sudah tersedia, ganti dengan Image.asset(...)
class _SchoolImagePlaceholder extends StatelessWidget {
  final String label;
  final double height;
  final IconData icon;
  final double borderRadius;

  const _SchoolImagePlaceholder({
    required this.label,
    required this.height,
    required this.icon,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kKabutToba,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: _kBiruToba.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: _kBiruToba.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODAL DETAIL BERITA — identik dengan BeritaModal di web
// ═════════════════════════════════════════════════════════════════════════════
class _BeritaModal extends StatelessWidget {
  final _BeritaItem item;
  final VoidCallback onClose;
  const _BeritaModal({required this.item, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: const Color(0xFF06364F).withValues(alpha: 0.75),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // stop propagation
            child: Container(
              margin: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 64, offset: const Offset(0, 32))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Media — identik dengan bagian Media di modal web
                  SizedBox(
                    height: 280,
                    child: _SchoolImagePlaceholder(
                      label: item.judul,
                      icon: item.isVideo ? Icons.play_circle_outline_rounded : Icons.image_outlined,
                      height: 280,
                      borderRadius: 0,
                    ),
                  ),
                  // Konten
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.tanggal,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFA0AEC0)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.judul,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _kNavyToba,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.isi,
                            style: const TextStyle(fontSize: 15, color: Color(0xFF4A5568), height: 1.8),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: onClose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kBiruToba,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
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
}