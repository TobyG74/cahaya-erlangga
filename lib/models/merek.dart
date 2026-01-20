class Merek {
  final int? idMerek;
  final String kodeMerek;
  final String namaMerek;
  final String? deskripsi;
  final String createdAt;
  final String updatedAt;

  Merek({
    this.idMerek,
    required this.kodeMerek,
    required this.namaMerek,
    this.deskripsi,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_merek': idMerek,
      'kode_merek': kodeMerek,
      'nama_merek': namaMerek,
      'deskripsi': deskripsi,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Merek.fromMap(Map<String, dynamic> map) {
    return Merek(
      idMerek: map['id_merek'] as int?,
      kodeMerek: map['kode_merek'] as String,
      namaMerek: map['nama_merek'] as String,
      deskripsi: map['deskripsi'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Merek copyWith({
    int? idMerek,
    String? kodeMerek,
    String? namaMerek,
    String? deskripsi,
    String? createdAt,
    String? updatedAt,
  }) {
    return Merek(
      idMerek: idMerek ?? this.idMerek,
      kodeMerek: kodeMerek ?? this.kodeMerek,
      namaMerek: namaMerek ?? this.namaMerek,
      deskripsi: deskripsi ?? this.deskripsi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
