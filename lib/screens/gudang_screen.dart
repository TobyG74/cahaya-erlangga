import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import '../models/gudang.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../utils/pagination_helper.dart';

class GudangScreen extends StatefulWidget {
  const GudangScreen({super.key});

  @override
  State<GudangScreen> createState() => _GudangScreenState();
}

class _GudangScreenState extends State<GudangScreen> with PaginationMixin<GudangScreen, Gudang> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    loadData();
  }

  void _onSearchChanged() {
    resetPagination();
    loadData();
  }

  @override
  Future<void> loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await _dbHelper.getGudangPaginated(
        limit: limit,
        offset: offset,
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      
      setState(() {
        items = result['items'] as List<Gudang>;
        totalItems = result['totalCount'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showGudangForm(BuildContext context, {Gudang? gudang}) {
    showDialog(
      context: context,
      builder: (context) => _GudangFormDialog(
        gudang: gudang,
        onSaved: () {
          resetPagination();
          loadData();
        },
      ),
    );
  }

  Future<void> _deleteGudang(BuildContext context, Gudang gudang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus gudang "${gudang.namaGudang}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteGudang(gudang.idGudang);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gudang berhasil dihapus')),
        );
        resetPagination();
        loadData();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Gudang'),
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => _showGudangForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Gudang'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari gudang...',
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) => _onSearchChanged(),
            ),
          ),
          Expanded(
            child: _isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(
                        child: Text('Belum ada data gudang'),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          resetPagination();
                          await loadData();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final gudang = items[index];
                            return _buildGudangCard(context, gudang, authProvider);
                          },
                        ),
                      ),
          ),
          buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildGudangCard(BuildContext context, Gudang gudang, AuthProvider authProvider) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showGudangForm(context, gudang: gudang),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                      Icons.warehouse,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gudang.namaGudang,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gudang.idGudang,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          _showGudangForm(context, gudang: gudang);
                        } else if (value == 'delete') {
                          _deleteGudang(context, gudang);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (gudang.lokasi != null)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        gudang.lokasi!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (gudang.namaKepalaGudang != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kepala: ${gudang.namaKepalaGudang}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GudangFormDialog extends StatefulWidget {
  final Gudang? gudang;
  final VoidCallback onSaved;

  const _GudangFormDialog({
    this.gudang,
    required this.onSaved,
  });

  @override
  State<_GudangFormDialog> createState() => _GudangFormDialogState();
}

class _GudangFormDialogState extends State<_GudangFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  late TextEditingController _idController;
  late TextEditingController _namaController;
  late TextEditingController _lokasiController;
  
  String? _selectedKepalaGudangId;
  List<User> _userList = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.gudang?.idGudang);
    _namaController = TextEditingController(text: widget.gudang?.namaGudang);
    _lokasiController = TextEditingController(text: widget.gudang?.lokasi);
    _selectedKepalaGudangId = widget.gudang?.idKepalaGudang;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _dbHelper.getAllUsers();
    setState(() {
      _userList = users;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().toIso8601String();
      final gudang = Gudang(
        idGudang: _idController.text,
        namaGudang: _namaController.text,
        lokasi: _lokasiController.text.isEmpty ? null : _lokasiController.text,
        idKepalaGudang: _selectedKepalaGudangId,
        createdAt: widget.gudang?.createdAt ?? DateTime.parse(now),
        updatedAt: DateTime.parse(now),
      );

      if (widget.gudang != null) {
        await _dbHelper.updateGudang(gudang);
      } else {
        await _dbHelper.insertGudang(gudang);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.gudang != null
                ? 'Gudang berhasil diupdate'
                : 'Gudang berhasil ditambahkan'),
          ),
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
    _idController.dispose();
    _namaController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.gudang == null ? 'Tambah Gudang' : 'Edit Gudang'),
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
                      TextFormField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: 'ID Gudang',
                          border: OutlineInputBorder(),
                        ),
                        enabled: widget.gudang == null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ID gudang harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Gudang',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama gudang harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lokasiController,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedKepalaGudangId,
                        decoration: const InputDecoration(
                          labelText: 'Kepala Gudang (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Pilih Kepala Gudang'),
                          ),
                          ..._userList.map((user) {
                            return DropdownMenuItem(
                              value: user.idUser,
                              child: Text(user.username),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedKepalaGudangId = value);
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
        FilledButton(
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
