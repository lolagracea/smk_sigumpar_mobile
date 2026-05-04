# 🏫 Sistem Informasi SMK Negeri 1 Sigumpar

Aplikasi mobile Flutter untuk Sistem Informasi SMK Negeri 1 Sigumpar.

---

## 🗂 Arsitektur Proyek

```
lib/
├── core/                    # Inti (konstan, DI, network, router, theme, utils)
├── data/                    # Layer Data (models, repositories, services)
├── domain/                  # Business Logic / Use Cases (opsional)
├── presentation/            # UI & State Management
│   ├── common/              # Widgets & Providers global
│   └── features/            # Fitur per modul
│       ├── auth/
│       ├── home/
│       ├── academic/
│       ├── student/
│       ├── learning/
│       ├── vocational/
│       └── asset/
├── app.dart
└── main.dart
```

---

## ⚙️ Setup & Instalasi

### 1. Prasyarat
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio / VS Code

### 2. Clone & Install Dependencies
```bash
git clone <repo-url>
cd smk_sigumpar
flutter pub get
```

### 3. Konfigurasi Base URL API
Edit file `lib/core/constants/api_endpoints.dart`:
```dart
static const String baseUrl = 'https://api.smkn1sigumpar.sch.id/api/v1';
```

### 4. Jalankan Aplikasi
```bash
flutter run
```

---

## 👥 Role Pengguna

| Role | Kode | Akses |
|------|------|-------|
| Administrator | `admin` | Semua fitur |
| Kepala Sekolah | `principal` | Akademik, Pembelajaran, Aset |
| Wakil Kepala Sekolah | `vice_principal` | Akademik, Pembelajaran |
| Guru | `teacher` | Pembelajaran, Absensi |
| Wali Kelas | `homeroom` | Kesiswaan, Absensi |
| Siswa | `student` | Nilai, Kehadiran, PKL |
| Staf TU | `staff` | Akademik, Aset |
| Bendahara | `treasurer` | Aset |

---

## 📦 Paket yang Digunakan

| Paket | Kegunaan |
|-------|----------|
| `go_router` | Navigasi deklaratif |
| `provider` | State management |
| `dio` | HTTP client |
| `flutter_secure_storage` | Simpan token JWT |
| `get_it` | Dependency injection |
| `google_fonts` | Tipografi (Plus Jakarta Sans) |
| `file_picker` | Upload file |
| `intl` | Internasionalisasi / format tanggal |
| `equatable` | Komparasi objek |
| `shimmer` | Loading skeleton |

---

## 🌐 Format API Response

Semua endpoint diharapkan mengikuti format:

### Single Object
```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": { ... }
}
```

### Paginated List
```json
{
  "success": true,
  "data": {
    "data": [ ... ],
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 75
  }
}
```

### Error
```json
{
  "success": false,
  "message": "Pesan error",
  "errors": ["Detail error 1", "Detail error 2"]
}
```

---

## 🔐 Autentikasi

Menggunakan JWT Bearer Token. Flow:
1. `POST /auth/login` → dapat `access_token` + `refresh_token`
2. Token disimpan di `flutter_secure_storage`
3. Setiap request inject `Authorization: Bearer <token>` via Dio Interceptor
4. Jika 401 → auto refresh token → retry request
5. Jika refresh gagal → redirect ke login

---

## 📁 Cara Menambah Fitur Baru

1. Buat **model** di `lib/data/models/`
2. Tambah method di **repository** (abstract) di `lib/data/repositories/`
3. Implementasi di **service** (Dio call) di `lib/data/services/`
4. Register di **injection_container.dart**
5. Buat **provider** di `lib/presentation/features/<fitur>/providers/`
6. Buat **screen** di `lib/presentation/features/<fitur>/screens/`
7. Daftarkan **route** di `lib/core/router/app_router.dart`
8. Tambah **route name** di `lib/core/constants/route_names.dart`

---

## 🧑‍💻 Tim Pengembang

**SMK Negeri 1 Sigumpar**  
Jl. Sisingamangaraja, Sigumpar, Toba, Sumatera Utara
