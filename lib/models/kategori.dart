class Kategori {
  final int? idKategori;
  final String kodeKategori;
  final String namaKategori;
  final String? deskripsi;
  final DateTime createdAt;
  final DateTime updatedAt;

  Kategori({
    this.idKategori,
    required this.kodeKategori,
    required this.namaKategori,
    this.deskripsi,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'kode_kategori': kodeKategori,
      'nama_kategori': namaKategori,
      'deskripsi': deskripsi,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    if (idKategori != null) {
      map['id_kategori'] = idKategori;
    }
    
    return map;
  }

  factory Kategori.fromMap(Map<String, dynamic> map) {
    return Kategori(
      idKategori: map['id_kategori'],
      kodeKategori: map['kode_kategori'],
      namaKategori: map['nama_kategori'],
      deskripsi: map['deskripsi'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Kategori copyWith({
    int? idKategori,
    String? kodeKategori,
    String? namaKategori,
    String? deskripsi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Kategori(
      idKategori: idKategori ?? this.idKategori,
      kodeKategori: kodeKategori ?? this.kodeKategori,
      namaKategori: namaKategori ?? this.namaKategori,
      deskripsi: deskripsi ?? this.deskripsi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
