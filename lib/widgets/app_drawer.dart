import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';

class NavItem {
  final IconData icon;
  final String label;
  final String route;
  const NavItem(this.icon, this.label, this.route);
}

class AppDrawer extends StatefulWidget {
  final List<NavItem> items;
  final String activeRoute;
  final String? userName; // Optional override
  final String? userRole; // Optional override

  const AppDrawer({
    super.key,
    required this.items,
    required this.activeRoute,
    this.userName,
    this.userRole,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _name = 'Loading...';
  String _role = 'User';

  @override
  void initState() {
    super.initState();
    if (widget.userName == null || widget.userRole == null) {
      _loadUserData();
    } else {
      _name = widget.userName!;
      _role = widget.userRole!;
    }
  }

  Future<void> _loadUserData() async {
    final userData = await UserService().getCurrentUserData();
    if (mounted && userData != null) {
      setState(() {
        _name = userData['displayName'] ?? 'User';
        _role = (userData['role'] ?? 'User').toString().toUpperCase();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                'assets/logo.png',
                height: 55,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isActive = item.route == widget.activeRoute;
                  return ListTile(
                    leading: Icon(item.icon, color: isActive ? AppColors.gold : AppColors.lightGray, size: 20),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isActive ? AppColors.gold : AppColors.lightGray,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    tileColor: isActive ? AppColors.gold.withOpacity(0.08) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (!isActive) {
                        Navigator.of(context).pushReplacementNamed(item.route);
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.gold,
                    child: Icon(Icons.person, color: AppColors.background, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(_role, style: const TextStyle(color: Color(0xFF7A7E9E), fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      UserService().clearCache();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                    icon: const Icon(Icons.logout, color: AppColors.lightGray, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<NavItem> customerNav = [
  NavItem(Icons.home_outlined, 'Home', '/customer'),
  NavItem(Icons.assignment_outlined, 'My Bookings', '/customer/services'),
  NavItem(Icons.local_shipping_outlined, 'Rental Store', '/customer/rentals'),
  NavItem(Icons.payment_outlined, 'Payments', '/customer/payments'),
  NavItem(Icons.history, 'Service History', '/customer/history'),
  NavItem(Icons.chat_bubble_outline, 'Chat', '/customer/chat'),
  NavItem(Icons.person_outline, 'Profile', '/customer/profile'),
];

const List<NavItem> adminNav = [
  NavItem(Icons.dashboard_outlined, 'Dashboard', '/admin'),
  NavItem(Icons.calendar_today_outlined, 'Appointments', '/admin/appointments'),
  NavItem(Icons.local_shipping_outlined, 'Rentals', '/admin/rentals'),
  NavItem(Icons.people_outline, 'Customer Accounts', '/admin/customers'),
  NavItem(Icons.schedule_outlined, 'Schedule Management', '/admin/schedule'),
  NavItem(Icons.history, 'Service History', '/admin/history'),
  NavItem(Icons.attach_money, 'Income & Expenses', '/admin/finance'),
  NavItem(Icons.inventory_2_outlined, 'Inventory', '/admin/inventory'),
  NavItem(Icons.engineering_outlined, 'Technician / Staff', '/admin/technicians'),
  NavItem(Icons.payments_outlined, 'Payroll', '/admin/payroll'),
  NavItem(Icons.account_balance_outlined, 'Payment Records', '/admin/payments'),
  NavItem(Icons.chat_bubble_outline, 'Chat', '/admin/chat'),
  NavItem(Icons.bar_chart_outlined, 'Reports', '/admin/reports'),
  NavItem(Icons.settings_outlined, 'Settings', '/admin/settings'),
];

const List<NavItem> technicianNav = [
  NavItem(Icons.dashboard_outlined, 'Dashboard', '/technician'),
  NavItem(Icons.assignment_outlined, 'Assigned Requests', '/technician/requests'),
  NavItem(Icons.calendar_today_outlined, 'Schedule', '/technician/schedule'),
  NavItem(Icons.history, 'Service History', '/technician/history'),
  NavItem(Icons.payments_outlined, 'Payroll', '/technician/payroll'),
  NavItem(Icons.person_outline, 'Profile', '/technician/profile'),
];
