class Barang {
  final String idBarang;
  final String namaBarang;
  final int idKategori;
  final String? idMerek;
  final double hargaBeli;
  final double hargaJual;
  final int stok;
  final String satuan;
  final String addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? namaKategori;
  String? namaMerek;

  Barang({
    required this.idBarang,
    required this.namaBarang,
    required this.idKategori,
    this.idMerek,
    required this.hargaBeli,
    required this.hargaJual,
    required this.stok,
    required this.satuan,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
    this.namaKategori,
    this.namaMerek,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_barang': idBarang,
      'nama_barang': namaBarang,
      'id_kategori': idKategori,
      'id_merek': idMerek,
      'harga_beli': hargaBeli,
      'harga_jual': hargaJual,
      'stok': stok,
      'satuan': satuan,
      'added_by': addedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Barang.fromMap(Map<String, dynamic> map) {
    return Barang(
      idBarang: map['id_barang'],
      namaBarang: map['nama_barang'],
      idKategori: map['id_kategori'],
      idMerek: map['id_merek'],
      hargaBeli: (map['harga_beli'] as num).toDouble(),
      hargaJual: (map['harga_jual'] as num).toDouble(),
      stok: map['stok'],
      satuan: map['satuan'],
      addedBy: map['added_by'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      namaKategori: map['nama_kategori'],
      namaMerek: map['nama_merek'],
    );
  }

  Barang copyWith({
    String? idBarang,
    String? namaBarang,
    int? idKategori,
    String? idMerek,
    double? hargaBeli,
    double? hargaJual,
    int? stok,
    String? satuan,
    String? addedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? namaKategori,
    String? namaMerek,
  }) {
    return Barang(
      idBarang: idBarang ?? this.idBarang,
      namaBarang: namaBarang ?? this.namaBarang,
      idKategori: idKategori ?? this.idKategori,
      idMerek: idMerek ?? this.idMerek,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      hargaJual: hargaJual ?? this.hargaJual,
      stok: stok ?? this.stok,
      satuan: satuan ?? this.satuan,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      namaKategori: namaKategori ?? this.namaKategori,
      namaMerek: namaMerek ?? this.namaMerek,
    );
  }
}
