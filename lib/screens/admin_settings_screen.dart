import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _twoFactorAuth = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'System Settings',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin/settings',
        userName: 'Admin',
        userRole: 'Administrator',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('System Settings',
                style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Manage shop configuration and security.',
                style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
            const SizedBox(height: 24),

            // ---- General Section ----
            _buildSectionHeader('General Shop Info'),
            _buildCard(
              child: Column(
                children: [
                  _buildTextField(label: 'Shop Name', initialValue: 'BartAton Shop'),
                  const SizedBox(height: 16),
                  _buildTextField(label: 'Contact Number', initialValue: '+63 912 345 6789'),
                  const SizedBox(height: 16),
                  _buildTextField(label: 'Business Address', initialValue: '123 Main St, Manila'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // ---- Notifications Section ----
            _buildSectionHeader('Notifications'),
            _buildCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive daily reports via email',
                    value: _emailNotifications,
                    onChanged: (v) => setState(() => _emailNotifications = v),
                  ),
                  const Divider(color: AppColors.border),
                  _buildSwitchTile(
                    title: 'SMS Alerts',
                    subtitle: 'Notify on critical inventory levels',
                    value: _smsNotifications,
                    onChanged: (v) => setState(() => _smsNotifications = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---- Security Section ----
            _buildSectionHeader('Security'),
            _buildCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Change Password', style: TextStyle(color: AppColors.white, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.lightGray),
                    onTap: () {
                      // Handle password change
                    },
                  ),
                  const Divider(color: AppColors.border),
                  _buildSwitchTile(
                    title: 'Two-Factor Authentication',
                    subtitle: 'Add an extra layer of security',
                    value: _twoFactorAuth,
                    onChanged: (v) => setState(() => _twoFactorAuth = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---- System Section ----
            _buildSectionHeader('System & Data'),
            _buildCard(
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.backup,
                    label: 'Database Backup',
                    onTap: () {},
                  ),
                  const Divider(color: AppColors.border),
                  _buildActionTile(
                    icon: Icons.restore,
                    label: 'Restore from Backup',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildTextField({required String label, required String initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(color: AppColors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.lightGray),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: AppColors.white, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.gold,
      inactiveTrackColor: AppColors.background,
    );
  }

  Widget _buildActionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.lightGray, size: 20),
      title: Text(label, style: const TextStyle(color: AppColors.white, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.lightGray),
      onTap: onTap,
    );
  }
}
