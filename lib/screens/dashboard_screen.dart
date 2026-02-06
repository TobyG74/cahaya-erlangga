import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_helper.dart';
import '../widgets/stat_card.dart';
import 'barang_screen.dart';
import 'kategori_screen.dart';
import 'merek_screen.dart';
import 'pemasok_screen.dart';
import 'gudang_screen.dart';
import 'barang_masuk_screen.dart';
import 'barang_keluar_screen.dart';
import 'penjualan_screen.dart';
import 'laporan_screen.dart';
import 'user_management_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await DatabaseHelper.instance.getDashboardStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Toggle Theme',
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, authProvider),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: theme.colorScheme.primary,
                              child: Text(
                                authProvider.currentUser?.fullname[0] ?? 'U',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat Datang,',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Text(
                                    authProvider.currentUser?.fullname ?? '',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    authProvider.currentUser?.role ?? '',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Statistik',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_stats != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Barang',
                              value: _stats!['totalBarang'].toString(),
                              icon: Icons.inventory_2,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Total Stok',
                              value: _stats!['totalStok'].toString(),
                              icon: Icons.bar_chart,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Penjualan Hari Ini',
                              value: 'Rp ${_formatCurrency(_stats!['penjualanHariIni'])}',
                              icon: Icons.payments,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Stok Menipis',
                              value: _stats!['stokMenipis'].toString(),
                              icon: Icons.warning,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Menu Cepat',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildQuickActions(context, authProvider),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icon.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Erlangga Motor',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.currentUser?.username ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Master Data
          _buildDrawerHeader('Master Data'),
          _buildDrawerItem(
            context,
            icon: Icons.inventory_2,
            title: 'Barang',
            onTap: () => _navigateTo(context, const BarangScreen()),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.category,
            title: 'Kategori',
            onTap: () => _navigateTo(context, const KategoriScreen()),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.branding_watermark,
            title: 'Merek',
            onTap: () => _navigateTo(context, const MerekScreen()),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.local_shipping,
            title: 'Pemasok',
            onTap: () => _navigateTo(context, const PemasokScreen()),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.warehouse,
            title: 'Gudang',
            onTap: () => _navigateTo(context, const GudangScreen()),
          ),

          const Divider(),

          // Transaksi
          _buildDrawerHeader('Transaksi'),
          _buildDrawerItem(
            context,
            icon: Icons.arrow_downward,
            title: 'Barang Masuk',
            onTap: () => _navigateTo(context, const BarangMasukScreen()),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.arrow_upward,
            title: 'Barang Keluar',
            onTap: () => _navigateTo(context, const BarangKeluarScreen()),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.shopping_cart,
            title: 'Penjualan',
            onTap: () => _navigateTo(context, const PenjualanScreen()),
          ),

          const Divider(),

          // Laporan
          _buildDrawerItem(
            context,
            icon: Icons.assessment,
            title: 'Laporan',
            onTap: () => _navigateTo(context, const LaporanScreen()),
          ),

          const Divider(),

          // User Management (Admin only)
          if (authProvider.canCreateUser())
            _buildDrawerItem(
              context,
              icon: Icons.manage_accounts,
              title: 'Kelola User',
              onTap: () => _navigateTo(context, const UserManagementScreen()),
            ),

          // Settings
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Pengaturan',
            onTap: () => _navigateToSettings(context),
          ),

          const Divider(),

          // Logout
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildQuickActions(BuildContext context, AuthProvider authProvider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildQuickActionCard(
          context,
          icon: Icons.inventory_2,
          label: 'Barang',
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BarangScreen()),
          ),
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.shopping_cart,
          label: 'Penjualan',
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PenjualanScreen()),
          ),
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.arrow_downward,
          label: 'Barang Masuk',
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BarangMasukScreen()),
          ),
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.arrow_upward,
          label: 'Barang Keluar',
          color: Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BarangKeluarScreen()),
          ),
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.assessment,
          label: 'Laporan',
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LaporanScreen()),
          ),
        ),
        _buildQuickActionCard(
          context,
          icon: Icons.settings,
          label: 'Pengaturan',
          color: Colors.grey,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            if (result == true && mounted) {
              _loadStats();
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); 
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _navigateToSettings(BuildContext context) async {
    Navigator.pop(context); 
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    if (result == true && mounted) {
      _loadStats();
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context); 
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
    }
  }

  String _formatCurrency(dynamic value) {
    final number = (value is int) ? value : (value as double).toInt();
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
