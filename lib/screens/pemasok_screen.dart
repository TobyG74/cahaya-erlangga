import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/pemasok.dart';
import '../providers/auth_provider.dart';
import '../utils/pagination_helper.dart';
import 'package:provider/provider.dart';

class PemasokScreen extends StatefulWidget {
  const PemasokScreen({super.key});

  @override
  State<PemasokScreen> createState() => _PemasokScreenState();
}

class _PemasokScreenState extends State<PemasokScreen> with PaginationMixin<PemasokScreen, Pemasok> {
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      final result = await DatabaseHelper.instance.getPemasokPaginated(
        limit: limit,
        offset: offset,
        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      
      setState(() {
        items = result['items'] as List<Pemasok>;
        totalItems = result['totalCount'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    resetPagination();
    setState(() => _isLoading = true);
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pemasok'),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pemasok...',
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
              ),
              onChanged: (v) => _onSearchChanged(),
            ),
          ),

          Expanded(
            child: _isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data pemasok',
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
                            return _buildPemasokCard(context, item, authProvider);
                          },
                        ),
                      ),
          ),
          
          buildPaginationControls(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => _showPemasokForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Pemasok'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPemasokCard(BuildContext context, Pemasok pemasok, AuthProvider authProvider) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showPemasokForm(context, pemasok: pemasok),
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
                      Icons.business_center,
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
                          pemasok.namaPemasok,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pemasok.idPemasok,
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
                          _showPemasokForm(context, pemasok: pemasok);
                        } else if (value == 'delete') {
                          _deletePemasok(context, pemasok);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (pemasok.noTelp != null)
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pemasok.noTelp!,
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
              if (pemasok.kontakPerson != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pemasok.kontakPerson!,
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
              if (pemasok.alamat != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pemasok.alamat!,
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

  Future<void> _showPemasokForm(BuildContext context, {Pemasok? pemasok}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => PemasokFormDialog(pemasok: pemasok),
    );

    if (result == true) {
      resetPagination();
      setState(() => _isLoading = true);
      loadData();
    }
  }

  Future<void> _deletePemasok(BuildContext context, Pemasok pemasok) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pemasok'),
        content: Text('Apakah Anda yakin ingin menghapus ${pemasok.namaPemasok}?'),
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
      await DatabaseHelper.instance.deletePemasok(pemasok.idPemasok);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pemasok.namaPemasok} berhasil dihapus')),
        );
        resetPagination();
        setState(() => _isLoading = true);
        loadData();
      }
    }
  }
}

class PemasokFormDialog extends StatefulWidget {
  final Pemasok? pemasok;
  const PemasokFormDialog({super.key, this.pemasok});

  @override
  State<PemasokFormDialog> createState() => _PemasokFormDialogState();
}

class _PemasokFormDialogState extends State<PemasokFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _noTelpController = TextEditingController();
  final _kontakPersonController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.pemasok != null) {
      _namaController.text = widget.pemasok!.namaPemasok;
      _alamatController.text = widget.pemasok!.alamat ?? '';
      _noTelpController.text = widget.pemasok!.noTelp ?? '';
      _kontakPersonController.text = widget.pemasok!.kontakPerson ?? '';
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _noTelpController.dispose();
    _kontakPersonController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final pemasok = Pemasok(
      idPemasok: widget.pemasok?.idPemasok ?? 'PMS${DateTime.now().millisecondsSinceEpoch}',
      namaPemasok: _namaController.text.trim(),
      alamat: _alamatController.text.trim().isEmpty ? null : _alamatController.text.trim(),
      noTelp: _noTelpController.text.trim().isEmpty ? null : _noTelpController.text.trim(),
      kontakPerson: _kontakPersonController.text.trim().isEmpty ? null : _kontakPersonController.text.trim(),
      createdAt: widget.pemasok?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await DatabaseHelper.instance.insertPemasok(pemasok);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.pemasok == null
                ? 'Pemasok berhasil ditambahkan'
                : 'Pemasok berhasil diupdate'),
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.pemasok == null ? 'Tambah Pemasok' : 'Edit Pemasok'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pemasok *',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama pemasok harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noTelpController,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kontakPersonController,
                decoration: const InputDecoration(
                  labelText: 'Kontak Person',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
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
