# BAB 4 - BAGIAN F
## HIRARKI FUNGSI SISTEM MANAJEMEN BENGKEL ERLANGGA MOTOR

### F. Hirarki Fungsi Sistem

Sistem Manajemen Bengkel Erlangga Motor dirancang dengan struktur hirarki fungsi yang terorganisir untuk memudahkan pengelolaan operasional bengkel. Berikut adalah penjelasan detail mengenai hirarki fungsi yang ada dalam sistem:

---

#### 1. FUNGSI LEVEL 0 (ROOT/INTI SISTEM)
**Sistem Manajemen Bengkel Erlangga Motor**
- Merupakan fungsi utama/induk yang menaungi seluruh fungsi operasional sistem
- Bertanggung jawab atas integrasi seluruh modul dan keamanan sistem

---

#### 2. FUNGSI LEVEL 1 (MODUL UTAMA)

Sistem terbagi menjadi 3 modul utama yang menjadi pilar operasional:

##### 2.1 Modul Autentikasi & Keamanan
- **Deskripsi**: Mengelola akses pengguna dan keamanan sistem
- **Fungsi Utama**:
  - Login/Logout pengguna
  - Manajemen sesi pengguna
  - Validasi hak akses berdasarkan role
  - Enkripsi password

##### 2.2 Modul Manajemen Data Master
- **Deskripsi**: Mengelola data referensi dan konfigurasi sistem
- **Fungsi Utama**:
  - Pengelolaan data dasar operasional
  - Konfigurasi parameter sistem
  - Maintenance data master

##### 2.3 Modul Transaksi & Operasional
- **Deskripsi**: Mengelola proses bisnis dan transaksi harian
- **Fungsi Utama**:
  - Pencatatan transaksi
  - Pemrosesan data operasional
  - Monitoring aktivitas harian

---

#### 3. FUNGSI LEVEL 2 (SUB-MODUL)

##### 3.1 Sub-Modul dari Autentikasi & Keamanan

**3.1.1 Manajemen Pengguna**
- Tambah pengguna baru
- Edit data pengguna
- Hapus pengguna
- Atur role dan hak akses
- Reset password

**3.1.2 Kontrol Akses**
- Verifikasi kredensial
- Manajemen sesi login
- Pembatasan akses menu berdasarkan role (Admin/User)
- Logout otomatis

---

##### 3.2 Sub-Modul dari Manajemen Data Master

**3.2.1 Manajemen Kategori Barang**
- Tambah kategori baru
- Edit kategori
- Hapus kategori
- Lihat daftar kategori
- Pencarian kategori

**3.2.2 Manajemen Merek**
- Tambah merek baru
- Edit merek
- Hapus merek
- Lihat daftar merek
- Pencarian merek

**3.2.3 Manajemen Barang/Inventori**
- Tambah barang baru (manual atau scan barcode)
- Edit data barang
- Hapus barang
- Lihat stok barang
- Update harga beli dan harga jual
- Pencarian barang
- Filter barang berdasarkan kategori/merek
- Pagination data

**3.2.4 Manajemen Pemasok/Supplier**
- Tambah pemasok baru
- Edit data pemasok
- Hapus pemasok
- Lihat daftar pemasok
- Kelola informasi kontak
- Pencarian pemasok

**3.2.5 Manajemen Gudang**
- Tambah gudang baru
- Edit data gudang
- Hapus gudang
- Atur kepala gudang
- Kelola lokasi gudang
- Lihat daftar gudang

**3.2.6 Manajemen Pelanggan**
- Tambah pelanggan baru
- Edit data pelanggan
- Hapus pelanggan
- Lihat daftar pelanggan
- Kelola informasi kontak

---

##### 3.3 Sub-Modul dari Transaksi & Operasional

**3.3.1 Barang Masuk**
- Catat transaksi barang masuk
- Input dari pemasok
- Pilih gudang tujuan
- Update stok otomatis
- Edit transaksi barang masuk
- Hapus transaksi
- Lihat riwayat barang masuk
- Filter berdasarkan periode

**3.3.2 Barang Keluar**
- Catat transaksi barang keluar
- Pilih gudang asal
- Update stok otomatis
- Input tujuan/keterangan
- Edit transaksi barang keluar
- Hapus transaksi
- Lihat riwayat barang keluar
- Filter berdasarkan periode

