class Pelanggan {
  final String idPelanggan;
  final String namaPelanggan;
  final String? alamat;
  final String? noTelp;
  final String? email;
  final String? jenisKelamin; 
  final DateTime createdAt;
  final DateTime updatedAt;

  Pelanggan({
    required this.idPelanggan,
    required this.namaPelanggan,
    this.alamat,
    this.noTelp,
    this.email,
    this.jenisKelamin,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_pelanggan': idPelanggan,
      'nama_pelanggan': namaPelanggan,
      'alamat': alamat,
      'no_telp': noTelp,
      'email': email,
      'jenis_kelamin': jenisKelamin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Pelanggan.fromMap(Map<String, dynamic> map) {
    return Pelanggan(
      idPelanggan: map['id_pelanggan'],
      namaPelanggan: map['nama_pelanggan'],
      alamat: map['alamat'],
      noTelp: map['no_telp'],
      email: map['email'],
      jenisKelamin: map['jenis_kelamin'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Pelanggan copyWith({
    String? idPelanggan,
    String? namaPelanggan,
    String? alamat,
    String? noTelp,
    String? email,
    String? jenisKelamin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pelanggan(
      idPelanggan: idPelanggan ?? this.idPelanggan,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      alamat: alamat ?? this.alamat,
      noTelp: noTelp ?? this.noTelp,
      email: email ?? this.email,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
