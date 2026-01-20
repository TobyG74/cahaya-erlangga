import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/barang_keluar.dart';
import '../models/barang.dart';
import '../models/pelanggan.dart';
import '../models/gudang.dart';
import '../services/database_helper.dart';
import '../utils/pagination_helper.dart';

class BarangKeluarScreen extends StatefulWidget {
  const BarangKeluarScreen({super.key});

  @override
  State<BarangKeluarScreen> createState() => _BarangKeluarScreenState();
}

class _BarangKeluarScreenState extends State<BarangKeluarScreen>
    with PaginationMixin<BarangKeluarScreen, BarangKeluar> {
  final TextEditingController _searchController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> loadData() async {
    try {
      final result = await DatabaseHelper.instance.getBarangKeluarPaginated(
        limit: limit,
        offset: offset,
        startDate: _startDate,
        endDate: _endDate,
        searchQuery: _searchController.text.trim().isEmpty 
          ? null 
          : _searchController.text.trim(),
      );

      setState(() {
        items = result['items'] as List<BarangKeluar>;
        totalItems = result['totalCount'] as int;
      });
    } catch (e) {
      setState(() {
        items = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      resetPagination();
      loadData();
    }
  }

  void _onSearchChanged() {
    resetPagination();
    loadData();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatCurrency(double? value) {
    if (value == null) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeText = _startDate != null && _endDate != null
        ? '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
        : 'Pilih Periode';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Keluar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter Tanggal',
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari barang atau pelanggan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => _onSearchChanged(),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          dateRangeText,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: items.isEmpty && !isLoadingMore
                ? const Center(child: Text('Tidak ada data barang keluar'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            item.namaBarang ?? item.idBarang,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2, size: 16),
                                  const SizedBox(width: 4),
                                  Text('ID: ${item.idBarang}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.namaPelanggan ?? 'Pelanggan tidak diketahui',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.warehouse, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.namaGudang ?? 'Gudang tidak diketahui',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Jumlah: ${item.jumlah}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(item.hargaKeluar),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: ${_formatCurrency(item.hargaKeluar * item.jumlah)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(item.tanggalKeluar.toIso8601String()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
          ),
          buildPaginationControls(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => _showBarangKeluarForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _showBarangKeluarForm(BuildContext context, {BarangKeluar? barangKeluar}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => BarangKeluarFormDialog(barangKeluar: barangKeluar),
    );

    if (result == true) {
      resetPagination();
      setState(() => isLoadingMore = true);
      loadData();
    }
  }
}

class BarangKeluarFormDialog extends StatefulWidget {
  final BarangKeluar? barangKeluar;

  const BarangKeluarFormDialog({super.key, this.barangKeluar});

  @override
  State<BarangKeluarFormDialog> createState() => _BarangKeluarFormDialogState();
}

class _BarangKeluarFormDialogState extends State<BarangKeluarFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;
  
  String? _selectedBarangId;
  String? _selectedPelangganId;
  String? _selectedGudangId;
  DateTime _tanggalKeluar = DateTime.now();
  final _jumlahController = TextEditingController();
  final _hargaController = TextEditingController();
  
  List<Barang> _barangList = [];
  List<Pelanggan> _pelangganList = [];
  List<Gudang> _gudangList = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    if (widget.barangKeluar != null) {
      _selectedBarangId = widget.barangKeluar!.idBarang;
      _selectedPelangganId = widget.barangKeluar!.idPelanggan;
      _selectedGudangId = widget.barangKeluar!.idGudang;
      _tanggalKeluar = widget.barangKeluar!.tanggalKeluar;
      _jumlahController.text = widget.barangKeluar!.jumlah.toString();
      _hargaController.text = widget.barangKeluar!.hargaKeluar.toString();
    }
  }

  Future<void> _loadData() async {
    final barang = await _dbHelper.getAllBarang();
    final pelanggan = await _dbHelper.getAllPelanggan();
    final gudang = await _dbHelper.getAllGudang();
    
    setState(() {
      _barangList = barang;
      _pelangganList = pelanggan;
      _gudangList = gudang;
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalKeluar,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _tanggalKeluar = picked);
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedBarangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih barang terlebih dahulu')),
      );
      return;
    }
    
    if (_selectedGudangId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gudang terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final barangKeluar = BarangKeluar(
      idKeluar: widget.barangKeluar?.idKeluar ?? 'BK${DateTime.now().millisecondsSinceEpoch}',
      idBarang: _selectedBarangId!,
      idPelanggan: _selectedPelangganId,
      tanggalKeluar: _tanggalKeluar,
      jumlah: int.parse(_jumlahController.text),
      hargaKeluar: double.parse(_hargaController.text),
      idGudang: _selectedGudangId!,
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.barangKeluar == null) {
        await _dbHelper.insertBarangKeluar(barangKeluar);
      } else {
        await _dbHelper.insertBarangKeluar(barangKeluar);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.barangKeluar == null ? 'Barang keluar berhasil ditambahkan' : 'Barang keluar berhasil diupdate')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.barangKeluar == null ? 'Tambah Barang Keluar' : 'Edit Barang Keluar'),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<Barang>(
                      initialValue: _selectedBarangId != null
                          ? TextEditingValue(
                              text: _barangList.firstWhere(
                                (b) => b.idBarang == _selectedBarangId,
                                orElse: () => _barangList.first,
                              ).namaBarang,
                            )
                          : null,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _barangList;
                        }
                        return _barangList.where((Barang barang) {
                          final searchText = textEditingValue.text.toLowerCase();
                          return barang.namaBarang.toLowerCase().contains(searchText) ||
                                 barang.idBarang.toLowerCase().contains(searchText);
                        });
                      },
                      displayStringForOption: (Barang barang) => '${barang.namaBarang} (${barang.idBarang})',
                      onSelected: (Barang barang) {
                        setState(() {
                          _selectedBarangId = barang.idBarang;
                          _hargaController.text = barang.hargaJual.toString();
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Barang',
                            hintText: 'Ketik untuk mencari...',
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          validator: (value) {
                            if (_selectedBarangId == null) {
                              return 'Pilih barang dari daftar';
                            }
                            return null;
                          },
                          onFieldSubmitted: (value) => onFieldSubmitted(),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 200,
                                maxWidth: MediaQuery.of(context).size.width * 0.8,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final barang = options.elementAt(index);
                                  return ListTile(
                                    title: Text(barang.namaBarang),
                                    subtitle: Text('ID: ${barang.idBarang} • Stok: ${barang.stok}'),
                                    onTap: () => onSelected(barang),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<Pelanggan>(
                      initialValue: _selectedPelangganId != null
                          ? TextEditingValue(
                              text: _pelangganList.firstWhere(
                                (p) => p.idPelanggan == _selectedPelangganId,
                                orElse: () => _pelangganList.first,
                              ).namaPelanggan,
                            )
                          : null,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _pelangganList;
                        }
                        return _pelangganList.where((Pelanggan pelanggan) {
                          return pelanggan.namaPelanggan
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      displayStringForOption: (Pelanggan pelanggan) => pelanggan.namaPelanggan,
                      onSelected: (Pelanggan pelanggan) {
                        setState(() => _selectedPelangganId = pelanggan.idPelanggan);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Pelanggan (Opsional)',
                            hintText: 'Ketik untuk mencari...',
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          onFieldSubmitted: (value) => onFieldSubmitted(),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 200,
                                maxWidth: MediaQuery.of(context).size.width * 0.8,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final pelanggan = options.elementAt(index);
                                    return ListTile(
                                      title: Text(pelanggan.namaPelanggan),
                                      subtitle: Text(pelanggan.noTelp ?? 'Tidak ada nomor'),
                                      onTap: () => onSelected(pelanggan),
                                    );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<Gudang>(
                      initialValue: _selectedGudangId != null
                          ? TextEditingValue(
                              text: _gudangList.firstWhere(
                                (g) => g.idGudang == _selectedGudangId,
                                orElse: () => _gudangList.first,
                              ).namaGudang,
                            )
                          : null,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _gudangList;
                        }
                        return _gudangList.where((Gudang gudang) {
                          return gudang.namaGudang
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      displayStringForOption: (Gudang gudang) => gudang.namaGudang,
                      onSelected: (Gudang gudang) {
                        setState(() => _selectedGudangId = gudang.idGudang);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Gudang',
                            hintText: 'Ketik untuk mencari...',
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          validator: (value) {
                            if (_selectedGudangId == null) {
                              return 'Pilih gudang dari daftar';
                            }
                            return null;
                          },
                          onFieldSubmitted: (value) => onFieldSubmitted(),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 200,
                                maxWidth: MediaQuery.of(context).size.width * 0.8,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final gudang = options.elementAt(index);
                                    return ListTile(
                                      title: Text(gudang.namaGudang),
                                      subtitle: Text(gudang.lokasi ?? 'Lokasi tidak tersedia'),
                                      onTap: () => onSelected(gudang),
                                    );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Keluar',
                        hintText: 'Pilih tanggal',
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('dd MMM yyyy').format(_tanggalKeluar),
                      ),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _jumlahController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah harus diisi';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Jumlah harus lebih dari 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _hargaController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Keluar',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harga harus diisi';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Harga harus lebih dari 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveData,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
