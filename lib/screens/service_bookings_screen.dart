import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class ServiceBookingsScreen extends StatefulWidget {
  const ServiceBookingsScreen({super.key});

  @override
  State<ServiceBookingsScreen> createState() => _ServiceBookingsScreenState();
}

class _ServiceBookingsScreenState extends State<ServiceBookingsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'My Service Bookings',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/customer'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(items: customerNav, activeRoute: '/customer/services'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/customer/book-service'),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: const Text('Book a Service', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Bookings', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Track the status of your repair and installation requests.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('service_requests')
                    .where('userId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }
                  
                  final docs = snapshot.data?.docs ?? [];
                  // Filter out Completed/Cancelled
                  final activeDocs = docs.where((doc) {
                    final status = doc['status'] ?? '';
                    return status != 'Completed' && status != 'Cancelled';
                  }).toList();

                  if (activeDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, color: Colors.white.withOpacity(0.1), size: 80),
                          const SizedBox(height: 16),
                          Text('No active bookings', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: activeDocs.length,
                    itemBuilder: (context, index) {
                      final data = activeDocs[index].data() as Map<String, dynamic>;
                      return _buildBookingCard(data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
       ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'Pending';
    final tech = data['technician'] ?? 'Unassigned';
    final isApproved = status == 'Confirmed' || status == 'Assigned' || status == 'In Progress' || status == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isApproved ? AppColors.success.withOpacity(0.3) : AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(data['requestId'] ?? 'N/A', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 14),
          Text(data['service'] ?? 'Service', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 4),
          Text(data['appliance'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          const Divider(color: AppColors.border, height: 24),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(data['date'] ?? '', style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 14, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(data['time'] ?? '', style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tech != 'Unassigned' ? AppColors.gold.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.engineering_outlined, color: tech != 'Unassigned' ? AppColors.gold : Colors.white38, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assigned Technician', style: TextStyle(color: Color(0xFF7A7E9E), fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        tech != 'Unassigned' ? tech : 'Waiting for Admin assignment...',
                        style: TextStyle(
                          color: tech != 'Unassigned' ? AppColors.white : Colors.white54,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = AppColors.gold;
    if (status == 'Confirmed' || status == 'In Progress') color = AppColors.success;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
