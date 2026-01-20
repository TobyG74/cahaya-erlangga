class Penjualan {
  final String idPenjualan;
  final DateTime tanggalPenjualan;
  final String? idPelanggan;
  final double totalHarga;
  final DateTime updatedAt;

  String? namaPelanggan;
  List<PenjualanDetail>? details;

  Penjualan({
    required this.idPenjualan,
    required this.tanggalPenjualan,
    this.idPelanggan,
    required this.totalHarga,
    required this.updatedAt,
    this.namaPelanggan,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_penjualan': idPenjualan,
      'tanggal_penjualan': tanggalPenjualan.toIso8601String(),
      'id_pelanggan': idPelanggan,
      'total_harga': totalHarga,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Penjualan.fromMap(Map<String, dynamic> map) {
    return Penjualan(
      idPenjualan: map['id_penjualan'],
      tanggalPenjualan: DateTime.parse(map['tanggal_penjualan']),
      idPelanggan: map['id_pelanggan'],
      totalHarga: (map['total_harga'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at']),
      namaPelanggan: map['nama_pelanggan'],
    );
  }

  Penjualan copyWith({
    String? idPenjualan,
    DateTime? tanggalPenjualan,
    String? idPelanggan,
    double? totalHarga,
    DateTime? updatedAt,
    String? namaPelanggan,
    List<PenjualanDetail>? details,
  }) {
    return Penjualan(
      idPenjualan: idPenjualan ?? this.idPenjualan,
      tanggalPenjualan: tanggalPenjualan ?? this.tanggalPenjualan,
      idPelanggan: idPelanggan ?? this.idPelanggan,
      totalHarga: totalHarga ?? this.totalHarga,
      updatedAt: updatedAt ?? this.updatedAt,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      details: details ?? this.details,
    );
  }
}

class PenjualanDetail {
  final String idBarang;
  final String namaBarang;
  final int jumlah;
  final double harga;
  final double subtotal;

  PenjualanDetail({
    required this.idBarang,
    required this.namaBarang,
    required this.jumlah,
    required this.harga,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_barang': idBarang,
      'nama_barang': namaBarang,
      'jumlah': jumlah,
      'harga': harga,
      'subtotal': subtotal,
    };
  }

  factory PenjualanDetail.fromMap(Map<String, dynamic> map) {
    return PenjualanDetail(
      idBarang: map['id_barang'],
      namaBarang: map['nama_barang'],
      jumlah: map['jumlah'],
      harga: (map['harga'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}
