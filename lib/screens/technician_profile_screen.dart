import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../services/user_service.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});

  @override
  State<TechnicianProfileScreen> createState() => _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _name = 'Loading...';
  String _username = '...';
  String _email = '...';
  String _mobile = '...';
  String _address = '...';
  String _role = 'Technician';
  String _expertise = 'Loading...';

  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userData = await UserService().getCurrentUserData();
    if (mounted && userData != null) {
      setState(() {
        _name = userData['displayName'] ?? 'Technician';
        _username = userData['username'] ?? 'username';
        _email = userData['email'] ?? 'email@example.com';
        _mobile = userData['mobile'] ?? 'N/A';
        _address = userData['address'] ?? 'No address set';
        _role = (userData['role'] ?? 'Technician').toString().toUpperCase();
        _expertise = userData['expertise'] ?? 'Washing Machines, Refrigerators';
      });
    }
  }

  void _openChangePassword() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Change Password', style: TextStyle(color: AppColors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: obscure,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Current password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: obscure,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'New password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: obscure,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Confirm new password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully.'),
                    backgroundColor: AppColors.surfaceLight,
                  ),
                );
              },
              child: const Text('Update', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Log Out', style: TextStyle(color: AppColors.white, fontSize: 16)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Log Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Technician Profile',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/technician'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: technicianNav,
        activeRoute: '/technician/profile',
        userName: _name,
        userRole: 'Technician',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Profile header ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: AppColors.gold,
                    child: Icon(Icons.engineering, color: AppColors.background, size: 45),
                  ),
                  const SizedBox(height: 16),
                  Text(_name, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_role,
                        style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---- Availability Toggle ----
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Work Availability', style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(_isAvailable ? 'Available for new assignments' : 'Currently off-duty', 
                  style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                activeColor: AppColors.gold,
              ),
            ),

            const SizedBox(height: 16),

            // ---- Account info ----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Technician Details',
                      style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.alternate_email, 'Username', _username),
                  _infoRow(Icons.email_outlined, 'Email', _email),
                  _infoRow(Icons.phone_outlined, 'Mobile Number', _mobile),
                  _infoRow(Icons.location_on_outlined, 'Address', _address),
                  _infoRow(Icons.star_border, 'Expertise', _expertise),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ---- Settings list ----
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _settingsTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: _openChangePassword,
                  ),
                  const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
                  _settingsTile(
                    icon: Icons.notifications_none,
                    title: 'Notification Preferences',
                    onTap: () {
                      // Show notification settings
                    },
                  ),
                  const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
                  _settingsTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    titleColor: AppColors.danger,
                    iconColor: AppColors.danger,
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF7A7E9E), fontSize: 11.5)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.white, fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.lightGray, size: 20),
      title: Text(title, style: TextStyle(color: titleColor ?? AppColors.white, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.lightGray, size: 18),
      onTap: onTap,
    );
  }
}
