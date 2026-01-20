import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/merek.dart';
import '../utils/pagination_helper.dart';

class MerekScreen extends StatefulWidget {
  const MerekScreen({super.key});

  @override
  State<MerekScreen> createState() => _MerekScreenState();
}

class _MerekScreenState extends State<MerekScreen> with PaginationMixin<MerekScreen, Merek> {
  final _dbHelper = DatabaseHelper.instance;
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
      final result = await _dbHelper.getMerekPaginated(
        limit: limit,
        offset: offset,
        searchQuery: _searchController.text.trim().isEmpty 
          ? null 
          : _searchController.text.trim(),
      );
      
      setState(() {
        items = result['items'] as List<Merek>;
        totalItems = result['totalCount'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        items = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    resetPagination();
    setState(() => _isLoading = true);
    loadData();
  }

  void _showMerekDialog({Merek? merek}) {
    final isEdit = merek != null;
    final kodeMerekController = TextEditingController(text: merek?.kodeMerek ?? '');
    final namaMerekController = TextEditingController(text: merek?.namaMerek ?? '');
    final deskripsiController = TextEditingController(text: merek?.deskripsi ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Merek' : 'Tambah Merek'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: kodeMerekController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Merek',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Kode merek harus diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: namaMerekController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Merek',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Nama merek harus diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: deskripsiController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final now = DateTime.now().toIso8601String();
                  final newMerek = Merek(
                    idMerek: merek?.idMerek,
                    kodeMerek: kodeMerekController.text,
                    namaMerek: namaMerekController.text,
                    deskripsi: deskripsiController.text.isEmpty
                        ? null
                        : deskripsiController.text,
                    createdAt: merek?.createdAt ?? now,
                    updatedAt: now,
                  );

                  if (isEdit) {
                    await _dbHelper.updateMerek(newMerek);
                  } else {
                    await _dbHelper.insertMerek(newMerek);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    resetPagination();
                    setState(() => _isLoading = true);
                    loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit
                            ? 'Merek berhasil diupdate'
                            : 'Merek berhasil ditambahkan'),
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
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteMerek(Merek merek) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus merek "${merek.namaMerek}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              await _dbHelper.deleteMerek(merek.idMerek!);
              if (mounted) {
                Navigator.pop(context);
                resetPagination();
                setState(() => _isLoading = true);
                loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Merek berhasil dihapus')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Merek'),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => _showMerekDialog(),
          child: const Icon(Icons.add),
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
                hintText: 'Cari merek...',
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
                        child: Text('Belum ada data merek'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final merek = items[index];
                          final theme = Theme.of(context);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: () => _showMerekDialog(merek: merek),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
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
                                        Icons.label,
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
                                            merek.namaMerek,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            merek.kodeMerek,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontFamily: 'monospace',
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          if (merek.deskripsi != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              merek.deskripsi!,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
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
                                          _showMerekDialog(merek: merek);
                                        } else if (value == 'delete') {
                                          _deleteMerek(merek);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          buildPaginationControls(),
        ],
      ),
    );
  }
}
