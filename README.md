# Erlangga Motor - Sistem Manajemen Bengkel

Aplikasi manajemen inventory dan penjualan untuk bengkel motor yang dibuat menggunakan Flutter. Aplikasi ini memudahkan pengelolaan stok barang, transaksi penjualan, dan laporan operasional bengkel. Aplikasi ini dibuat untuk memenuhi tugas akhir/KKP (Kerja Praktek) di Universitas Indraprasta.

## Tentang Aplikasi

Erlangga Motor adalah sistem manajemen bengkel yang dirancang untuk membantu pemilik dan karyawan bengkel dalam mengelola berbagai aspek operasional, mulai dari inventori suku cadang, transaksi penjualan, hingga pelaporan. Aplikasi ini dibangun dengan Flutter sehingga bisa berjalan di platform Android.

## Teknologi yang Digunakan

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Material Design](https://img.shields.io/badge/Material_Design_3-757575?style=for-the-badge&logo=material-design&logoColor=white)

## Cara Install

### Prasyarat

Pastikan kamu sudah install:
- Flutter SDK (versi 3.0 atau lebih baru)
- Android Studio / VS Code
- Git

### Langkah Install

1. **Clone repository ini**
   ```bash
   git clone https://github.com/TobyG74/cahaya-erlangga
   cd cahaya_erlangga
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

   Atau untuk build APK:
   ```bash
   flutter build apk --release
   ```

## Struktur Project

```
lib/
├── main.dart                  # Entry point aplikasi
├── models/                    # Data models
│   ├── barang.dart
│   ├── kategori.dart
│   ├── merek.dart
│   ├── pemasok.dart
│   ├── pelanggan.dart
│   ├── gudang.dart
│   ├── user.dart
│   ├── barang_masuk.dart
│   ├── barang_keluar.dart
│   └── penjualan.dart
├── screens/                   # UI Screens
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── barang_screen.dart
│   ├── kategori_screen.dart
│   ├── merek_screen.dart
│   ├── pemasok_screen.dart
│   ├── gudang_screen.dart
│   ├── barang_masuk_screen.dart
│   ├── barang_keluar_screen.dart
│   ├── penjualan_screen.dart
│   ├── penjualan_form_screen.dart
│   ├── laporan_screen.dart
│   ├── user_management_screen.dart
│   └── settings_screen.dart
├── services/                  # Business logic
│   ├── database_helper.dart
│   └── backup_manager.dart
├── providers/                 # State management
│   ├── auth_provider.dart
│   └── theme_provider.dart
├── widgets/                   # Reusable widgets
│   ├── barcode_scanner.dart
│   └── stat_card.dart
└── utils/                     # Utilities
    └── pagination_helper.dart
```

## Cara Pakai

### Login Pertama Kali

Saat pertama kali membuka aplikasi, gunakan akun default:
- **Username**: `admin`
- **Password**: `admin123`

> **Penting**: Segera ganti password default setelah login pertama kali dari menu Settings

### Alur Kerja Umum

1. **Setup Master Data**
   - Buat kategori barang (misalnya: Ban, Oli, Aki, dll)
   - Tambahkan merek barang
   - Input data pemasok
   - Daftarkan pelanggan (opsional)
   - Setup gudang

2. **Input Barang**
   - Masuk ke menu Barang
   - Tambah data barang lengkap dengan harga dan kategori
   - Bisa pakai barcode scanner untuk input lebih cepat

3. **Transaksi Barang Masuk**
   - Pilih menu Barang Masuk
   - Pilih barang, pemasok, dan gudang tujuan
   - Input jumlah dan harga pembelian
   - Stok akan otomatis bertambah

4. **Transaksi Penjualan**
   - Buka menu Penjualan → Buat Penjualan Baru
   - Scan barcode atau cari barang manual
   - Tambahkan ke keranjang
   - Tentukan pelanggan (opsional)
   - Selesaikan transaksi
   - Stok akan otomatis berkurang

5. **Lihat Laporan**
   - Masuk ke menu Laporan
   - Pilih jenis laporan (Barang Masuk/Keluar/Penjualan)
   - Tentukan periode tanggal
   - Export ke Excel atau PDF sesuai kebutuhan

### Manajemen User

Khusus untuk Admin:
- Tambah user baru dengan role Staff atau Admin
- Atur hak akses setiap user
- Nonaktifkan atau hapus user yang tidak diperlukan

### Backup Data

Untuk keamanan data:
1. Masuk ke Settings
2. Pilih "Backup Database"
3. File backup akan tersimpan di folder Documents
4. Untuk restore, pilih file backup yang sudah dibuat

## Dependencies

Berikut library yang digunakan:

```yaml
dependencies:
  provider: ^6.1.2         # State management
  sqflite: ^2.3.2         # Database lokal
  path_provider: ^2.1.2    # File path utilities
  shared_preferences: ^2.2.2  # Penyimpanan preferences
  pdf: ^3.10.8            # Generate PDF
  printing: ^5.12.0       # Print & share PDF
  excel: ^4.0.3           # Generate Excel
  intl: ^0.19.0           # Formatting tanggal & angka
  mobile_scanner: ^5.2.3  # Barcode scanner
  file_picker: ^8.1.6     # File picker untuk backup
  fl_chart: ^0.66.2       # Grafik & chart
  uuid: ^4.3.3            # Generate unique ID
```

## Database Schema

Aplikasi menggunakan SQLite dengan struktur database sebagai berikut:

- `users` - Data pengguna sistem
- `kategori` - Kategori barang
- `merek` - Merek barang
- `barang` - Master data barang
- `pemasok` - Data supplier
- `gudang` - Data gudang
- `pelanggan` - Data pelanggan
- `barang_masuk` - Transaksi pembelian
- `barang_keluar` - Transaksi pengeluaran
- `penjualan` - Header transaksi penjualan
- `penjualan_detail` - Detail item penjualan

## Lisensi

[MIT Lisence](https://github.com/TobyG74/cahaya-erlangga/blob/master/LICENSE) - Project ini dibuat untuk keperluan tugas akhir/KKP (Kerja Praktek).

## Kontributor

- Developer: Tobi Saputra
- Anggota KKP: 
    - Endriyan Ramadhan
    - Muhammad Ishafakhri Akbar
    - Muhammad Zulfahmi
    - Satrio Baskoro
    - Fachri Akbar Alghifahri
    - Ridho Alfiansyah Yuharian
    - Azizan Ramadhan
    - Tobi Saputra
- Pembimbing: Dr. Adhi Susano, M. Kom.
- Institusi: Universitas Indraprasta PGRI

---

**NOTE**: Aplikasi ini masih dalam tahap pengembangan. Jika menemukan bug atau ada saran, silakan hubungi developer.
