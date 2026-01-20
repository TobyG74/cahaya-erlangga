import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class BackupManager {
  static final BackupManager instance = BackupManager._init();
  BackupManager._init();
  
  static const String _customPathKey = 'custom_backup_path';

  Future<bool> requestStoragePermission() async {
    return true;
  }

  Future<Directory?> getBackupDirectory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString(_customPathKey);
      
      Directory? directory;
      
      if (customPath != null && customPath.isNotEmpty) {
        directory = Directory(customPath);
      } else if (Platform.isAndroid) {
        final appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          final pathParts = appDir.path.split('/');
          final baseIndex = pathParts.indexOf('Android');
          if (baseIndex > 0) {
            final basePath = pathParts.sublist(0, baseIndex).join('/');
            directory = Directory('$basePath/Documents/ErlanggaMotor/Backup');
          } else {
            directory = Directory('${appDir.path}/Backup');
          }
        }
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        directory = Directory('${appDir.path}/Backup');
      }

      if (directory != null && !await directory.exists()) {
        await directory.create(recursive: true);
      }

      return directory;
    } catch (e) {
      try {
        final appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          final directory = Directory('${appDir.path}/Backup');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          return directory;
        }
      } catch (e2) {
        print('Fallback directory error: $e2');
      }
      return null;
    }
  }
  
  Future<bool> setCustomBackupDirectory(String path) async {
    try {
      final directory = Directory(path);
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customPathKey, path);
      
      return true;
    } catch (e) {
      print('Error setting custom backup directory: $e');
      return false;
    }
  }
  
  Future<void> resetBackupDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customPathKey);
  }

  Future<String?> backupDatabase() async {
    try {
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission not granted');
      }

      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      final backupDir = await getBackupDirectory();
      if (backupDir == null) {
        throw Exception('Could not access backup directory');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'bengkel_backup_$timestamp.db';
      final backupPath = '${backupDir.path}/$backupFileName';

      await dbFile.copy(backupPath);

      final infoFile = File('${backupDir.path}/backup_info.txt');
      final infoContent = '''
Erlangga Motor - Database Backup
====================================
Backup Date: ${DateFormat('dd MMMM yyyy HH:mm:ss').format(DateTime.now())}
Backup File: $backupFileName
Database Size: ${await dbFile.length()} bytes
====================================
''';
      await infoFile.writeAsString(infoContent);

      return backupPath;
    } catch (e) {
      print('Error backing up database: $e');
      return null;
    }
  }

  Future<bool> restoreDatabase(String backupPath) async {
    try {
      print('Starting restore from: $backupPath');
      final backupFile = File(backupPath);
      
      if (!await backupFile.exists()) {
        print('Backup file not found!');
        throw Exception('Backup file not found');
      }

      print('Backup file exists, size: ${await backupFile.length()} bytes');

      print('Closing current database...');
      await DatabaseHelper.instance.close();

      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      await backupFile.copy(dbPath);

      final restoredFile = File(dbPath);
      if (await restoredFile.exists()) {
      }

      await DatabaseHelper.instance.database;

      return true;
    } catch (e) {
      print('Error restoring database: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final backupDir = await getBackupDirectory();
      if (backupDir == null) return [];

      if (await backupDir.exists()) {
        final files = backupDir.listSync(recursive: true, followLinks: false);
        final backups = <Map<String, dynamic>>[];

        for (var file in files) {
          if (file is File && file.path.toLowerCase().endsWith('.db')) {
            final stat = await file.stat();
            final fileName = file.path.split(Platform.pathSeparator).last;
            
            backups.add({
              'path': file.path,
              'name': fileName,
              'size': stat.size,
              'date': stat.modified,
            });
          }
        }

        backups.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

        return backups;
      }
      
      return [];
    } catch (e) {
      print('Error listing backups: $e');
      return [];
    }
  }

  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting backup: $e');
      return false;
    }
  }

  Future<void> autoBackup() async {
    try {
      final backups = await listBackups();
      
      if (backups.isEmpty) {
        await backupDatabase();
        return;
      }

      final lastBackup = backups.first['date'] as DateTime;
      final hoursSinceLastBackup = DateTime.now().difference(lastBackup).inHours;

      if (hoursSinceLastBackup >= 24) {
        await backupDatabase();
        
        if (backups.length > 7) {
          for (int i = 7; i < backups.length; i++) {
            await deleteBackup(backups[i]['path']);
          }
        }
      }
    } catch (e) {
      print('Error in auto backup: $e');
    }
  }

  Future<String> getBackupFolderPath() async {
    final dir = await getBackupDirectory();
    return dir?.path ?? 'Unknown';
  }
}
