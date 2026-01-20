import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/barang.dart';
import '../models/kategori.dart';
import '../models/merek.dart';
import '../providers/auth_provider.dart';
import '../widgets/barcode_scanner.dart';
import '../utils/pagination_helper.dart';
import 'package:provider/provider.dart';

class BarangScreen extends StatefulWidget {
  const BarangScreen({super.key});

  @override
  State<BarangScreen> createState() => _BarangScreenState();
}

class _BarangScreenState extends State<BarangScreen> with PaginationMixin<BarangScreen, Barang> {
  List<Kategori> _kategoriList = [];
  List<Merek> _merekList = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  int? _filterKategoriId;
  String? _filterMerekId;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    final kategori = await DatabaseHelper.instance.getAllKategori();
    final merek = await DatabaseHelper.instance.getAllMerek();
    
    setState(() {
      _kategoriList = kategori;
      _merekList = merek;
    });
  }

  @override
  Future<void> loadData() async {
    try {
      final result = await DatabaseHelper.instance.getBarangPaginated(
        limit: limit,
        offset: offset,
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        kategoriId: _filterKategoriId,
        merekId: _filterMerekId,
      );
      
      setState(() {
        items = result['items'] as List<Barang>;
        totalItems = result['totalCount'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchOrFilterChanged() {
    resetPagination();
    setState(() => _isLoading = true);
    loadData();
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      _searchController.text = result;
      _onSearchOrFilterChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              resetPagination();
              setState(() => _isLoading = true);
              loadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari barang...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scanBarcode,
                      tooltip: 'Scan Barcode',
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchOrFilterChanged();
                        },
                      ),
                  ],
                ),
              ),
              onChanged: (v) => _onSearchOrFilterChanged(),
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: Text(_filterKategoriId == null ? 'Kategori' : _kategoriList.firstWhere((k) => k.idKategori == _filterKategoriId).namaKategori),
                  selected: _filterKategoriId != null,
                  onSelected: (_) => _showKategoriFilter(),
                  avatar: const Icon(Icons.category, size: 18),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(_filterMerekId == null ? 'Merek' : _merekList.firstWhere((m) => m.idMerek.toString() == _filterMerekId).namaMerek),
                  selected: _filterMerekId != null,
                  onSelected: (_) => _showMerekFilter(),
                  avatar: const Icon(Icons.business, size: 18),
                ),
                if (_filterKategoriId != null || _filterMerekId != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _filterKategoriId = null;
                        _filterMerekId = null;
                      });
                      _onSearchOrFilterChanged();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Reset'),
                  ),
                ],
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data barang',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          resetPagination();
                          setState(() => _isLoading = true);
                          await loadData();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildBarangCard(context, item, authProvider);
                          },
                        ),
                      ),
          ),
          
          // Pagination controls
          buildPaginationControls(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => _showBarangForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Barang'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBarangCard(BuildContext context, Barang barang, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final isLowStock = barang.stok < 10;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isLowStock ? Colors.orange.withOpacity(0.3) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _showBarangForm(context, barang: barang),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Icon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barang.namaBarang,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          barang.idBarang,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions menu
                  if (authProvider.canDeleteData())
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Hapus', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showBarangForm(context, barang: barang);
                        } else if (value == 'delete') {
                          _deleteBarang(context, barang);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Divider
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 8),
              // Info row - compact
              Row(
                children: [
                  if (barang.namaKategori != null) ...[
                    Icon(Icons.category, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      barang.namaKategori!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  if (barang.namaKategori != null && barang.namaMerek != null) ...[
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 8),
                  ],
                  if (barang.namaMerek != null) ...[
                    Icon(Icons.business, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        barang.namaMerek!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Price and stock row - more compact
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.credit_card, size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Rp ${_formatCurrency(barang.hargaJual)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLowStock 
                          ? Colors.orange.withOpacity(0.08)
                          : Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isLowStock 
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLowStock ? Icons.warning : Icons.inventory,
                          size: 14,
                          color: isLowStock ? Colors.orange.shade700 : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${barang.stok} ${barang.satuan}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLowStock ? Colors.orange.shade800 : Colors.blue.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isLowStock) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 12, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Stok menipis!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBarangForm(BuildContext context, {Barang? barang}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => BarangFormDialog(barang: barang),
    );

    if (result == true) {
      resetPagination();
      setState(() => _isLoading = true);
      loadData();
    }
  }

  Future<void> _deleteBarang(BuildContext context, Barang barang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Apakah Anda yakin ingin menghapus ${barang.namaBarang}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteBarang(barang.idBarang);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil dihapus')),
        );
        resetPagination();
        setState(() => _isLoading = true);
        loadData();
      }
    }
  }

  void _showKategoriFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Semua Kategori'),
            leading: const Icon(Icons.category),
            selected: _filterKategoriId == null,
            onTap: () {
              setState(() => _filterKategoriId = null);
              _onSearchOrFilterChanged();
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ..._kategoriList.map((k) => ListTile(
            title: Text(k.namaKategori),
            leading: const Icon(Icons.label),
            selected: _filterKategoriId == k.idKategori,
            onTap: () {
              setState(() => _filterKategoriId = k.idKategori);
              _onSearchOrFilterChanged();
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  void _showMerekFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Semua Merek'),
            leading: const Icon(Icons.business),
            selected: _filterMerekId == null,
            onTap: () {
              setState(() => _filterMerekId = null);
              _onSearchOrFilterChanged();
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ..._merekList.map((m) => ListTile(
            title: Text(m.namaMerek),
            leading: const Icon(Icons.label),
            selected: _filterMerekId == m.idMerek.toString(),
            onTap: () {
              setState(() => _filterMerekId = m.idMerek.toString());
              _onSearchOrFilterChanged();
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

class BarangFormDialog extends StatefulWidget {
  final Barang? barang;

  const BarangFormDialog({super.key, this.barang});

  @override
  State<BarangFormDialog> createState() => _BarangFormDialogState();
}

class _BarangFormDialogState extends State<BarangFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _namaController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _stokController = TextEditingController();
  final _satuanController = TextEditingController();
  
  List<Kategori> _kategoriList = [];
  List<Merek> _merekList = [];
  int? _selectedKategoriId;
  String? _selectedMerekId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadKategori();
    _loadMerek();
    
    if (widget.barang != null) {
      _idController.text = widget.barang!.idBarang;
      _namaController.text = widget.barang!.namaBarang;
      _hargaBeliController.text = widget.barang!.hargaBeli.toString();
      _hargaJualController.text = widget.barang!.hargaJual.toString();
      _stokController.text = widget.barang!.stok.toString();
      _satuanController.text = widget.barang!.satuan;
      _selectedKategoriId = widget.barang!.idKategori;
      _selectedMerekId = widget.barang!.idMerek;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _namaController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _stokController.dispose();
    _satuanController.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    final data = await DatabaseHelper.instance.getAllKategori();
    setState(() => _kategoriList = data);
  }

  Future<void> _loadMerek() async {
    final data = await DatabaseHelper.instance.getAllMerek();
    setState(() => _merekList = data);
  }

  Future<void> _scanBarcodeForId() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _idController.text = result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final barang = Barang(
      idBarang: _idController.text.trim(),
      namaBarang: _namaController.text.trim(),
      idKategori: _selectedKategoriId!,
      idMerek: _selectedMerekId,
      hargaBeli: double.parse(_hargaBeliController.text),
      hargaJual: double.parse(_hargaJualController.text),
      stok: widget.barang?.stok ?? int.parse(_stokController.text),
      satuan: _satuanController.text.trim(),
      addedBy: authProvider.currentUser?.username ?? '',
      createdAt: widget.barang?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.barang == null) {
        await DatabaseHelper.instance.insertBarang(barang);
      } else {
        await DatabaseHelper.instance.updateBarang(barang);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.barang == null
                ? 'Barang berhasil ditambahkan'
                : 'Barang berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.barang == null ? 'Tambah Barang' : 'Edit Barang'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'ID Barang / Barcode',
                  suffixIcon: widget.barang == null
                      ? IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _scanBarcodeForId,
                          tooltip: 'Scan Barcode',
                        )
                      : null,
                ),
                enabled: widget.barang == null,
                validator: (v) => v!.isEmpty ? 'ID tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedKategoriId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: _kategoriList.map((k) {
                  return DropdownMenuItem(
                    value: k.idKategori,
                    child: Text(k.namaKategori),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedKategoriId = value),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedMerekId,
                decoration: const InputDecoration(labelText: 'Merek (Optional)'),
                items: _merekList.map((m) {
                  return DropdownMenuItem(
                    value: m.idMerek.toString(),
                    child: Text(m.namaMerek),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedMerekId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hargaBeliController,
                decoration: const InputDecoration(labelText: 'Harga Beli'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Harga beli tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hargaJualController,
                decoration: const InputDecoration(labelText: 'Harga Jual'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Harga jual tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              if (widget.barang == null)
                TextFormField(
                  controller: _stokController,
                  decoration: const InputDecoration(labelText: 'Stok Awal'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Stok tidak boleh kosong' : null,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _satuanController,
                decoration: const InputDecoration(labelText: 'Satuan'),
                validator: (v) => v!.isEmpty ? 'Satuan tidak boleh kosong' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
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
