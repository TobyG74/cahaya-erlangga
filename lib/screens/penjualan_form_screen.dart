import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/penjualan.dart';
import '../models/pelanggan.dart';
import '../models/barang.dart';
import '../services/database_helper.dart';

class PenjualanFormScreen extends StatefulWidget {
  const PenjualanFormScreen({super.key});

  @override
  State<PenjualanFormScreen> createState() => _PenjualanFormScreenState();
}

class _PenjualanFormScreenState extends State<PenjualanFormScreen> {
  final _dbHelper = DatabaseHelper.instance;
  
  // Data
  List<Pelanggan> _pelangganList = [];
  List<Barang> _barangList = [];
  List<CartItem> _cartItems = [];
  
  // Controllers
  final _pelangganController = TextEditingController();
  final _searchBarangController = TextEditingController();
  
  // State
  String? _selectedPelangganId;
  DateTime _tanggalPenjualan = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPelangganUmum = true;
  
  @override
  void initState() {
    super.initState();
    _pelangganController.text = 'Pelanggan Umum';
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pelanggan = await _dbHelper.getAllPelanggan();
      final barang = await _dbHelper.getAllBarang();
      
      setState(() {
        _pelangganList = pelanggan;
        _barangList = barang.where((b) => b.stok > 0).toList(); // Only show items with stock
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _addToCart(Barang barang, int quantity) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.barang.idBarang == barang.idBarang);
      
      if (existingIndex >= 0) {
        // Update quantity
        final newQuantity = _cartItems[existingIndex].quantity + quantity;
        if (newQuantity <= barang.stok) {
          _cartItems[existingIndex] = CartItem(
            barang: barang,
            quantity: newQuantity,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stok tidak cukup! Tersedia: ${barang.stok}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Add new item
        if (quantity <= barang.stok) {
          _cartItems.add(CartItem(barang: barang, quantity: quantity));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stok tidak cukup! Tersedia: ${barang.stok}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateCartItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(index);
      return;
    }

    final item = _cartItems[index];
    if (newQuantity <= item.barang.stok) {
      setState(() {
        _cartItems[index] = CartItem(
          barang: item.barang,
          quantity: newQuantity,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok tidak cukup! Tersedia: ${item.barang.stok}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateTotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _showAddPelangganDialog() async {
    final namaPelangganController = TextEditingController();
    final noTelpController = TextEditingController();
    final alamatController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Pelanggan Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaPelangganController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pelanggan *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noTelpController,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaPelangganController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama pelanggan harus diisi')),
                );
                return;
              }

              final pelanggan = Pelanggan(
                idPelanggan: 'PLG${DateTime.now().millisecondsSinceEpoch}',
                namaPelanggan: namaPelangganController.text.trim(),
                noTelp: noTelpController.text.trim().isEmpty ? null : noTelpController.text.trim(),
                alamat: alamatController.text.trim().isEmpty ? null : alamatController.text.trim(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                await _dbHelper.insertPelanggan(pelanggan);
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadData();
      // Auto-select the newly added pelanggan
      if (_pelangganList.isNotEmpty) {
        final lastPelanggan = _pelangganList.last;
        setState(() {
          _selectedPelangganId = lastPelanggan.idPelanggan;
          _pelangganController.text = lastPelanggan.namaPelanggan;
          _isPelangganUmum = false;
        });
      }
    }
  }

  Future<void> _showAddItemDialog() async {
    Barang? selectedBarang;
    int quantity = 1;
    final quantityController = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search barang
                Autocomplete<Barang>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _barangList;
                    }
                    return _barangList.where((Barang barang) {
                      return barang.namaBarang
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()) ||
                          barang.idBarang.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  displayStringForOption: (Barang barang) => 
                      '${barang.namaBarang} (Stok: ${barang.stok})',
                  onSelected: (Barang barang) {
                    setDialogState(() {
                      selectedBarang = barang;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Cari Barang',
                        hintText: 'Ketik nama atau kode barang...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 300,
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
                                subtitle: Text(
                                  'Kode: ${barang.idBarang} | Stok: ${barang.stok} | ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(barang.hargaJual)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onTap: () => onSelected(barang),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (selectedBarang != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedBarang!.namaBarang,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Stok: ${selectedBarang!.stok} ${selectedBarang!.satuan}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Harga Satuan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(selectedBarang!.hargaJual),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: 'Jumlah',
                      border: const OutlineInputBorder(),
                      suffixText: selectedBarang!.satuan,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setDialogState(() {
                        quantity = int.tryParse(value) ?? 1;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(selectedBarang!.hargaJual * quantity),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: selectedBarang == null
                  ? null
                  : () {
                      if (quantity <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Jumlah harus lebih dari 0')),
                        );
                        return;
                      }
                      _addToCart(selectedBarang!, quantity);
                      Navigator.pop(context);
                    },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalPenjualan,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _tanggalPenjualan) {
      setState(() {
        _tanggalPenjualan = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 item!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final penjualan = Penjualan(
      idPenjualan: 'PJ${DateTime.now().millisecondsSinceEpoch}',
      tanggalPenjualan: _tanggalPenjualan,
      idPelanggan: _selectedPelangganId,
      totalHarga: _calculateTotal(),
      updatedAt: DateTime.now(),
    );

    final details = _cartItems.map((item) => PenjualanDetail(
      idBarang: item.barang.idBarang,
      namaBarang: item.barang.namaBarang,
      jumlah: item.quantity,
      harga: item.barang.hargaJual,
      subtotal: item.subtotal,
    )).toList();

    try {
      await _dbHelper.insertPenjualan(penjualan, details);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi penjualan berhasil disimpan'),
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _pelangganController.dispose();
    _searchBarangController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Penjualan Baru'),
        actions: [
          if (_cartItems.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Badge(
                  label: Text('${_cartItems.length}'),
                  child: const Icon(Icons.shopping_cart),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Column(
                    children: [
                      // Pelanggan
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _isPelangganUmum,
                                      onChanged: (value) {
                                        setState(() {
                                          _isPelangganUmum = value ?? true;
                                          if (_isPelangganUmum) {
                                            _selectedPelangganId = null;
                                            _pelangganController.text = 'Pelanggan Umum';
                                          } else {
                                            _pelangganController.clear();
                                          }
                                        });
                                      },
                                    ),
                                    const Expanded(child: Text('Pelanggan Umum')),
                                  ],
                                ),
                                if (!_isPelangganUmum) ...[
                                  const SizedBox(height: 8),
                                  Autocomplete<Pelanggan>(
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return _pelangganList;
                                      }
                                      return _pelangganList.where((Pelanggan pelanggan) {
                                        return pelanggan.namaPelanggan
                                            .toLowerCase()
                                            .contains(textEditingValue.text.toLowerCase()) ||
                                            (pelanggan.noTelp?.contains(textEditingValue.text) ?? false);
                                      });
                                    },
                                    displayStringForOption: (Pelanggan pelanggan) => pelanggan.namaPelanggan,
                                    onSelected: (Pelanggan pelanggan) {
                                      setState(() {
                                        _selectedPelangganId = pelanggan.idPelanggan;
                                        _pelangganController.text = pelanggan.namaPelanggan;
                                      });
                                    },
                                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                      if (_pelangganController.text.isNotEmpty && controller.text.isEmpty) {
                                        controller.text = _pelangganController.text;
                                      }
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(
                                          labelText: 'Pilih Pelanggan',
                                          hintText: 'Ketik nama...',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!_isPelangganUmum) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.person_add),
                              onPressed: _showAddPelangganDialog,
                              tooltip: 'Tambah Pelanggan',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Tanggal
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd MMMM yyyy').format(_tanggalPenjualan),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Cart Items
                Expanded(
                  child: _cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Keranjang Kosong',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tambahkan item menggunakan tombol + di bawah',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.barang.namaBarang,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                'Harga: ',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                NumberFormat.currency(
                                                  locale: 'id',
                                                  symbol: 'Rp ',
                                                  decimalDigits: 0,
                                                ).format(item.barang.hargaJual),
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                ' × ${item.quantity}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text(
                                                'Subtotal: ',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                NumberFormat.currency(
                                                  locale: 'id',
                                                  symbol: 'Rp ',
                                                  decimalDigits: 0,
                                                ).format(item.subtotal),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline),
                                              onPressed: () => _updateCartItemQuantity(
                                                index,
                                                item.quantity - 1,
                                              ),
                                              color: Colors.red,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline),
                                              onPressed: () => _updateCartItemQuantity(
                                                index,
                                                item.quantity + 1,
                                              ),
                                              color: Colors.green,
                                            ),
                                          ],
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _removeFromCart(index),
                                          icon: const Icon(Icons.delete, size: 18),
                                          label: const Text('Hapus'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Total & Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(_calculateTotal()),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showAddItemDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah Item'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isSaving ? null : _saveTransaction,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check),
                                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class CartItem {
  final Barang barang;
  final int quantity;

  CartItem({
    required this.barang,
    required this.quantity,
  });

  double get subtotal => barang.hargaJual * quantity;
}
