import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _name = 'Loading...';
  String _username = '...';
  String _email = '...';
  String _mobile = '...';
  String _address = '...';
  String _role = 'Customer';

  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userData = await UserService().getCurrentUserData();
    if (mounted && userData != null) {
      setState(() {
        _name = userData['displayName'] ?? 'User';
        _username = userData['username'] ?? 'username';
        _email = userData['email'] ?? 'email@example.com';
        _mobile = userData['mobile'] ?? 'N/A';
        _address = userData['address'] ?? 'No address set';
        _role = userData['role']?.toUpperCase() ?? 'CUSTOMER';
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
              // TODO: Replace with a real password-change call to your
              // backend (e.g. FirebaseAuth.updatePassword after re-auth).
              onPressed: () {
                if (newController.text.isEmpty || newController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match.'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
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
        title: 'Profile',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/customer'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: customerNav,
        activeRoute: '/customer/profile',
        userName: _name,
        userRole: _role,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Profile header ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.gold,
                        child: Icon(Icons.person, color: AppColors.background, size: 40),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            // TODO: Wire to image_picker + upload to storage.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connect image_picker to change photo.'),
                                backgroundColor: AppColors.surfaceLight,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: AppColors.gold, size: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(_name, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_role,
                        style: const TextStyle(color: AppColors.gold, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ),
                ],
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
                  const Text('Account Information',
                      style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.alternate_email, 'Username', _username),
                  _infoRow(Icons.email_outlined, 'Email', _email),
                  _infoRow(Icons.phone_outlined, 'Mobile Number', _mobile),
                  _infoRow(Icons.location_on_outlined, 'Address', _address),
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
                  _expandableNotificationSettings(),
                  const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
                  _settingsTile(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Account Settings',
                    onTap: () {},
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

  Widget _expandableNotificationSettings() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(Icons.notifications_outlined, color: AppColors.lightGray, size: 20),
        title: const Text('Notification Settings', style: TextStyle(color: AppColors.white, fontSize: 14)),
        iconColor: AppColors.gold,
        collapsedIconColor: AppColors.lightGray,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        children: [
          _notificationSwitch('Push Notifications', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
          _notificationSwitch('Email Notifications', _emailNotifications, (v) => setState(() => _emailNotifications = v)),
          _notificationSwitch('SMS Notifications', _smsNotifications, (v) => setState(() => _smsNotifications = v)),
        ],
      ),
    );
  }

  Widget _notificationSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.gold,
            activeTrackColor: AppColors.gold.withOpacity(0.3),
            inactiveThumbColor: AppColors.lightGray,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}