**3.3.3 Penjualan**
- Input transaksi penjualan (POS)
- Scan barcode produk
- Input manual produk
- Pilih pelanggan
- Hitung total otomatis
- Simpan transaksi penjualan
- Cetak struk/nota
- Edit transaksi penjualan
- Hapus transaksi
- Lihat riwayat penjualan
- Filter berdasarkan periode

**3.3.4 Laporan**
- Generate laporan barang
- Generate laporan stok
- Generate laporan penjualan
- Generate laporan keuangan
- Export ke Excel
- Export ke PDF
- Cetak laporan
- Filter laporan berdasarkan periode
- Statistik dan grafik

---

#### 4. FUNGSI LEVEL 3 (DETAIL OPERASI)

##### 4.1 Operasi Database
- **CRUD Operations**: Create, Read, Update, Delete data
- **Query & Filter**: Pencarian dan penyaringan data
- **Pagination**: Pembagian data per halaman
- **Validation**: Validasi input data
- **Transaction**: Pengelolaan transaksi database

##### 4.2 Operasi File & Backup
- **Auto Backup**: Backup otomatis database
- **Manual Backup**: Backup manual oleh user
- **Restore**: Pemulihan database dari backup
- **Export Data**: Export data ke Excel/PDF
- **File Management**: Pengelolaan folder laporan

##### 4.3 Operasi UI/UX
- **Theme Management**: Dark/Light mode
- **Navigation**: Menu navigasi dan routing
- **Form Handling**: Penanganan input form
- **Barcode Scanner**: Scan barcode produk
- **Statistics Display**: Tampilan dashboard & statistik
- **Notification**: Notifikasi dan alert

##### 4.4 Operasi Utility
- **Date/Time Management**: Pengelolaan tanggal dan waktu
- **ID Generation**: Generate ID unik
- **Calculation**: Perhitungan harga, total, dll
- **Validation**: Validasi data input
- **Permission**: Pengecekan izin aplikasi

---

#### 5. DIAGRAM HIRARKI FUNGSI

```
SISTEM MANAJEMEN BENGKEL ERLANGGA MOTOR
│
├── AUTENTIKASI & KEAMANAN
│   ├── Manajemen Pengguna
│   │   ├── Tambah User
│   │   ├── Edit User
│   │   ├── Hapus User
│   │   ├── Atur Role
│   │   └── Reset Password
│   │
│   └── Kontrol Akses
│       ├── Login
│       ├── Logout
│       ├── Verifikasi
│       └── Manajemen Sesi
│
├── MANAJEMEN DATA MASTER
│   ├── Kategori Barang
│   │   ├── CRUD Kategori
│   │   └── Pencarian
│   │
│   ├── Merek
│   │   ├── CRUD Merek
│   │   └── Pencarian
│   │
│   ├── Barang/Inventori
│   │   ├── CRUD Barang
│   │   ├── Scan Barcode
│   │   ├── Kelola Stok
│   │   ├── Kelola Harga
│   │   └── Filter & Pencarian
│   │
│   ├── Pemasok/Supplier
│   │   ├── CRUD Pemasok
│   │   └── Kelola Kontak
│   │
│   ├── Gudang
│   │   ├── CRUD Gudang
│   │   └── Atur Kepala Gudang
│   │
│   └── Pelanggan
│       ├── CRUD Pelanggan
│       └── Kelola Kontak
│
└── TRANSAKSI & OPERASIONAL
    ├── Barang Masuk
    │   ├── Input Barang Masuk
    │   ├── Pilih Pemasok
    │   ├── Pilih Gudang
    │   ├── Update Stok
    │   └── Riwayat & Filter
    │
    ├── Barang Keluar
    │   ├── Input Barang Keluar
    │   ├── Pilih Gudang
    │   ├── Update Stok
    │   └── Riwayat & Filter
    │
    ├── Penjualan (POS)
    │   ├── Input Transaksi
    │   ├── Scan/Pilih Produk
    │   ├── Pilih Pelanggan
    │   ├── Hitung Total
    │   ├── Simpan Transaksi
    │   ├── Cetak Nota
    │   └── Riwayat & Filter
    │
    └── Laporan
        ├── Laporan Barang
        ├── Laporan Stok
        ├── Laporan Penjualan
        ├── Laporan Keuangan
        ├── Export Excel/PDF
        ├── Cetak Laporan
        └── Statistik & Grafik
```

---

#### 6. TABEL MATRIKS FUNGSI DAN HAK AKSES

