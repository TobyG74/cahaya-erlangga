class Pemasok {
  final String idPemasok;
  final String namaPemasok;
  final String? alamat;
  final String? noTelp;
  final String? kontakPerson;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pemasok({
    required this.idPemasok,
    required this.namaPemasok,
    this.alamat,
    this.noTelp,
    this.kontakPerson,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_pemasok': idPemasok,
      'nama_pemasok': namaPemasok,
      'alamat': alamat,
      'no_telp': noTelp,
      'kontak_person': kontakPerson,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Pemasok.fromMap(Map<String, dynamic> map) {
    return Pemasok(
      idPemasok: map['id_pemasok'],
      namaPemasok: map['nama_pemasok'],
      alamat: map['alamat'],
      noTelp: map['no_telp'],
      kontakPerson: map['kontak_person'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Pemasok copyWith({
    String? idPemasok,
    String? namaPemasok,
    String? alamat,
    String? noTelp,
    String? kontakPerson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pemasok(
      idPemasok: idPemasok ?? this.idPemasok,
      namaPemasok: namaPemasok ?? this.namaPemasok,
      alamat: alamat ?? this.alamat,
      noTelp: noTelp ?? this.noTelp,
      kontakPerson: kontakPerson ?? this.kontakPerson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
