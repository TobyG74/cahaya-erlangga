class Gudang {
  final String idGudang;
  final String namaGudang;
  final String? lokasi;
  final String? idKepalaGudang;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? namaKepalaGudang;

  Gudang({
    required this.idGudang,
    required this.namaGudang,
    this.lokasi,
    this.idKepalaGudang,
    required this.createdAt,
    required this.updatedAt,
    this.namaKepalaGudang,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_gudang': idGudang,
      'nama_gudang': namaGudang,
      'lokasi': lokasi,
      'id_kepala_gudang': idKepalaGudang,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Gudang.fromMap(Map<String, dynamic> map) {
    return Gudang(
      idGudang: map['id_gudang'],
      namaGudang: map['nama_gudang'],
      lokasi: map['lokasi'],
      idKepalaGudang: map['id_kepala_gudang'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      namaKepalaGudang: map['nama_kepala_gudang'],
    );
  }

  Gudang copyWith({
    String? idGudang,
    String? namaGudang,
    String? lokasi,
    String? idKepalaGudang,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? namaKepalaGudang,
  }) {
    return Gudang(
      idGudang: idGudang ?? this.idGudang,
      namaGudang: namaGudang ?? this.namaGudang,
      lokasi: lokasi ?? this.lokasi,
      idKepalaGudang: idKepalaGudang ?? this.idKepalaGudang,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      namaKepalaGudang: namaKepalaGudang ?? this.namaKepalaGudang,
    );
  }
}
