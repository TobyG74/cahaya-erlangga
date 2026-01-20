import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/barang_masuk.dart';
import '../models/barang.dart';
import '../models/pemasok.dart';
import '../models/gudang.dart';
import '../services/database_helper.dart';
import '../utils/pagination_helper.dart';

class BarangMasukScreen extends StatefulWidget {
  const BarangMasukScreen({super.key});

  @override
  State<BarangMasukScreen> createState() => _BarangMasukScreenState();
}

class _BarangMasukScreenState extends State<BarangMasukScreen>
    with PaginationMixin<BarangMasukScreen, BarangMasuk> {
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
      final result = await DatabaseHelper.instance.getBarangMasukPaginated(
        limit: limit,
        offset: offset,
        startDate: _startDate,
        endDate: _endDate,
        searchQuery: _searchController.text.trim().isEmpty 
          ? null 
          : _searchController.text.trim(),
      );

      setState(() {
        items = result['items'] as List<BarangMasuk>;
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
        title: const Text('Barang Masuk'),
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
                    hintText: 'Cari barang atau pemasok...',
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
                ? const Center(child: Text('Tidak ada data barang masuk'))
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
                                  const Icon(Icons.business, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.namaPemasok ?? 'Pemasok tidak diketahui',
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
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(item.hargaMasuk),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: ${_formatCurrency(item.hargaMasuk * item.jumlah)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(item.tanggalMasuk.toIso8601String()),
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
          onPressed: () => _showBarangMasukForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _showBarangMasukForm(BuildContext context, {BarangMasuk? barangMasuk}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => BarangMasukFormDialog(barangMasuk: barangMasuk),
    );

    if (result == true) {
      resetPagination();
      setState(() => isLoadingMore = true);
      loadData();
    }
  }
}

class BarangMasukFormDialog extends StatefulWidget {
  final BarangMasuk? barangMasuk;

  const BarangMasukFormDialog({super.key, this.barangMasuk});

  @override
  State<BarangMasukFormDialog> createState() => _BarangMasukFormDialogState();
}

class _BarangMasukFormDialogState extends State<BarangMasukFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;
  
  String? _selectedBarangId;
  String? _selectedPemasokId;
  String? _selectedGudangId;
  DateTime _tanggalMasuk = DateTime.now();
  final _jumlahController = TextEditingController();
  final _hargaController = TextEditingController();
  
  List<Barang> _barangList = [];
  List<Pemasok> _pemasokList = [];
  List<Gudang> _gudangList = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    if (widget.barangMasuk != null) {
      _selectedBarangId = widget.barangMasuk!.idBarang;
      _selectedPemasokId = widget.barangMasuk!.idPemasok;
      _selectedGudangId = widget.barangMasuk!.idGudang;
      _tanggalMasuk = widget.barangMasuk!.tanggalMasuk;
      _jumlahController.text = widget.barangMasuk!.jumlah.toString();
      _hargaController.text = widget.barangMasuk!.hargaMasuk.toString();
    }
  }

  Future<void> _loadData() async {
    final barang = await _dbHelper.getAllBarang();
    final pemasok = await _dbHelper.getAllPemasok();
    final gudang = await _dbHelper.getAllGudang();
    
    setState(() {
      _barangList = barang;
      _pemasokList = pemasok;
      _gudangList = gudang;
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalMasuk,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _tanggalMasuk = picked);
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
    
    if (_selectedPemasokId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pemasok terlebih dahulu')),
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

    final barangMasuk = BarangMasuk(
      idMasuk: widget.barangMasuk?.idMasuk ?? 'BM${DateTime.now().millisecondsSinceEpoch}',
      idBarang: _selectedBarangId!,
      idPemasok: _selectedPemasokId!,
      tanggalMasuk: _tanggalMasuk,
      jumlah: int.parse(_jumlahController.text),
      hargaMasuk: double.parse(_hargaController.text),
      idGudang: _selectedGudangId!,
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.barangMasuk == null) {
        await _dbHelper.insertBarangMasuk(barangMasuk);
      } else {
        await _dbHelper.insertBarangMasuk(barangMasuk);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.barangMasuk == null ? 'Barang masuk berhasil ditambahkan' : 'Barang masuk berhasil diupdate')),
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
      title: Text(widget.barangMasuk == null ? 'Tambah Barang Masuk' : 'Edit Barang Masuk'),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
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
                            _hargaController.text = barang.hargaBeli.toString();
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
                      Autocomplete<Pemasok>(
                        initialValue: _selectedPemasokId != null
                            ? TextEditingValue(
                                text: _pemasokList.firstWhere(
                                  (p) => p.idPemasok == _selectedPemasokId,
                                  orElse: () => _pemasokList.first,
                                ).namaPemasok,
                              )
                            : null,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _pemasokList;
                          }
                          return _pemasokList.where((Pemasok pemasok) {
                            return pemasok.namaPemasok
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        displayStringForOption: (Pemasok pemasok) => pemasok.namaPemasok,
                        onSelected: (Pemasok pemasok) {
                          setState(() => _selectedPemasokId = pemasok.idPemasok);
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Pemasok',
                              hintText: 'Ketik untuk mencari...',
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            validator: (value) {
                              if (_selectedPemasokId == null) {
                                return 'Pilih pemasok dari daftar';
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
                                    final pemasok = options.elementAt(index);
                                    return ListTile(
                                      title: Text(pemasok.namaPemasok),
                                      subtitle: Text(pemasok.noTelp ?? 'Tidak ada nomor'),
                                      onTap: () => onSelected(pemasok),
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
                          labelText: 'Tanggal Masuk',
                          hintText: 'Pilih tanggal',
                          suffixIcon: const Icon(Icons.calendar_today),
                          border: const OutlineInputBorder(),
                        ),
                        controller: TextEditingController(
                          text: DateFormat('dd MMM yyyy').format(_tanggalMasuk),
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
                          labelText: 'Harga Masuk',
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
