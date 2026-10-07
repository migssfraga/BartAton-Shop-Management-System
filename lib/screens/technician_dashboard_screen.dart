import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/stat_card.dart';
import '../services/user_service.dart';

class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  State<TechnicianDashboardScreen> createState() => _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  String _techName = 'Technician';
  String _queryName = '';
  bool _isLoading = true;
  
  int _assignedCount = 0;
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTechData();
  }

  Future<void> _loadTechData() async {
    final userData = await UserService().getCurrentUserData(forceRefresh: true);
    if (userData == null) return;
    
    final displayName = userData['displayName'] ?? 'Technician';

    // Fetch all requests for this tech from Firestore
    final assignedSnapshot = await _firestore.collection('service_requests').where('technician', isEqualTo: displayName).get();
    
    // Global pending (unassigned)
    final pendingSnapshot = await _firestore.collection('service_requests')
        .where('status', isEqualTo: 'Pending')
        .where('technician', isEqualTo: 'Unassigned')
        .get();

    if (mounted) {
      setState(() {
        _techName = userData['firstName'] ?? 'Technician';
        _queryName = displayName;
        
        // Active counts (excluding Completed/Cancelled)
        _assignedCount = assignedSnapshot.docs.where((d) => d['status'] == 'Pending' || d['status'] == 'Assigned' || d['status'] == 'Confirmed').length;
        _inProgressCount = assignedSnapshot.docs.where((d) => d['status'] == 'In Progress').length;
        _completedCount = assignedSnapshot.docs.where((d) => d['status'] == 'Completed').length;
        _pendingCount = pendingSnapshot.docs.length;
        
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int gridColumns = 2;
    double cardAspectRatio = 1.4;

    if (screenWidth >= 900) {
      gridColumns = 4;
      cardAspectRatio = 1.6;
    } else if (screenWidth >= 600) {
      gridColumns = 2;
      cardAspectRatio = 1.7;
    } else {
      gridColumns = 2;
      cardAspectRatio = 1.4;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF02040A),
      appBar: AppHeader(
        title: 'Technician Dashboard',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: technicianNav,
        activeRoute: '/technician',
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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    children: [
                      const TextSpan(text: 'Welcome back, '),
                      TextSpan(text: '$_techName!', style: const TextStyle(color: AppColors.gold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here are your assignments for today.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
                const SizedBox(height: 32),
                
                GridView.count(
                  crossAxisCount: gridColumns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: cardAspectRatio,
                  children: [
                    StatCard(icon: Icons.assignment, label: 'Assigned', value: '$_assignedCount', caption: 'Your jobs'),
                    StatCard(icon: Icons.access_time, label: 'Queue', value: '$_pendingCount', caption: 'Global pending'),
                    StatCard(
                      icon: Icons.build,
                      label: 'Progress',
                      value: '$_inProgressCount',
                      caption: 'Active now',
                      iconBackground: const Color(0x33FF8A3D),
                      valueColor: AppColors.warning,
                    ),
                    StatCard(
                      icon: Icons.check_circle,
                      label: 'Completed',
                      value: '$_completedCount',
                      caption: 'Total finished',
                      iconBackground: const Color(0x332ECC71),
                      valueColor: AppColors.success,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                const Text('Your Active Assignments',
                    style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 16),
                
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('service_requests')
                      .where('technician', isEqualTo: _queryName)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                    if (snapshot.hasError) return Center(child: Text('No active assignments.', style: TextStyle(color: Colors.white.withOpacity(0.3))));
                    final docs = snapshot.data?.docs ?? [];
                    final activeDocs = docs.where((d) {
                      final status = (d.data() as Map)['status'] ?? '';
                      return ['Pending', 'Assigned', 'In Progress', 'Confirmed'].contains(status);
                    }).toList();

                    if (activeDocs.isEmpty) return Center(child: Text('No active assignments.', style: TextStyle(color: Colors.white.withOpacity(0.3))));

                    return Column(
                      children: activeDocs.take(5).map((doc) {
                        final r = doc.data() as Map<String, dynamic>;
                        return _buildModernRequestTile(r);
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRequestTile(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151921).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['requestId'] ?? 'N/A',
                    style: const TextStyle(
                        color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Text(r['customerName'] ?? 'Unknown',
                    style: const TextStyle(
                        color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(r['service'] ?? 'Unknown Service', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          ),
          StatusBadge(status: r['status'] ?? 'Pending'),
        ],
      ),
    );
  }
}
