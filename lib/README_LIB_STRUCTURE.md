# Flutter `lib/` Scaffold

Scaffold ini mengikuti arsitektur:
- `core/` untuk fondasi
- `data/` untuk model, remote API, repository
- `features/` per domain / role

Prioritas implementasi awal:
1. Auth + Keycloak
2. Tata Usaha (kelas, siswa, pengumuman, arsip surat)
3. Router guard berbasis role
4. Sinkronisasi model dengan backend service