| No | Fungsi/Modul | Admin | User | Deskripsi |
|----|--------------|-------|------|-----------|
| 1 | Dashboard | ✓ | ✓ | Tampilan statistik sistem |
| 2 | Manajemen User | ✓ | ✗ | CRUD data pengguna |
| 3 | Kategori | ✓ | ✓ | CRUD data kategori |
| 4 | Merek | ✓ | ✓ | CRUD data merek |
| 5 | Barang | ✓ | ✓ | CRUD data barang |
| 6 | Pemasok | ✓ | ✓ | CRUD data pemasok |
| 7 | Gudang | ✓ | ✓ | CRUD data gudang |
| 8 | Barang Masuk | ✓ | ✓ | Transaksi barang masuk |
| 9 | Barang Keluar | ✓ | ✓ | Transaksi barang keluar |
| 10 | Penjualan | ✓ | ✓ | Transaksi penjualan |
| 11 | Laporan | ✓ | ✓ | Generate & export laporan |
| 12 | Settings | ✓ | ✓ | Pengaturan aplikasi |
| 13 | Backup/Restore | ✓ | ✗ | Backup database |
| 14 | Reset Database | ✓ | ✗ | Reset seluruh database |

---

#### 7. INTEGRASI ANTAR FUNGSI

##### 7.1 Alur Integrasi Data Master → Transaksi
1. **Kategori & Merek** → digunakan untuk klasifikasi **Barang**
2. **Barang** → digunakan dalam transaksi **Barang Masuk**, **Barang Keluar**, dan **Penjualan**
3. **Pemasok** → digunakan dalam transaksi **Barang Masuk**
4. **Gudang** → digunakan dalam transaksi **Barang Masuk** dan **Barang Keluar**
5. **Pelanggan** → digunakan dalam transaksi **Penjualan**

##### 7.2 Alur Integrasi Transaksi → Laporan
1. **Barang Masuk** → data untuk **Laporan Stok** dan **Laporan Barang**
2. **Barang Keluar** → data untuk **Laporan Stok** dan **Laporan Barang**
3. **Penjualan** → data untuk **Laporan Penjualan** dan **Laporan Keuangan**

##### 7.3 Alur Update Stok Otomatis
1. **Barang Masuk** → Stok bertambah di tabel Barang
2. **Barang Keluar** → Stok berkurang di tabel Barang
3. **Penjualan** → Stok berkurang di tabel Barang

---

#### 8. FUNGSI PENDUKUNG SISTEM

##### 8.1 Barcode Scanner
- Scanning barcode untuk input ID barang
- Integrasi dengan form input barang
- Validasi hasil scan
- Permission kamera

##### 8.2 Theme Provider
- Toggle dark/light mode
- Persistensi preferensi theme
- Responsif terhadap system theme

##### 8.3 Pagination Helper
- Pembagian data per halaman
- Navigasi halaman
- Info jumlah data

##### 8.4 Backup Manager
- Auto backup berkala
- Manual backup
- Restore database
- Validasi file backup

---

#### 9. TEKNOLOGI DAN ARSITEKTUR

##### 9.1 Layer Arsitektur
1. **Presentation Layer**: UI/Screens (Flutter Widgets)
2. **Business Logic Layer**: Providers (State Management)
3. **Data Layer**: Database Helper, Models
4. **Service Layer**: Backup Manager, Utility Services

##### 9.2 Design Pattern
- **Provider Pattern**: State management
- **Singleton Pattern**: Database Helper, Backup Manager
- **Repository Pattern**: Database operations
- **MVC/MVVM Hybrid**: Separation of concerns

---

#### 10. KESIMPULAN

Sistem Manajemen Bengkel Erlangga Motor memiliki struktur hirarki fungsi yang terorganisir dengan baik, terdiri dari:

- **3 Modul Utama**: Autentikasi, Data Master, dan Transaksi
- **13 Sub-Modul**: Mencakup seluruh aspek operasional bengkel
- **50+ Fungsi Detail**: Operasi CRUD, transaksi, dan reporting
- **Integrasi Terintegrasi**: Aliran data yang seamless antar modul
- **Role-Based Access**: Pembatasan akses berdasarkan role pengguna

Hirarki fungsi ini memastikan sistem dapat:
1. Mengelola data master dengan efisien
2. Memproses transaksi secara real-time
3. Menghasilkan laporan yang akurat
4. Menjaga keamanan dan integritas data
5. Memberikan user experience yang baik

Dengan struktur ini, sistem dapat dikembangkan dan dimaintain dengan mudah karena setiap fungsi memiliki tanggung jawab yang jelas dan terpisah (separation of concerns).
