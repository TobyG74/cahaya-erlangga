class BarangMasuk {
  final String idMasuk;
  final String idBarang;
  final String idPemasok;
  final DateTime tanggalMasuk;
  final int jumlah;
  final double hargaMasuk;
  final String idGudang;
  final DateTime updatedAt;

  String? namaBarang;
  String? namaPemasok;
  String? namaGudang;

  BarangMasuk({
    required this.idMasuk,
    required this.idBarang,
    required this.idPemasok,
    required this.tanggalMasuk,
    required this.jumlah,
    required this.hargaMasuk,
    required this.idGudang,
    required this.updatedAt,
    this.namaBarang,
    this.namaPemasok,
    this.namaGudang,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_masuk': idMasuk,
      'id_barang': idBarang,
      'id_pemasok': idPemasok,
      'tanggal_masuk': tanggalMasuk.toIso8601String(),
      'jumlah': jumlah,
      'harga_masuk': hargaMasuk,
      'id_gudang': idGudang,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BarangMasuk.fromMap(Map<String, dynamic> map) {
    return BarangMasuk(
      idMasuk: map['id_masuk'],
      idBarang: map['id_barang'],
      idPemasok: map['id_pemasok'],
      tanggalMasuk: DateTime.parse(map['tanggal_masuk']),
      jumlah: map['jumlah'],
      hargaMasuk: (map['harga_masuk'] as num).toDouble(),
      idGudang: map['id_gudang'],
      updatedAt: DateTime.parse(map['updated_at']),
      namaBarang: map['nama_barang'],
      namaPemasok: map['nama_pemasok'],
      namaGudang: map['nama_gudang'],
    );
  }

  BarangMasuk copyWith({
    String? idMasuk,
    String? idBarang,
    String? idPemasok,
    DateTime? tanggalMasuk,
    int? jumlah,
    double? hargaMasuk,
    String? idGudang,
    DateTime? updatedAt,
    String? namaBarang,
    String? namaPemasok,
    String? namaGudang,
  }) {
    return BarangMasuk(
      idMasuk: idMasuk ?? this.idMasuk,
      idBarang: idBarang ?? this.idBarang,
      idPemasok: idPemasok ?? this.idPemasok,
      tanggalMasuk: tanggalMasuk ?? this.tanggalMasuk,
      jumlah: jumlah ?? this.jumlah,
      hargaMasuk: hargaMasuk ?? this.hargaMasuk,
      idGudang: idGudang ?? this.idGudang,
      updatedAt: updatedAt ?? this.updatedAt,
      namaBarang: namaBarang ?? this.namaBarang,
      namaPemasok: namaPemasok ?? this.namaPemasok,
      namaGudang: namaGudang ?? this.namaGudang,
    );
  }
}
