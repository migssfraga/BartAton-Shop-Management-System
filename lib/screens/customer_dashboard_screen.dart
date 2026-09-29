import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../services/user_service.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _displayName = 'Customer';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await UserService().getCurrentUserData(forceRefresh: true);
    if (mounted && userData != null) {
      setState(() {
        _displayName = userData['firstName'] ?? 'Customer';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF02040A),
      appBar: AppHeader(
        title: 'Dashboard',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: customerNav,
        activeRoute: '/customer',
        userName: _displayName,
        userRole: 'Customer',
      ),
      body: Stack(
        children: [
          // Corner Decorations
          Positioned(
            top: -40,
            left: -60,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 250,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold.withOpacity(0.4), AppColors.gold.withOpacity(0.05)],
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -80,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: 300,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold.withOpacity(0.05), AppColors.gold.withOpacity(0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    children: [
                      const TextSpan(text: 'Welcome '),
                      TextSpan(text: 'Back, $_displayName!', style: const TextStyle(color: AppColors.gold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your services, appointments and rentals.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
                const SizedBox(height: 32),
                
                const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildQuickAction(
                      icon: Icons.ac_unit,
                      label: 'Aircon\nInstall',
                      onTap: () => Navigator.of(context).pushNamed('/customer/book-service'),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      icon: Icons.plumbing,
                      label: 'Washing\nRepair',
                      onTap: () => Navigator.of(context).pushNamed('/customer/book-service'),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAction(
                      icon: Icons.kitchen,
                      label: 'Fridge\nRepair',
                      onTap: () => Navigator.of(context).pushNamed('/customer/book-service'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Combined Service card
                _buildModernDashboardCard(
                  icon: Icons.assignment_outlined,
                  title: 'My Bookings',
                  subtitle: 'Track and manage your services',
                  onTap: () => Navigator.of(context).pushNamed('/customer/services'),
                ),
                const SizedBox(height: 16),
                _buildModernDashboardCard(
                  icon: Icons.local_shipping_outlined,
                  title: 'Rental Store',
                  subtitle: 'Rent washing machines and dryers',
                  onTap: () => Navigator.of(context).pushNamed('/customer/rentals'),
                ),
                const SizedBox(height: 16),
                _buildModernDashboardCard(
                  icon: Icons.payment_outlined,
                  title: 'Payments',
                  subtitle: 'Pay your bills and view records',
                  onTap: () => Navigator.of(context).pushNamed('/customer/payments'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.gold, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151921).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.gold, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.2), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
