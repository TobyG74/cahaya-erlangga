import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/backup_manager.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _backupPath = '';

  @override
  void initState() {
    super.initState();
    _loadBackupPath();
  }

  Future<void> _loadBackupPath() async {
    final path = await BackupManager.instance.getBackupFolderPath();
    setState(() => _backupPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Tampilan'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Mode Gelap'),
                  subtitle: const Text('Gunakan tema gelap'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                  secondary: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                ),
              ],
            ),
          ),

          _buildSectionHeader('Database'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup Database'),
                  subtitle: const Text('Cadangkan data ke storage'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _backupDatabase(context),
                ),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Database'),
                  subtitle: const Text('Pulihkan data dari backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRestoreDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.green),
                  title: const Text('Import Data SQL', style: TextStyle(color: Colors.green)),
                  subtitle: const Text('Import data dari file SQL'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _importSqlFile(context),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Reset Database', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Hapus semua data dan reset ke awal'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    print('Reset Database button tapped!');
                    _showResetDatabaseDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('Lokasi Backup'),
                  subtitle: Text(
                    _backupPath.isEmpty ? 'Loading...' : _backupPath,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _changeBackupLocation(context),
                ),
              ],
            ),
          ),

          _buildSectionHeader('Akun'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profil'),
                  subtitle: Text(authProvider.currentUser?.fullname ?? ''),
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Ubah Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePasswordDialog(context),
                ),
              ],
            ),
          ),

          _buildSectionHeader('Tentang'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Versi Aplikasi'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Tentang Aplikasi'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _backupDatabase(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final path = await BackupManager.instance.backupDatabase();
    
    if (!mounted) return;
    Navigator.pop(context);

    if (path != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup Berhasil'),
          content: Text('Database berhasil di-backup ke:\n$path'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup gagal. Pastikan izin storage diberikan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRestoreDialog(BuildContext parentContext) async {
    final backups = await BackupManager.instance.listBackups();

    if (!mounted) return;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(child: Text('Pilih Backup')),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh daftar backup',
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    _showRestoreDialog(parentContext);
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: backups.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Tidak ada file backup di folder.\n\nGunakan tombol "Pilih File" untuk memilih dari lokasi lain.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: backups.length,
                      itemBuilder: (context, index) {
                        final backup = backups[index];
                        final date = backup['date'] as DateTime;
                        final size = backup['size'] as int;

                        return ListTile(
                          leading: const Icon(Icons.backup),
                          title: Text(backup['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${DateFormat('dd MMM yyyy HH:mm').format(date)} - ${(size / 1024).toStringAsFixed(2)} KB',
                              ),
                              Text(
                                backup['path'],
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _confirmRestore(backup['path']);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (mounted) {
                    _pickAndRestoreFile(parentContext);
                  }
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Pilih File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRestore(String path) async {
    if (!mounted) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Restore'),
        content: const Text(
          'Data saat ini akan diganti dengan backup. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      _performRestore(path);
    }
  }

  Future<void> _pickAndRestoreFile(BuildContext parentContext) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Pilih File Database (.db)',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        if (!filePath.toLowerCase().endsWith('.db')) {
          if (mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              const SnackBar(
                content: Text('File harus berformat .db'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (!mounted) return;
        
        final confirm = await showDialog<bool>(
          context: parentContext,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Konfirmasi Restore'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('File yang dipilih:'),
                const SizedBox(height: 8),
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lokasi: $filePath',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Text('Data saat ini akan diganti dengan backup ini.\nLanjutkan restore?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Restore'),
              ),
            ],
          ),
        );

        if (confirm == true && mounted) {
          _performRestore(filePath);
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('Error memilih file: $e')),
        );
      }
    }
  }

  void _performRestore(String path) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Merestore database...'),
          ],
        ),
      ),
    );

    try {
      final success = await BackupManager.instance.restoreDatabase(path);
      
      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database berhasil di-restore!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Lama'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password baru tidak cocok')),
                );
                return;
              }

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.updatePassword(
                oldPasswordController.text,
                newPasswordController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Password berhasil diubah'
                        : 'Password lama salah'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Aplikasi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Erlangga Motor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Versi 1.0.0'),
              const SizedBox(height: 16),
              const Text(
                'Proyek KKP (Kerja Kuliah Praktek)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Universitas Indraprasta PGRI'),
              const SizedBox(height: 16),
              const Text(
                'Tim Pengembang:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildTeamMember('1. Endriyan Ramadhan', '2595'),
              _buildTeamMember('2. Azizan Ramadhan', '2583'),
              _buildTeamMember('3. Ridho Alfiansyah Yuharian', '2644'),
              _buildTeamMember('4. Satrio Baskoro', '2598'),
              _buildTeamMember('5. Tobi Saputra', '2612'),
              _buildTeamMember('6. Fachri Akbar', '2642'),
              _buildTeamMember('7. Ishafakhri Akbar', '2587'),
              _buildTeamMember('8. Muhammad Zulfahmi', '2609'),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String name, String nim) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(name),
          ),
          Text(
            nim,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showResetDatabaseDialog(BuildContext context) {
    print('_showResetDatabaseDialog called');
    showDialog(
      context: context,
      builder: (context) {
        print('Building first dialog');
        return AlertDialog(
        title: const Text('Reset Database'),
        content: const Text(
          'PERINGATAN!\n\nSemua data akan dihapus dan tidak dapat dikembalikan. '
          'Pastikan Anda sudah melakukan backup terlebih dahulu.\n\n'
          'Lanjutkan reset database?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('First dialog - Batal pressed');
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              print('First dialog - Reset pressed');
              Navigator.pop(context);
              _confirmReset();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      );
      },
    );
  }

  void _confirmReset() async {
    print('Widget mounted: $mounted');
    
    if (!mounted) {
      print('ERROR: Widget not mounted after first dialog!');
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        print('Building second confirmation dialog');
        return AlertDialog(
        title: const Text('Konfirmasi Terakhir'),
        content: const Text('Apakah Anda benar-benar yakin ingin mereset database?'),
        actions: [
          TextButton(
            onPressed: () {
              print('Second dialog - Batal pressed');
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              print('Second dialog - Reset pressed');
              Navigator.pop(dialogContext, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      );
      },
    );

    print('Confirmation result: $confirm');
    print('Widget mounted after confirmation: $mounted');
    
    if (confirm == true) {
      print('Confirm is true, checking widget...');
      if (!mounted) {
        print('ERROR: Widget not mounted!');
        return;
      }
      
      _performReset();
    } else {
      print('Confirm is false or null, aborting reset');
    }
  }

  void _performReset() async {
    print('Starting database reset...');
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Mereset database...'),
          ],
        ),
      ),
    );
    
    try {
      print('Calling resetDatabase...');
      await DatabaseHelper.instance.resetDatabase();
      print('Reset database completed');
      
      if (!mounted) return;
      
      Navigator.pop(context); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database berhasil direset!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error during reset: $e');
      if (!mounted) return;
      
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reset database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changeBackupLocation(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Lokasi Backup'),
        content: const Text(
          'Pilih folder baru untuk menyimpan backup database.\n\n'
          'Pastikan lokasi yang dipilih memiliki izin akses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                
                if (selectedDirectory != null) {
                  final success = await BackupManager.instance.setCustomBackupDirectory(
                    '$selectedDirectory/Backup',
                  );
                  
                  if (success) {
                    await _loadBackupPath();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lokasi backup berhasil diubah'),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal mengubah lokasi backup'),
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Pilih Folder'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              await BackupManager.instance.resetBackupDirectory();
              await _loadBackupPath();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lokasi backup dikembalikan ke default'),
                  ),
                );
              }
            },
            child: const Text('Reset ke Default'),
          ),
        ],
      ),
    );
  }

  Future<void> _importSqlFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sql'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Data SQL'),
            content: Text(
              'Import data dari file:\n${result.files.single.name}\n\n'
              'Data baru akan ditambahkan ke database.\n'
              'Lanjutkan import?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          try {
            final sqlContent = await file.readAsString();
            final success = await DatabaseHelper.instance.importSqlFile(sqlContent);
            
            if (context.mounted) {
              Navigator.pop(context); 
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data berhasil diimport!'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal import data. Periksa format SQL.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
