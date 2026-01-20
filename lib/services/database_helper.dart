import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/kategori.dart';
import '../models/merek.dart';
import '../models/barang.dart';
import '../models/pemasok.dart';
import '../models/gudang.dart';
import '../models/pelanggan.dart';
import '../models/barang_masuk.dart';
import '../models/barang_keluar.dart';
import '../models/penjualan.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bengkel_v2.db');
    return _database!;
  }

  Future<void> resetDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'bengkel_v2.db');
      await deleteDatabase(path);
      
      _database = await _initDB('bengkel_v2.db');
      
    } catch (e) {
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE users (
        id_user $idType,
        fullname $textType,
        username $textType UNIQUE,
        password $textType,
        role $textType,
        created_at $textType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE kategori (
        id_kategori INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_kategori $textType UNIQUE,
        nama_kategori $textType,
        deskripsi $textTypeNullable,
        created_at $textType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE merek (
        id_merek INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_merek $textType UNIQUE,
        nama_merek $textType,
        deskripsi $textTypeNullable,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // Barang table
    await db.execute('''
      CREATE TABLE barang (
        id_barang $idType,
        nama_barang $textType,
        id_kategori $intType,
        id_merek $textTypeNullable,
        harga_beli $realType,
        harga_jual $realType,
        stok $intType DEFAULT 0,
        satuan $textType,
        added_by $textType,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (id_kategori) REFERENCES kategori (id_kategori),
        FOREIGN KEY (id_merek) REFERENCES merek (id_merek),
        FOREIGN KEY (added_by) REFERENCES users (username)
      )
    ''');

    // Pemasok table
    await db.execute('''
      CREATE TABLE pemasok (
        id_pemasok $idType,
        nama_pemasok $textType,
        alamat $textTypeNullable,
        no_telp $textTypeNullable,
        kontak_person $textTypeNullable,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // Gudang table
    await db.execute('''
      CREATE TABLE gudang (
        id_gudang $idType,
        nama_gudang $textType,
        lokasi $textTypeNullable,
        id_kepala_gudang $textTypeNullable,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (id_kepala_gudang) REFERENCES users (id_user)
      )
    ''');

    // Pelanggan table
    await db.execute('''
      CREATE TABLE pelanggan (
        id_pelanggan $idType,
        nama_pelanggan $textType,
        alamat $textTypeNullable,
        no_telp $textTypeNullable,
        email $textTypeNullable,
        jenis_kelamin $textTypeNullable,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // Barang Masuk table
    await db.execute('''
      CREATE TABLE barang_masuk (
        id_masuk $idType,
        id_barang $textType,
        id_pemasok $textType,
        tanggal_masuk $textType,
        jumlah $intType,
        harga_masuk $realType,
        id_gudang $textType,
        updated_at $textType,
        FOREIGN KEY (id_barang) REFERENCES barang (id_barang),
        FOREIGN KEY (id_pemasok) REFERENCES pemasok (id_pemasok),
        FOREIGN KEY (id_gudang) REFERENCES gudang (id_gudang)
      )
    ''');

    // Barang Keluar table
    await db.execute('''
      CREATE TABLE barang_keluar (
        id_keluar $idType,
        id_barang $textType,
        id_pelanggan $textTypeNullable,
        tanggal_keluar $textType,
        jumlah $intType,
        harga_keluar $realType,
        id_gudang $textType,
        updated_at $textType,
        FOREIGN KEY (id_barang) REFERENCES barang (id_barang),
        FOREIGN KEY (id_pelanggan) REFERENCES pelanggan (id_pelanggan),
        FOREIGN KEY (id_gudang) REFERENCES gudang (id_gudang)
      )
    ''');

    // Penjualan table
    await db.execute('''
      CREATE TABLE penjualan (
        id_penjualan $idType,
        tanggal_penjualan $textType,
        id_pelanggan $textTypeNullable,
        total_harga $realType,
        updated_at $textType,
        FOREIGN KEY (id_pelanggan) REFERENCES pelanggan (id_pelanggan)
      )
    ''');

    // Penjualan Detail table (for cart items)
    await db.execute('''
      CREATE TABLE penjualan_detail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_penjualan $textType,
        id_barang $textType,
        nama_barang $textType,
        jumlah $intType,
        harga $realType,
        subtotal $realType,
        FOREIGN KEY (id_penjualan) REFERENCES penjualan (id_penjualan),
        FOREIGN KEY (id_barang) REFERENCES barang (id_barang)
      )
    ''');

    // Insert default admin user
    await db.insert('users', {
      'id_user': 'admin_001',
      'fullname': 'Administrator',
      'username': 'admin',
      'password': 'admin123',
      'role': 'Admin',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<User?> login(String username, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    
    final existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [user.username],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Username "${user.username}" sudah digunakan');
    }
    
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users', orderBy: 'created_at DESC');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getUsersPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
    String? roleFilter,
  }) async {
    final db = await database;
    
    List<String> conditions = [];
    List<dynamic> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(username LIKE ? OR nama_lengkap LIKE ? OR email LIKE ?)');
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }
    
    if (roleFilter != null && roleFilter.isNotEmpty && roleFilter != 'Semua') {
      conditions.add('role = ?');
      whereArgs.add(roleFilter);
    }
    
    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users $whereClause',
      whereArgs.isNotEmpty ? whereArgs : null,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;
    
    final result = await db.rawQuery('''
      SELECT * FROM users
      $whereClause
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    
    final items = result.map((map) => User.fromMap(map)).toList();
    
    return {
      'items': items,
      'totalCount': totalCount,
    };
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id_user = ?',
      whereArgs: [user.idUser],
    );
  }

  Future<int> deleteUser(String idUser) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id_user = ?',
      whereArgs: [idUser],
    );
  }

  Future<bool> checkUsernameExists(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  Future<int> insertKategori(Kategori kategori) async {
    final db = await database;
    
    final existing = await db.query(
      'kategori',
      where: 'kode_kategori = ?',
      whereArgs: [kategori.kodeKategori],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      throw Exception('Kode kategori "${kategori.kodeKategori}" sudah digunakan');
    }
    
    return await db.insert('kategori', kategori.toMap());
  }

  Future<List<Kategori>> getAllKategori() async {
    final db = await database;
    final result = await db.query('kategori', orderBy: 'nama_kategori ASC');
    return result.map((map) => Kategori.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getKategoriPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'WHERE nama_kategori LIKE ? OR kode_kategori LIKE ?';
      whereArgs = ['%$searchQuery%', '%$searchQuery%'];
    }
    
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM kategori $whereClause',
      whereArgs.isNotEmpty ? whereArgs : null,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;
    
    final result = await db.rawQuery('''
      SELECT * FROM kategori 
      $whereClause
      ORDER BY nama_kategori ASC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    
    final items = result.map((map) => Kategori.fromMap(map)).toList();
    
    return {
      'items': items,
      'totalCount': totalCount,
    };
  }

  Future<int> updateKategori(Kategori kategori) async {
    final db = await database;
    return await db.update(
      'kategori',
      kategori.toMap(),
      where: 'id_kategori = ?',
      whereArgs: [kategori.idKategori],
    );
  }

  Future<int> deleteKategori(int idKategori) async {
    final db = await database;
    return await db.delete(
      'kategori',
      where: 'id_kategori = ?',
      whereArgs: [idKategori],
    );
  }

  Future<int> insertMerek(Merek merek) async {
    final db = await database;
    final existing = await db.query(
      'merek',
      where: 'kode_merek = ?',
      whereArgs: [merek.kodeMerek],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw Exception('Kode merek "${merek.kodeMerek}" sudah digunakan');
    }
    return await db.insert('merek', merek.toMap());
  }

  Future<List<Merek>> getAllMerek() async {
    final db = await database;
    final result = await db.query('merek', orderBy: 'nama_merek ASC');
    return result.map((map) => Merek.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getMerekPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'WHERE nama_merek LIKE ? OR kode_merek LIKE ?';
      whereArgs = ['%$searchQuery%', '%$searchQuery%'];
    }
    
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM merek $whereClause',
      whereArgs.isNotEmpty ? whereArgs : null,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;
    
    final result = await db.rawQuery('''
      SELECT * FROM merek 
      $whereClause
      ORDER BY nama_merek ASC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    
    final items = result.map((map) => Merek.fromMap(map)).toList();
    
    return {
      'items': items,
      'totalCount': totalCount,
    };
  }

  Future<List<Merek>> searchMerek(String query) async {
    final db = await database;
    final result = await db.query(
      'merek',
      where: 'nama_merek LIKE ? OR kode_merek LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nama_merek ASC',
    );
    return result.map((map) => Merek.fromMap(map)).toList();
  }

  Future<int> updateMerek(Merek merek) async {
    final db = await database;
    return await db.update(
      'merek',
      merek.toMap(),
      where: 'id_merek = ?',
      whereArgs: [merek.idMerek],
    );
  }

  Future<int> deleteMerek(int idMerek) async {
    final db = await database;
    return await db.delete(
      'merek',
      where: 'id_merek = ?',
      whereArgs: [idMerek],
    );
  }

  Future<int> insertBarang(Barang barang) async {
    final db = await database;
    return await db.insert('barang', barang.toMap());
  }

  Future<List<Barang>> getAllBarang() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT b.*, k.nama_kategori, m.nama_merek 
      FROM barang b
      LEFT JOIN kategori k ON b.id_kategori = k.id_kategori
      LEFT JOIN merek m ON b.id_merek = m.id_merek
      ORDER BY b.nama_barang ASC
    ''');
    print('getAllBarang: Found ${result.length} items');
    if (result.isNotEmpty) {
      print('First item: ${result.first}');
    }
    return result.map((map) => Barang.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getBarangPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
    int? kategoriId,
    String? merekId,
  }) async {
    final db = await database;
    
    List<String> conditions = [];
    List<dynamic> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(b.nama_barang LIKE ? OR b.id_barang LIKE ?)');
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }
    
    if (kategoriId != null) {
      conditions.add('b.id_kategori = ?');
      whereArgs.add(kategoriId);
    }
    
    if (merekId != null) {
      conditions.add('b.id_merek = ?');
      whereArgs.add(merekId);
    }
    
    final whereClause = conditions.isNotEmpty 
        ? 'WHERE ${conditions.join(' AND ')}'
        : '';
    
    final countResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM barang b
      $whereClause
    ''', whereArgs.isNotEmpty ? whereArgs : null);
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;
    
    final result = await db.rawQuery('''
      SELECT b.*, k.nama_kategori, m.nama_merek 
      FROM barang b
      LEFT JOIN kategori k ON b.id_kategori = k.id_kategori
      LEFT JOIN merek m ON b.id_merek = m.id_merek
      $whereClause
      ORDER BY b.nama_barang ASC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    
    final items = result.map((map) => Barang.fromMap(map)).toList();
    
    return {
      'items': items,
      'totalCount': totalCount,
    };
  }

  Future<List<Barang>> searchBarang(String query) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT b.*, k.nama_kategori, m.nama_merek
      FROM barang b
      LEFT JOIN kategori k ON b.id_kategori = k.id_kategori
      LEFT JOIN merek m ON b.id_merek = m.id_merek
      WHERE b.nama_barang LIKE ? OR b.id_barang LIKE ?
      ORDER BY b.nama_barang ASC
    ''', ['%$query%', '%$query%']);
    return result.map((map) => Barang.fromMap(map)).toList();
  }  Future<Barang?> getBarangById(String idBarang) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT b.*, k.nama_kategori 
      FROM barang b
      LEFT JOIN kategori k ON b.id_kategori = k.id_kategori
      WHERE b.id_barang = ?
    ''', [idBarang]);
    
    if (result.isNotEmpty) {
      return Barang.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateBarang(Barang barang) async {
    final db = await database;
    return await db.update(
      'barang',
      barang.toMap(),
      where: 'id_barang = ?',
      whereArgs: [barang.idBarang],
    );
  }

  Future<int> updateStokBarang(String idBarang, int stokBaru) async {
    final db = await database;
    return await db.rawUpdate('''
      UPDATE barang 
      SET stok = ?, updated_at = ?
      WHERE id_barang = ?
    ''', [stokBaru, DateTime.now().toIso8601String(), idBarang]);
  }

  Future<int> deleteBarang(String idBarang) async {
    final db = await database;
    return await db.delete(
      'barang',
      where: 'id_barang = ?',
      whereArgs: [idBarang],
    );
  }

  Future<int> insertPemasok(Pemasok pemasok) async {
    final db = await database;
    return await db.insert('pemasok', pemasok.toMap());
  }

  Future<List<Pemasok>> getAllPemasok() async {
    final db = await database;
    final result = await db.query('pemasok', orderBy: 'nama_pemasok ASC');
    return result.map((map) => Pemasok.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getPemasokPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'WHERE nama_pemasok LIKE ? OR id_pemasok LIKE ? OR alamat LIKE ?';
      whereArgs = ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%'];
    }
    
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pemasok $whereClause',
      whereArgs.isNotEmpty ? whereArgs : null,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;
    
    final result = await db.rawQuery('''
      SELECT * FROM pemasok 
      $whereClause
      ORDER BY nama_pemasok ASC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    
    final items = result.map((map) => Pemasok.fromMap(map)).toList();
    
    return {
      'items': items,
      'totalCount': totalCount,
    };
  }

  Future<int> updatePemasok(Pemasok pemasok) async {
    final db = await database;
    return await db.update(
      'pemasok',
      pemasok.toMap(),
      where: 'id_pemasok = ?',
      whereArgs: [pemasok.idPemasok],
    );
  }

  Future<int> deletePemasok(String idPemasok) async {
    final db = await database;
    return await db.delete(
      'pemasok',
      where: 'id_pemasok = ?',
      whereArgs: [idPemasok],
    );
  }

  Future<int> insertGudang(Gudang gudang) async {
    final db = await database;
    return await db.insert('gudang', gudang.toMap());
  }

  Future<List<Gudang>> getAllGudang() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT g.*, u.fullname as nama_kepala_gudang 
      FROM gudang g
      LEFT JOIN users u ON g.id_kepala_gudang = u.id_user
      ORDER BY g.nama_gudang ASC
    ''');
    return result.map((map) => Gudang.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getGudangPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'WHERE g.nama_gudang LIKE ? OR g.id_gudang LIKE ? OR g.lokasi LIKE ?';
      whereArgs = ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%'];
    }
    
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM gudang g $whereClause',
      whereArgs.isNotEmpty ? whereArgs : null,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;
    
    final result = await db.rawQuery('''
      SELECT g.*, u.fullname as nama_kepala_gudang 
      FROM gudang g
      LEFT JOIN users u ON g.id_kepala_gudang = u.id_user
      $whereClause
      ORDER BY g.nama_gudang ASC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    
    final items = result.map((map) => Gudang.fromMap(map)).toList();
    
    return {
      'items': items,
      'totalCount': totalCount,
    };
  }

  Future<int> updateGudang(Gudang gudang) async {
    final db = await database;
    return await db.update(
      'gudang',
      gudang.toMap(),
      where: 'id_gudang = ?',
      whereArgs: [gudang.idGudang],
    );
  }

  Future<int> deleteGudang(String idGudang) async {
    final db = await database;
    return await db.delete(
      'gudang',
      where: 'id_gudang = ?',
      whereArgs: [idGudang],
    );
  }

  Future<int> insertPelanggan(Pelanggan pelanggan) async {
    final db = await database;
    return await db.insert('pelanggan', pelanggan.toMap());
  }

  Future<List<Pelanggan>> getAllPelanggan() async {
    final db = await database;
    final result = await db.query('pelanggan', orderBy: 'nama_pelanggan ASC');
    return result.map((map) => Pelanggan.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getPelangganPaginated({
    required int limit,
    required int offset,
    String? searchQuery,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'WHERE nama_pelanggan LIKE ? OR id_pelanggan LIKE ? OR alamat LIKE ? OR telepon LIKE ?';
      whereArgs = ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%', '%$searchQuery%'];
    }
    
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pelanggan $whereClause',
      whereArgs.isNotEmpty ? whereArgs : null,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;
    
    final result = await db.rawQuery('''
      SELECT * FROM pelanggan 
      $whereClause
      ORDER BY nama_pelanggan ASC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    
    final items = result.map((map) => Pelanggan.fromMap(map)).toList();
    
    return {
      'items': items,
      'totalCount': totalCount,
    };
  }

  Future<int> updatePelanggan(Pelanggan pelanggan) async {
    final db = await database;
    return await db.update(
      'pelanggan',
      pelanggan.toMap(),
      where: 'id_pelanggan = ?',
      whereArgs: [pelanggan.idPelanggan],
    );
  }

  Future<int> deletePelanggan(String idPelanggan) async {
    final db = await database;
    return await db.delete(
      'pelanggan',
      where: 'id_pelanggan = ?',
      whereArgs: [idPelanggan],
    );
  }

  Future<int> insertBarangMasuk(BarangMasuk barangMasuk) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('barang_masuk', barangMasuk.toMap());
      await txn.rawUpdate('''
        UPDATE barang 
        SET stok = stok + ?, updated_at = ?
        WHERE id_barang = ?
      ''', [barangMasuk.jumlah, DateTime.now().toIso8601String(), barangMasuk.idBarang]);
    });
    
    return 1;
  }

  Future<List<BarangMasuk>> getAllBarangMasuk({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String query = '''
      SELECT bm.*, b.nama_barang, p.nama_pemasok, g.nama_gudang
      FROM barang_masuk bm
      LEFT JOIN barang b ON bm.id_barang = b.id_barang
      LEFT JOIN pemasok p ON bm.id_pemasok = p.id_pemasok
      LEFT JOIN gudang g ON bm.id_gudang = g.id_gudang
    ''';
    
    List<dynamic> args = [];
    
    if (startDate != null && endDate != null) {
      query += ' WHERE bm.tanggal_masuk BETWEEN ? AND ?';
      args = [startDate.toIso8601String(), endDate.toIso8601String()];
    }
    
    query += ' ORDER BY bm.tanggal_masuk DESC';
    
    final result = await db.rawQuery(query, args);
    return result.map((map) => BarangMasuk.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getBarangMasukPaginated({
    required int limit,
    required int offset,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    final db = await database;
    
    List<String> conditions = [];
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      conditions.add('bm.tanggal_masuk BETWEEN ? AND ?');
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(b.nama_barang LIKE ? OR bm.id_barang LIKE ? OR p.nama_pemasok LIKE ?)');
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }
    
    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final countResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM barang_masuk bm
      LEFT JOIN barang b ON bm.id_barang = b.id_barang
      LEFT JOIN pemasok p ON bm.id_pemasok = p.id_pemasok
      $whereClause
    ''', whereArgs.isNotEmpty ? whereArgs : null);
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;
    final result = await db.rawQuery('''
      SELECT bm.*, b.nama_barang, p.nama_pemasok, g.nama_gudang
      FROM barang_masuk bm
      LEFT JOIN barang b ON bm.id_barang = b.id_barang
      LEFT JOIN pemasok p ON bm.id_pemasok = p.id_pemasok
      LEFT JOIN gudang g ON bm.id_gudang = g.id_gudang
      $whereClause
      ORDER BY bm.tanggal_masuk DESC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    final items = result.map((map) => BarangMasuk.fromMap(map)).toList();
    
    return {
      'items': items,
      'totalCount': totalCount,
    };
  }

  Future<int> insertBarangKeluar(BarangKeluar barangKeluar) async {
    final db = await database;
    final barang = await getBarangById(barangKeluar.idBarang);
    if (barang == null || barang.stok < barangKeluar.jumlah) {
      throw Exception('Stok tidak mencukupi');
    }
    await db.transaction((txn) async {
      await txn.insert('barang_keluar', barangKeluar.toMap());
      await txn.rawUpdate('''
        UPDATE barang 
        SET stok = stok - ?, updated_at = ?
        WHERE id_barang = ?
      ''', [barangKeluar.jumlah, DateTime.now().toIso8601String(), barangKeluar.idBarang]);
    });
    return 1;
  }

  Future<List<BarangKeluar>> getAllBarangKeluar({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String query = '''
      SELECT bk.*, b.nama_barang, p.nama_pelanggan, g.nama_gudang
      FROM barang_keluar bk
      LEFT JOIN barang b ON bk.id_barang = b.id_barang
      LEFT JOIN pelanggan p ON bk.id_pelanggan = p.id_pelanggan
      LEFT JOIN gudang g ON bk.id_gudang = g.id_gudang
    ''';
    
    List<dynamic> args = [];
    
    if (startDate != null && endDate != null) {
      query += ' WHERE bk.tanggal_keluar BETWEEN ? AND ?';
      args = [startDate.toIso8601String(), endDate.toIso8601String()];
    }
    
    query += ' ORDER BY bk.tanggal_keluar DESC';
    
    final result = await db.rawQuery(query, args);
    return result.map((map) => BarangKeluar.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getBarangKeluarPaginated({
    required int limit,
    required int offset,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    final db = await database;
    
    List<String> conditions = [];
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      conditions.add('bk.tanggal_keluar BETWEEN ? AND ?');
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(b.nama_barang LIKE ? OR bk.id_barang LIKE ? OR p.nama_pelanggan LIKE ?)');
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }
    
    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final countResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM barang_keluar bk
      LEFT JOIN barang b ON bk.id_barang = b.id_barang
      LEFT JOIN pelanggan p ON bk.id_pelanggan = p.id_pelanggan
      $whereClause
    ''', whereArgs.isNotEmpty ? whereArgs : null);
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;
    final result = await db.rawQuery('''
      SELECT bk.*, b.nama_barang, p.nama_pelanggan, g.nama_gudang
      FROM barang_keluar bk
      LEFT JOIN barang b ON bk.id_barang = b.id_barang
      LEFT JOIN pelanggan p ON bk.id_pelanggan = p.id_pelanggan
      LEFT JOIN gudang g ON bk.id_gudang = g.id_gudang
      $whereClause
      ORDER BY bk.tanggal_keluar DESC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    final items = result.map((map) => BarangKeluar.fromMap(map)).toList();
    
    return {
      'items': items,
      'totalCount': totalCount,
    };
  }

  Future<int> insertPenjualan(Penjualan penjualan, List<PenjualanDetail> details) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('penjualan', penjualan.toMap());
      for (var detail in details) {
        final result = await txn.query(
          'barang',
          where: 'id_barang = ?',
          whereArgs: [detail.idBarang],
        );
        
        if (result.isEmpty) {
          throw Exception('Barang ${detail.namaBarang} tidak ditemukan');
        }
        
        final stok = result.first['stok'] as int;
        if (stok < detail.jumlah) {
          throw Exception('Stok ${detail.namaBarang} tidak mencukupi');
        }
        
        await txn.insert('penjualan_detail', {
          ...detail.toMap(),
          'id_penjualan': penjualan.idPenjualan,
        });
        
        await txn.rawUpdate('''
          UPDATE barang 
          SET stok = stok - ?, updated_at = ?
          WHERE id_barang = ?
        ''', [detail.jumlah, DateTime.now().toIso8601String(), detail.idBarang]);
      }
    });
    
    return 1;
  }

  Future<List<Penjualan>> getAllPenjualan({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String query = '''
      SELECT p.*, pel.nama_pelanggan
      FROM penjualan p
      LEFT JOIN pelanggan pel ON p.id_pelanggan = pel.id_pelanggan
    ''';
    
    List<dynamic> args = [];
    
    if (startDate != null && endDate != null) {
      query += ' WHERE p.tanggal_penjualan BETWEEN ? AND ?';
      args = [startDate.toIso8601String(), endDate.toIso8601String()];
    }
    
    query += ' ORDER BY p.tanggal_penjualan DESC';
    
    final result = await db.rawQuery(query, args);
    return result.map((map) => Penjualan.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getPenjualanPaginated({
    required int limit,
    required int offset,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    final db = await database;
    
    List<String> conditions = [];
    List<dynamic> whereArgs = [];
    
    // Date range filter
    if (startDate != null && endDate != null) {
      conditions.add('p.tanggal_penjualan BETWEEN ? AND ?');
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }
    
    // Search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('(p.id_penjualan LIKE ? OR pel.nama_pelanggan LIKE ?)');
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }
    
    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    
    // Get total count
    final countResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM penjualan p
      LEFT JOIN pelanggan pel ON p.id_pelanggan = pel.id_pelanggan
      $whereClause
    ''', whereArgs.isNotEmpty ? whereArgs : null);
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;
    
    // Get paginated data
    final result = await db.rawQuery('''
      SELECT p.*, pel.nama_pelanggan
      FROM penjualan p
      LEFT JOIN pelanggan pel ON p.id_pelanggan = pel.id_pelanggan
      $whereClause
      ORDER BY p.tanggal_penjualan DESC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    
    final items = result.map((map) => Penjualan.fromMap(map)).toList();
    
    return {
      'items': items,
      'totalCount': totalCount,
    };
  }

  Future<List<PenjualanDetail>> getPenjualanDetails(String idPenjualan) async {
    final db = await database;
    final result = await db.query(
      'penjualan_detail',
      where: 'id_penjualan = ?',
      whereArgs: [idPenjualan],
    );
    return result.map((map) => PenjualanDetail.fromMap(map)).toList();
  }

  // Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    
    // Total Barang
    final totalBarangResult = await db.rawQuery('SELECT COUNT(*) as count FROM barang');
    final totalBarang = totalBarangResult.first['count'] as int;
    
    // Total Stok
    final totalStokResult = await db.rawQuery('SELECT SUM(stok) as total FROM barang');
    final totalStok = totalStokResult.first['total'] ?? 0;
    
    // Total Penjualan Hari Ini
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    
    final penjualanHariIniResult = await db.rawQuery('''
      SELECT SUM(total_harga) as total 
      FROM penjualan 
      WHERE tanggal_penjualan BETWEEN ? AND ?
    ''', [startOfDay, endOfDay]);
    final penjualanHariIni = penjualanHariIniResult.first['total'] ?? 0;
    
    // Barang Stok Menipis (< 10)
    final stokMenipisResult = await db.rawQuery('SELECT COUNT(*) as count FROM barang WHERE stok < 10');
    final stokMenipis = stokMenipisResult.first['count'] as int;
    
    return {
      'totalBarang': totalBarang,
      'totalStok': totalStok,
      'penjualanHariIni': penjualanHariIni,
      'stokMenipis': stokMenipis,
    };
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Get database path for backup
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'bengkel_v2.db');
  }

  // Import SQL file
  Future<bool> importSqlFile(String sqlContent) async {
    try {
      final db = await database;
      
      // Remove comment lines first
      final lines = sqlContent.split('\n');
      final cleanedLines = lines
          .where((line) => !line.trim().startsWith('--'))
          .join('\n');
      
      // Split SQL content by semicolon and execute each statement
      final statements = cleanedLines
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      print('Total SQL statements to execute: ${statements.length}');
      
      await db.transaction((txn) async {
        int successCount = 0;
        for (final statement in statements) {
          if (statement.trim().isNotEmpty) {
            try {
              await txn.execute(statement);
              successCount++;
              print('Executed: ${statement.substring(0, statement.length > 50 ? 50 : statement.length)}...');
            } catch (e) {
              print('Error executing statement: $e');
              print('Statement: ${statement.substring(0, statement.length > 100 ? 100 : statement.length)}');
            }
          }
        }
        print('Successfully executed $successCount out of ${statements.length} statements');
      });
      
      // Verify data was inserted
      final barangCount = await db.rawQuery('SELECT COUNT(*) as count FROM barang');
      final kategoriCount = await db.rawQuery('SELECT COUNT(*) as count FROM kategori');
      final merekCount = await db.rawQuery('SELECT COUNT(*) as count FROM merek');
      
      print('After import - Kategori: ${kategoriCount[0]['count']}, Merek: ${merekCount[0]['count']}, Barang: ${barangCount[0]['count']}');
      
      return true;
    } catch (e) {
      print('Error importing SQL: $e');
      return false;
    }
  }

  // Report methods - Get data by date range
  Future<List<BarangMasuk>> getBarangMasukByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        bm.*,
        b.nama_barang,
        b.stok,
        p.nama_pemasok,
        g.nama_gudang
      FROM barang_masuk bm
      LEFT JOIN barang b ON bm.id_barang = b.id_barang
      LEFT JOIN pemasok p ON bm.id_pemasok = p.id_pemasok
      LEFT JOIN gudang g ON bm.id_gudang = g.id_gudang
      WHERE DATE(bm.tanggal_masuk) BETWEEN ? AND ?
      ORDER BY bm.tanggal_masuk DESC
    ''', [startDateStr, endDateStr]);

    return List.generate(maps.length, (i) => BarangMasuk.fromMap(maps[i]));
  }

  Future<List<BarangKeluar>> getBarangKeluarByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        bk.*,
        b.nama_barang,
        b.stok,
        g.nama_gudang,
        pel.nama_pelanggan
      FROM barang_keluar bk
      LEFT JOIN barang b ON bk.id_barang = b.id_barang
      LEFT JOIN gudang g ON bk.id_gudang = g.id_gudang
      LEFT JOIN pelanggan pel ON bk.id_pelanggan = pel.id_pelanggan
      WHERE DATE(bk.tanggal_keluar) BETWEEN ? AND ?
      ORDER BY bk.tanggal_keluar DESC
    ''', [startDateStr, endDateStr]);

    return List.generate(maps.length, (i) => BarangKeluar.fromMap(maps[i]));
  }

  Future<List<Penjualan>> getPenjualanByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        p.*,
        pel.nama_pelanggan
      FROM penjualan p
      LEFT JOIN pelanggan pel ON p.id_pelanggan = pel.id_pelanggan
      WHERE DATE(p.tanggal_penjualan) BETWEEN ? AND ?
      ORDER BY p.tanggal_penjualan DESC
    ''', [startDateStr, endDateStr]);

    return List.generate(maps.length, (i) => Penjualan.fromMap(maps[i]));
  }
}
