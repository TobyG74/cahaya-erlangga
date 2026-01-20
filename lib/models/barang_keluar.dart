class BarangKeluar {
  final String idKeluar;
  final String idBarang;
  final String? idPelanggan;
  final DateTime tanggalKeluar;
  final int jumlah;
  final double hargaKeluar;
  final String idGudang;
  final DateTime updatedAt;

  String? namaBarang;
  String? namaPelanggan;
  String? namaGudang;

  BarangKeluar({
    required this.idKeluar,
    required this.idBarang,
    this.idPelanggan,
    required this.tanggalKeluar,
    required this.jumlah,
    required this.hargaKeluar,
    required this.idGudang,
    required this.updatedAt,
    this.namaBarang,
    this.namaPelanggan,
    this.namaGudang,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_keluar': idKeluar,
      'id_barang': idBarang,
      'id_pelanggan': idPelanggan,
      'tanggal_keluar': tanggalKeluar.toIso8601String(),
      'jumlah': jumlah,
      'harga_keluar': hargaKeluar,
      'id_gudang': idGudang,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BarangKeluar.fromMap(Map<String, dynamic> map) {
    return BarangKeluar(
      idKeluar: map['id_keluar'],
      idBarang: map['id_barang'],
      idPelanggan: map['id_pelanggan'],
      tanggalKeluar: DateTime.parse(map['tanggal_keluar']),
      jumlah: map['jumlah'],
      hargaKeluar: (map['harga_keluar'] as num).toDouble(),
      idGudang: map['id_gudang'],
      updatedAt: DateTime.parse(map['updated_at']),
      namaBarang: map['nama_barang'],
      namaPelanggan: map['nama_pelanggan'],
      namaGudang: map['nama_gudang'],
    );
  }

  BarangKeluar copyWith({
    String? idKeluar,
    String? idBarang,
    String? idPelanggan,
    DateTime? tanggalKeluar,
    int? jumlah,
    double? hargaKeluar,
    String? idGudang,
    DateTime? updatedAt,
    String? namaBarang,
    String? namaPelanggan,
    String? namaGudang,
  }) {
    return BarangKeluar(
      idKeluar: idKeluar ?? this.idKeluar,
      idBarang: idBarang ?? this.idBarang,
      idPelanggan: idPelanggan ?? this.idPelanggan,
      tanggalKeluar: tanggalKeluar ?? this.tanggalKeluar,
      jumlah: jumlah ?? this.jumlah,
      hargaKeluar: hargaKeluar ?? this.hargaKeluar,
      idGudang: idGudang ?? this.idGudang,
      updatedAt: updatedAt ?? this.updatedAt,
      namaBarang: namaBarang ?? this.namaBarang,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      namaGudang: namaGudang ?? this.namaGudang,
    );
  }
}
