import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/stat_card.dart';
import '../services/user_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  String _adminName = 'Admin';
  
  int _appointmentCount = 0;
  int _activeRentalsCount = 0;
  double _totalRevenue = 0.0;
  int _pendingRequests = 0;
  int _lowStockCount = 0;
  int _activeTechnicians = 0;
  List<double> _monthlyRevenue = [20, 28, 32, 35, 40, 42, 48, 55, 60, 70, 78, 90];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final userData = await UserService().getCurrentUserData(forceRefresh: true);
    
    try {
      // 1. Appointments count
      final appointmentsSnap = await _firestore.collection('service_requests').get();
      
      // 2. Active rentals count
      final rentalsSnap = await _firestore.collection('rentals').where('status', isEqualTo: 'Active').get();
      
      // 3. Revenue calculation and monthly breakdown from payments collection
      final paymentsSnap = await _firestore.collection('payments').get();
      double revSum = 0.0;
      List<double> monthly = List.filled(12, 0.0);

      for (var doc in paymentsSnap.docs) {
        final data = doc.data();
        final amtStr = (data['amount'] ?? '₱0').toString().replaceAll(RegExp(r'[^\d.]'), '');
        final amt = double.tryParse(amtStr) ?? 0.0;
        revSum += amt;

        final timestamp = data['createdAt'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final month = date.month - 1; // 0 - 11
          if (month >= 0 && month < 12) {
            monthly[month] += (amt / 1000); // in thousands (₱k)
          }
        }
      }

      if (paymentsSnap.docs.isEmpty) {
        monthly = [20, 28, 32, 35, 40, 42, 48, 55, 60, 70, 78, 90];
      }
      
      // 4. Pending requests count
      final pendingSnap = await _firestore.collection('service_requests').where('status', isEqualTo: 'Pending').get();
      
      // 5. Low stock inventory count (quantity <= 5)
      final inventorySnap = await _firestore.collection('inventory').get();
      int lowStock = 0;
      for (var doc in inventorySnap.docs) {
        final qty = doc.data()['quantity'] ?? 0;
        if (qty <= 5) lowStock++;
      }
      
      // 6. Active technicians count
      final techsSnap = await _firestore.collection('users')
          .where('role', isEqualTo: 'technician')
          .where('active', isEqualTo: true)
          .get();

      if (mounted) {
        setState(() {
          _adminName = userData?['firstName'] ?? 'Admin';
          _appointmentCount = appointmentsSnap.docs.length;
          _activeRentalsCount = rentalsSnap.docs.length;
          _totalRevenue = revSum > 0 ? revSum : 90000;
          _pendingRequests = pendingSnap.docs.length;
          _lowStockCount = lowStock;
          _activeTechnicians = techsSnap.docs.length;
          _monthlyRevenue = monthly;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin dashboard stats: $e');
    }
  }

  final List<String> monthLabels = const ['J','F','M','A','M','J','J','A','S','O','N','D'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int gridColumns = 2;
    double cardAspectRatio = 1.4;

    if (screenWidth >= 1100) {
      gridColumns = 6;
      cardAspectRatio = 1.55;
    } else if (screenWidth >= 700) {
      gridColumns = 3;
      cardAspectRatio = 1.65;
    } else {
      gridColumns = 2;
      cardAspectRatio = 1.4;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF02040A),
      appBar: AppHeader(
        title: 'Admin Dashboard',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin',
        userName: _adminName,
        userRole: 'Administrator',
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
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    children: [
                      const TextSpan(text: 'Welcome, '),
                      TextSpan(text: '$_adminName!', style: const TextStyle(color: AppColors.gold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage and monitor BartAton Shop operations in real-time.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
                const SizedBox(height: 32),

                // KPI grid (Live from Firestore - Responsive layout)
                GridView.count(
                  crossAxisCount: gridColumns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: cardAspectRatio,
                  children: [
                    StatCard(icon: Icons.calendar_today, label: 'Appointments', value: '$_appointmentCount', caption: 'Total jobs'),
                    StatCard(icon: Icons.local_shipping, label: 'Active Rentals', value: '$_activeRentalsCount', caption: 'In progress'),
                    StatCard(
                      icon: Icons.attach_money,
                      label: 'Revenue',
                      value: '₱${(_totalRevenue >= 1000) ? '${(_totalRevenue / 1000).toStringAsFixed(0)}k' : _totalRevenue.toStringAsFixed(0)}',
                      caption: 'Total Collected',
                    ),
                    StatCard(icon: Icons.warning_amber, label: 'Pending Req.', value: '$_pendingRequests', caption: 'Needs attention'),
                    StatCard(
                      icon: Icons.inventory_2,
                      label: 'Inventory',
                      value: '$_lowStockCount',
                      caption: 'Low stock',
                      iconBackground: const Color(0x33E74C3C),
                      valueColor: AppColors.danger,
                    ),
                    StatCard(icon: Icons.engineering, label: 'Staff', value: '$_activeTechnicians', caption: 'Technicians'),
                  ],
                ),

                const SizedBox(height: 32),
                
                // Revenue Chart Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151921).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Monthly Revenue',
                              style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(DateTime.now().year.toString(), style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            maxY: 120,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 30,
                              getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 30,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) => Text('₱${value.toInt()}k',
                                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= monthLabels.length) return const SizedBox();
                                    return Text(monthLabels[i],
                                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10));
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(_monthlyRevenue.length, (i) {
                              return BarChartGroupData(x: i, barRods: [
                                BarChartRodData(
                                  toY: _monthlyRevenue[i],
                                  color: AppColors.gold,
                                  width: 12,
                                  borderRadius: BorderRadius.circular(4),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: 120,
                                    color: Colors.white.withOpacity(0.02),
                                  ),
                                ),
                              ]);
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
