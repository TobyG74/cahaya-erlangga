import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/database_helper.dart';
import '../models/barang_masuk.dart';
import '../models/barang_keluar.dart';
import '../models/penjualan.dart';
import '../models/barang.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/services.dart' show rootBundle;

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<BarangMasuk> _barangMasukList = [];
  List<BarangKeluar> _barangKeluarList = [];
  List<Penjualan> _penjualanList = [];
  List<Barang> _barangList = [];
  int _totalBarangTerjual = 0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final barangMasuk =
          await _dbHelper.getBarangMasukByDateRange(_startDate, _endDate);
      final barangKeluar =
          await _dbHelper.getBarangKeluarByDateRange(_startDate, _endDate);
      final penjualan =
          await _dbHelper.getPenjualanByDateRange(_startDate, _endDate);
      final totalBarang = await _dbHelper.getTotalBarangTerjualByDateRange(
          _startDate, _endDate);
      final barang = await _dbHelper.getAllBarang();

      setState(() {
        _barangMasukList = barangMasuk;
        _barangKeluarList = barangKeluar;
        _penjualanList = penjualan;
        _totalBarangTerjual = totalBarang;
        _barangList = barang;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Masuk', icon: Icon(Icons.arrow_downward, size: 18)),
            Tab(text: 'Keluar', icon: Icon(Icons.arrow_upward, size: 18)),
            Tab(text: 'Penjualan', icon: Icon(Icons.shopping_cart, size: 18)),
            Tab(text: 'Stok', icon: Icon(Icons.inventory_2, size: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range),
                      const SizedBox(width: 8),
                      Text(
                        'Periode Laporan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${DateFormat('dd MMM yyyy', 'id_ID').format(_startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_endDate)}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Ubah'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBarangMasukTab(),
                      _buildBarangKeluarTab(),
                      _buildPenjualanTab(),
                      _buildStokBarangTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangMasukTab() {
    if (_barangMasukList.isEmpty) {
      return const Center(
        child: Text('Tidak ada data barang masuk pada periode ini'),
      );
    }

    final totalJumlah =
        _barangMasukList.fold<int>(0, (sum, item) => sum + item.jumlah);
    final totalNilai = _barangMasukList.fold<double>(
        0, (sum, item) => sum + (item.hargaMasuk * item.jumlah));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Item',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalJumlah.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Nilai',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${_formatCurrency(totalNilai)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportToExcel('barang_masuk'),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportToPdf('barang_masuk'),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _barangMasukList.length,
            itemBuilder: (context, index) {
              final item = _barangMasukList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(item.namaBarang ?? item.idBarang),
                  subtitle: Text(
                    '${DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggalMasuk)}\n'
                    '${item.namaPemasok ?? '-'} • ${item.namaGudang ?? '-'}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.jumlah} pcs',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${_formatCurrency(item.hargaMasuk * item.jumlah)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarangKeluarTab() {
    if (_barangKeluarList.isEmpty) {
      return const Center(
        child: Text('Tidak ada data barang keluar pada periode ini'),
      );
    }

    final totalJumlah =
        _barangKeluarList.fold<int>(0, (sum, item) => sum + item.jumlah);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Item Keluar',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalJumlah.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportToExcel('barang_keluar'),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportToPdf('barang_keluar'),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _barangKeluarList.length,
            itemBuilder: (context, index) {
              final item = _barangKeluarList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(item.namaBarang ?? item.idBarang),
                  subtitle: Text(
                    '${DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggalKeluar)}\n'
                    '${item.namaPelanggan ?? 'Pelanggan tidak diketahui'} • ${item.namaGudang ?? '-'}',
                  ),
                  trailing: Text(
                    '${item.jumlah} pcs',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPenjualanTab() {
    if (_penjualanList.isEmpty) {
      return const Center(
        child: Text('Tidak ada data penjualan pada periode ini'),
      );
    }

    final totalPenjualan =
        _penjualanList.fold<double>(0, (sum, item) => sum + item.totalHarga);
    final totalTransaksi = _penjualanList.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Transaksi',
                              style: TextStyle(color: Colors.purple.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalTransaksi.toString(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Barang',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_totalBarangTerjual pcs',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Penjualan',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Rp ${_formatCurrency(totalPenjualan)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportToExcel('penjualan'),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportToPdf('penjualan'),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _penjualanList.length,
            itemBuilder: (context, index) {
              final item = _penjualanList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(item.namaPelanggan ?? 'Pelanggan Umum'),
                  subtitle: Text(
                    '${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(item.tanggalPenjualan)}\n'
                    'ID: ${item.idPenjualan}',
                  ),
                  trailing: Text(
                    'Rp ${_formatCurrency(item.totalHarga)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _exportToExcel(String type) async {
    try {
      final excel = excel_pkg.Excel.createExcel();
      final sheet = excel['Sheet1'];

      sheet.appendRow([
        excel_pkg.TextCellValue(
            'LAPORAN ${type.toUpperCase().replaceAll('_', ' ')}')
      ]);
      sheet.appendRow([
        excel_pkg.TextCellValue(
            'Periode: ${DateFormat('dd MMM yyyy', 'id_ID').format(_startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_endDate)}')
      ]);
      sheet.appendRow([excel_pkg.TextCellValue('')]);

      if (type == 'barang_masuk') {
        sheet.appendRow([
          excel_pkg.TextCellValue('No'),
          excel_pkg.TextCellValue('Tanggal'),
          excel_pkg.TextCellValue('Barang'),
          excel_pkg.TextCellValue('Pemasok'),
          excel_pkg.TextCellValue('Gudang'),
          excel_pkg.TextCellValue('Jumlah'),
          excel_pkg.TextCellValue('Harga Satuan'),
          excel_pkg.TextCellValue('Total'),
        ]);

        for (var i = 0; i < _barangMasukList.length; i++) {
          final item = _barangMasukList[i];
          sheet.appendRow([
            excel_pkg.IntCellValue(i + 1),
            excel_pkg.TextCellValue(
                DateFormat('dd/MM/yyyy').format(item.tanggalMasuk)),
            excel_pkg.TextCellValue(item.namaBarang ?? item.idBarang),
            excel_pkg.TextCellValue(item.namaPemasok ?? '-'),
            excel_pkg.TextCellValue(item.namaGudang ?? '-'),
            excel_pkg.IntCellValue(item.jumlah),
            excel_pkg.DoubleCellValue(item.hargaMasuk),
            excel_pkg.DoubleCellValue(item.hargaMasuk * item.jumlah),
          ]);
        }
      } else if (type == 'barang_keluar') {
        sheet.appendRow([
          excel_pkg.TextCellValue('No'),
          excel_pkg.TextCellValue('Tanggal'),
          excel_pkg.TextCellValue('Barang'),
          excel_pkg.TextCellValue('Pelanggan'),
          excel_pkg.TextCellValue('Gudang'),
          excel_pkg.TextCellValue('Jumlah'),
        ]);

        for (var i = 0; i < _barangKeluarList.length; i++) {
          final item = _barangKeluarList[i];
          sheet.appendRow([
            excel_pkg.IntCellValue(i + 1),
            excel_pkg.TextCellValue(
                DateFormat('dd/MM/yyyy').format(item.tanggalKeluar)),
            excel_pkg.TextCellValue(item.namaBarang ?? item.idBarang),
            excel_pkg.TextCellValue(item.namaPelanggan ?? 'Tidak diketahui'),
            excel_pkg.TextCellValue(item.namaGudang ?? '-'),
            excel_pkg.IntCellValue(item.jumlah),
          ]);
        }
      } else if (type == 'penjualan') {
        sheet.appendRow([
          excel_pkg.TextCellValue('No'),
          excel_pkg.TextCellValue('Tanggal'),
          excel_pkg.TextCellValue('ID Penjualan'),
          excel_pkg.TextCellValue('Pelanggan'),
          excel_pkg.TextCellValue('Total Harga'),
        ]);

        for (var i = 0; i < _penjualanList.length; i++) {
          final item = _penjualanList[i];
          sheet.appendRow([
            excel_pkg.IntCellValue(i + 1),
            excel_pkg.TextCellValue(
                DateFormat('dd/MM/yyyy HH:mm').format(item.tanggalPenjualan)),
            excel_pkg.TextCellValue(item.idPenjualan),
            excel_pkg.TextCellValue(item.namaPelanggan ?? 'Pelanggan Umum'),
            excel_pkg.DoubleCellValue(item.totalHarga),
          ]);
        }
      } else if (type == 'stok_barang') {
        sheet.appendRow([
          excel_pkg.TextCellValue('No'),
          excel_pkg.TextCellValue('Kode Barang'),
          excel_pkg.TextCellValue('Nama Barang'),
          excel_pkg.TextCellValue('Kategori'),
          excel_pkg.TextCellValue('Merek'),
          excel_pkg.TextCellValue('Stok'),
          excel_pkg.TextCellValue('Satuan'),
          excel_pkg.TextCellValue('Harga Beli'),
          excel_pkg.TextCellValue('Harga Jual'),
          excel_pkg.TextCellValue('Nilai Modal'),
          excel_pkg.TextCellValue('Nilai Jual'),
        ]);

        final barangTersedia =
            _barangList.where((item) => item.stok > 0).toList();
        for (var i = 0; i < barangTersedia.length; i++) {
          final item = barangTersedia[i];
          sheet.appendRow([
            excel_pkg.IntCellValue(i + 1),
            excel_pkg.TextCellValue(item.idBarang),
            excel_pkg.TextCellValue(item.namaBarang),
            excel_pkg.TextCellValue(item.namaKategori ?? '-'),
            excel_pkg.TextCellValue(item.namaMerek ?? '-'),
            excel_pkg.IntCellValue(item.stok),
            excel_pkg.TextCellValue(item.satuan),
            excel_pkg.DoubleCellValue(item.hargaBeli),
            excel_pkg.DoubleCellValue(item.hargaJual),
            excel_pkg.DoubleCellValue(item.hargaBeli * item.stok),
            excel_pkg.DoubleCellValue(item.hargaJual * item.stok),
          ]);
        }
      }

      final bytes = excel.encode();
      if (bytes != null) {
        final directory = await getApplicationDocumentsDirectory();
        final laporanDir =
            Directory('${directory.path}/ErlanggaMotor/Laporan/Excel');

        if (!await laporanDir.exists()) {
          await laporanDir.create(recursive: true);
        }

        final fileName =
            'Laporan_${type}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
        final file = File('${laporanDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Excel berhasil disimpan:\n$fileName'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error export Excel: $e')),
        );
      }
    }
  }

  Future<void> _exportToPdf(String type) async {
    try {
      final pdf = pw.Document();

      // Load logo
      final ByteData logoData = await rootBundle.load('assets/icon.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

      if (type == 'barang_masuk') {
        final totalJumlah =
            _barangMasukList.fold<int>(0, (sum, item) => sum + item.jumlah);
        final totalNilai = _barangMasukList.fold<double>(
            0, (sum, item) => sum + (item.hargaMasuk * item.jumlah));

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (context) => [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 70,
                    height: 70,
                    child: pw.Image(logo),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'CAHAYA ERLANGGA MOTOR',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Jl. Radar Auri No.76 5, RT.5/RW.14, Cibubur',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'Kec. Ciracas, Kota Depok, Jawa Barat 16454',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'No. Telp: (021) 87756249',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text(
                  'LAPORAN BARANG MASUK',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Periode: ${DateFormat('dd MMMM yyyy', 'id_ID').format(_startDate)} - ${DateFormat('dd MMMM yyyy', 'id_ID').format(_endDate)}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(4),
                headers: [
                  'No',
                  'Tanggal',
                  'Barang',
                  'Pemasok',
                  'Gudang',
                  'Qty',
                  'Harga',
                  'Total'
                ],
                data: List.generate(_barangMasukList.length, (i) {
                  final item = _barangMasukList[i];
                  return [
                    '${i + 1}',
                    DateFormat('dd/MM/yy').format(item.tanggalMasuk),
                    item.namaBarang ?? item.idBarang,
                    item.namaPemasok ?? '-',
                    item.namaGudang ?? '-',
                    '${item.jumlah}',
                    _formatCurrency(item.hargaMasuk),
                    _formatCurrency(item.hargaMasuk * item.jumlah),
                  ];
                }),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Item',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '$totalJumlah pcs',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Total Nilai',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Rp ${_formatCurrency(totalNilai)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Depok, ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Mengetahui,',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 50),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(width: 1),
                          ),
                        ),
                        child: pw.SizedBox(height: 1),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Hendra Setiawan',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      } else if (type == 'barang_keluar') {
        final totalJumlah =
            _barangKeluarList.fold<int>(0, (sum, item) => sum + item.jumlah);

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (context) => [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 100,
                    height: 100,
                    child: pw.Image(logo),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'CAHAYA ERLANGGA MOTOR',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Jl. Radar Auri No.76 5, RT.5/RW.14, Cibubur',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'Kec. Ciracas, Kota Depok, Jawa Barat 16454',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'No. Telp: (021) 87756249',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text(
                  'LAPORAN BARANG KELUAR',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Periode: ${DateFormat('dd MMMM yyyy', 'id_ID').format(_startDate)} - ${DateFormat('dd MMMM yyyy', 'id_ID').format(_endDate)}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
                headers: [
                  'No',
                  'Tanggal',
                  'Barang',
                  'Pelanggan',
                  'Gudang',
                  'Jumlah'
                ],
                data: List.generate(_barangKeluarList.length, (i) {
                  final item = _barangKeluarList[i];
                  return [
                    '${i + 1}',
                    DateFormat('dd/MM/yyyy').format(item.tanggalKeluar),
                    item.namaBarang ?? item.idBarang,
                    item.namaPelanggan ?? 'Tidak diketahui',
                    item.namaGudang ?? '-',
                    '${item.jumlah}',
                  ];
                }),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Item Keluar: $totalJumlah pcs',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Depok, ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Mengetahui,',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 50),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(width: 1),
                          ),
                        ),
                        child: pw.SizedBox(height: 1),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Hendra Setiawan',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      } else if (type == 'penjualan') {
        final ByteData logoData = await rootBundle.load('assets/icon.png');
        final Uint8List logoBytes = logoData.buffer.asUint8List();
        final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

        final totalPenjualan = _penjualanList.fold<double>(
            0, (sum, item) => sum + item.totalHarga);

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (context) => [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 100,
                    height: 100,
                    child: pw.Image(logo),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'CAHAYA ERLANGGA MOTOR',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Jl. Radar Auri No.76 5, RT.5/RW.14, Cibubur',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'Kec. Ciracas, Kota Depok, Jawa Barat 16454',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'No. Telp: (021) 87756249',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 15),

              // Report Title
              pw.Center(
                child: pw.Text(
                  'LAPORAN PENJUALAN',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // Period Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Periode: ${DateFormat('dd MMMM yyyy', 'id_ID').format(_startDate)} - ${DateFormat('dd MMMM yyyy', 'id_ID').format(_endDate)}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),

              // Sales Table
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
                headers: [
                  'No',
                  'Tanggal',
                  'ID Penjualan',
                  'Pelanggan',
                  'Total Harga (Rp)'
                ],
                data: List.generate(_penjualanList.length, (i) {
                  final item = _penjualanList[i];
                  return [
                    '${i + 1}',
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(item.tanggalPenjualan),
                    item.idPenjualan,
                    item.namaPelanggan ?? 'Pelanggan Umum',
                    _formatCurrency(item.totalHarga),
                  ];
                }),
              ),

              pw.SizedBox(height: 10),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Transaksi',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '${_penjualanList.length} transaksi',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Total Barang Terjual',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '$_totalBarangTerjual pcs',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange900,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Total Penjualan',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Rp ${_formatCurrency(totalPenjualan)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Signature Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Depok, ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Mengetahui,',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 50),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(width: 1),
                          ),
                        ),
                        child: pw.SizedBox(height: 1),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Hendra Setiawan',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      } else if (type == 'stok_barang') {
        final barangTersedia =
            _barangList.where((item) => item.stok > 0).toList();
        final totalItem = barangTersedia.length;
        final totalStok =
            barangTersedia.fold<int>(0, (sum, item) => sum + item.stok);
        final totalNilaiBeli = barangTersedia.fold<double>(
            0, (sum, item) => sum + (item.hargaBeli * item.stok));
        final totalNilaiJual = barangTersedia.fold<double>(
            0, (sum, item) => sum + (item.hargaJual * item.stok));

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(40),
            build: (context) => [
              // Header with Logo and Company Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 100,
                    height: 100,
                    child: pw.Image(logo),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'CAHAYA ERLANGGA MOTOR',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Jl. Radar Auri No.76 5, RT.5/RW.14, Cibubur',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'Kec. Ciracas, Kota Depok, Jawa Barat 16454',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'No. Telp: (021) 87756249',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text(
                  'LAPORAN STOK BARANG',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 15),

              // Stock Table
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(3),
                headers: [
                  'No',
                  'Kode',
                  'Nama Barang',
                  'Kategori',
                  'Merek',
                  'Stok',
                  'Satuan',
                  'Harga Beli',
                  'Harga Jual',
                  'Nilai Modal',
                  'Nilai Jual'
                ],
                data: List.generate(barangTersedia.length, (i) {
                  final item = barangTersedia[i];
                  return [
                    '${i + 1}',
                    item.idBarang,
                    item.namaBarang,
                    item.namaKategori ?? '-',
                    item.namaMerek ?? '-',
                    '${item.stok}',
                    item.satuan,
                    _formatCurrency(item.hargaBeli),
                    _formatCurrency(item.hargaJual),
                    _formatCurrency(item.hargaBeli * item.stok),
                    _formatCurrency(item.hargaJual * item.stok),
                  ];
                }),
              ),

              pw.SizedBox(height: 10),

              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Item',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '$totalItem item',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Total Stok',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '$totalStok pcs',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Nilai Modal',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Rp ${_formatCurrency(totalNilaiBeli)}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Nilai Jual Potensial',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Rp ${_formatCurrency(totalNilaiJual)}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.purple900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Signature Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Depok, ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Mengetahui,',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 50),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(width: 1),
                          ),
                        ),
                        child: pw.SizedBox(height: 1),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Hendra Setiawan',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final laporanDir =
          Directory('${directory.path}/ErlanggaMotor/Laporan/PDF');

      if (!await laporanDir.exists()) {
        await laporanDir.create(recursive: true);
      }

      final fileName =
          'Laporan_${type}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${laporanDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil disimpan:\n${file.path}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Preview',
              onPressed: () async {
                try {
                  await Printing.layoutPdf(
                    onLayout: (format) async => pdf.save(),
                    name: fileName,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Tidak dapat membuka preview. PDF sudah tersimpan di folder Laporan.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error export PDF: $e')),
        );
      }
    }
  }

  Widget _buildStokBarangTab() {
    if (_barangList.isEmpty) {
      return const Center(
        child: Text('Tidak ada data barang'),
      );
    }

    // Filter hanya barang yang stoknya > 0
    final barangTersedia = _barangList.where((item) => item.stok > 0).toList();

    if (barangTersedia.isEmpty) {
      return const Center(
        child: Text('Tidak ada barang dengan stok tersedia'),
      );
    }

    // Hitung statistik
    final totalItem = barangTersedia.length;
    final totalStok =
        barangTersedia.fold<int>(0, (sum, item) => sum + item.stok);
    final totalNilaiBeli = barangTersedia.fold<double>(
        0, (sum, item) => sum + (item.hargaBeli * item.stok));
    final totalNilaiJual = barangTersedia.fold<double>(
        0, (sum, item) => sum + (item.hargaJual * item.stok));
    final stokRendah = barangTersedia.where((item) => item.stok < 10).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Item',
                              style: TextStyle(
                                  color: Colors.blue.shade700, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalItem.toString(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Stok',
                              style: TextStyle(
                                  color: Colors.orange.shade700, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalStok pcs',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stok Rendah',
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$stokRendah item',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nilai Modal (Harga Beli)',
                              style: TextStyle(
                                  color: Colors.green.shade700, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${_formatCurrency(totalNilaiBeli)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nilai Jual Potensial',
                              style: TextStyle(
                                  color: Colors.purple.shade700, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${_formatCurrency(totalNilaiJual)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportToExcel('stok_barang'),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportToPdf('stok_barang'),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: barangTersedia.length,
            itemBuilder: (context, index) {
              final item = barangTersedia[index];
              final isLowStock = item.stok < 10;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isLowStock ? Colors.red : Colors.blue,
                    child: Icon(
                      isLowStock ? Icons.warning : Icons.inventory_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.namaBarang,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${item.namaKategori ?? '-'} • ${item.namaMerek ?? '-'}\n'
                    'Harga Beli: Rp ${_formatCurrency(item.hargaBeli)} | '
                    'Harga Jual: Rp ${_formatCurrency(item.hargaJual)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.stok} ${item.satuan}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isLowStock ? Colors.red : Colors.green,
                        ),
                      ),
                      if (isLowStock)
                        const Text(
                          'Stok Rendah',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatCurrency(dynamic value) {
    final number = (value is int) ? value : (value as double).toInt();
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
