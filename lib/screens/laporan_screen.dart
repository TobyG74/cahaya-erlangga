import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../models/barang_masuk.dart';
import '../models/barang_keluar.dart';
import '../models/penjualan.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel_pkg;

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  List<BarangMasuk> _barangMasukList = [];
  List<BarangKeluar> _barangKeluarList = [];
  List<Penjualan> _penjualanList = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final barangMasuk = await _dbHelper.getBarangMasukByDateRange(_startDate, _endDate);
      final barangKeluar = await _dbHelper.getBarangKeluarByDateRange(_startDate, _endDate);
      final penjualan = await _dbHelper.getPenjualanByDateRange(_startDate, _endDate);
      
      setState(() {
        _barangMasukList = barangMasuk;
        _barangKeluarList = barangKeluar;
        _penjualanList = penjualan;
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
            Tab(text: 'Barang Masuk', icon: Icon(Icons.arrow_downward)),
            Tab(text: 'Barang Keluar', icon: Icon(Icons.arrow_upward)),
            Tab(text: 'Penjualan', icon: Icon(Icons.shopping_cart)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date filter card
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
                          '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
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
          
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBarangMasukTab(),
                      _buildBarangKeluarTab(),
                      _buildPenjualanTab(),
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

    final totalJumlah = _barangMasukList.fold<int>(0, (sum, item) => sum + item.jumlah);
    final totalNilai = _barangMasukList.fold<double>(0, (sum, item) => sum + (item.hargaMasuk * item.jumlah));

    return Column(
      children: [
        // Summary cards
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
        
        // Export buttons
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
        
        // Data list
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
                    '${DateFormat('dd MMM yyyy').format(item.tanggalMasuk)}\n'
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

    final totalJumlah = _barangKeluarList.fold<int>(0, (sum, item) => sum + item.jumlah);

    return Column(
      children: [
        // Summary card
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
        
        // Export buttons
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
        
        // Data list
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
                    '${DateFormat('dd MMM yyyy').format(item.tanggalKeluar)}\n'
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

    final totalPenjualan = _penjualanList.fold<double>(0, (sum, item) => sum + item.totalHarga);
    final totalTransaksi = _penjualanList.length;

    return Column(
      children: [
        // Summary cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Penjualan',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${_formatCurrency(totalPenjualan)}',
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
        
        // Export buttons
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
        
        // Data list
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
                    '${DateFormat('dd MMM yyyy HH:mm').format(item.tanggalPenjualan)}\n'
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
      
      // Add title
      sheet.appendRow([
        excel_pkg.TextCellValue('LAPORAN ${type.toUpperCase().replaceAll('_', ' ')}')
      ]);
      sheet.appendRow([
        excel_pkg.TextCellValue('Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}')
      ]);
      sheet.appendRow([excel_pkg.TextCellValue('')]);
      
      // Add headers and data based on type
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
            excel_pkg.TextCellValue(DateFormat('dd/MM/yyyy').format(item.tanggalMasuk)),
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
            excel_pkg.TextCellValue(DateFormat('dd/MM/yyyy').format(item.tanggalKeluar)),
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
            excel_pkg.TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(item.tanggalPenjualan)),
            excel_pkg.TextCellValue(item.idPenjualan),
            excel_pkg.TextCellValue(item.namaPelanggan ?? 'Pelanggan Umum'),
            excel_pkg.DoubleCellValue(item.totalHarga),
          ]);
        }
      }
      
      // Save file
      final bytes = excel.encode();
      if (bytes != null) {
        final directory = await getApplicationDocumentsDirectory();
        final laporanDir = Directory('${directory.path}/ErlanggaMotor/Laporan/Excel');
        
        // Create directory if it doesn't exist
        if (!await laporanDir.exists()) {
          await laporanDir.create(recursive: true);
        }
        
        final fileName = 'Laporan_${type}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
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
      
      // Add pages
      if (type == 'barang_masuk') {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'LAPORAN BARANG MASUK',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text('Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['No', 'Tanggal', 'Barang', 'Pemasok', 'Gudang', 'Jumlah', 'Harga', 'Total'],
                data: List.generate(_barangMasukList.length, (i) {
                  final item = _barangMasukList[i];
                  return [
                    '${i + 1}',
                    DateFormat('dd/MM/yyyy').format(item.tanggalMasuk),
                    item.namaBarang ?? item.idBarang,
                    item.namaPemasok ?? '-',
                    item.namaGudang ?? '-',
                    '${item.jumlah}',
                    _formatCurrency(item.hargaMasuk),
                    _formatCurrency(item.hargaMasuk * item.jumlah),
                  ];
                }),
              ),
            ],
          ),
        );
      } else if (type == 'barang_keluar') {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'LAPORAN BARANG KELUAR',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text('Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['No', 'Tanggal', 'Barang', 'Pelanggan', 'Gudang', 'Jumlah'],
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
            ],
          ),
        );
      } else if (type == 'penjualan') {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'LAPORAN PENJUALAN',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text('Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['No', 'Tanggal', 'ID Penjualan', 'Pelanggan', 'Total Harga'],
                data: List.generate(_penjualanList.length, (i) {
                  final item = _penjualanList[i];
                  return [
                    '${i + 1}',
                    DateFormat('dd/MM/yyyy HH:mm').format(item.tanggalPenjualan),
                    item.idPenjualan,
                    item.namaPelanggan ?? 'Pelanggan Umum',
                    _formatCurrency(item.totalHarga),
                  ];
                }),
              ),
            ],
          ),
        );
      }
      
      // Save to file and show print dialog
      final directory = await getApplicationDocumentsDirectory();
      final laporanDir = Directory('${directory.path}/ErlanggaMotor/Laporan/PDF');
      
      // Create directory if it doesn't exist
      if (!await laporanDir.exists()) {
        await laporanDir.create(recursive: true);
      }
      
      final fileName = 'Laporan_${type}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${laporanDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF berhasil disimpan:\n$fileName'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      // Show print preview
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error export PDF: $e')),
        );
      }
    }
  }

  String _formatCurrency(dynamic value) {
    final number = (value is int) ? value : (value as double).toInt();
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

