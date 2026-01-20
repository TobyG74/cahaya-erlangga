import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/backup_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  await BackupManager.instance.autoBackup();
  await _createLaporanFolders();
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  final cameraStatus = await Permission.camera.status;
  if (!cameraStatus.isGranted) {
    await Permission.camera.request();
  }
}

Future<void> _createLaporanFolders() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final excelDir = Directory('${directory.path}/ErlanggaMotor/Laporan/Excel');
    if (!await excelDir.exists()) {
      await excelDir.create(recursive: true);
    }
    final pdfDir = Directory('${directory.path}/ErlanggaMotor/Laporan/PDF');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
  } catch (e) {
    print('Error creating Laporan folders: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Erlangga Motor',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isLoggedIn) {
                  return const DashboardScreen();
                }
                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
