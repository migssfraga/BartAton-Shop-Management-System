import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _statusFilter = 'All';

  static const List<String> _filters = [
    'All', 'Pending', 'Confirmed', 'Assigned', 'In Progress', 'Completed', 'Cancelled',
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.danger;
      case 'In Progress':
      case 'Assigned':
        return AppColors.warning;
      default:
        return AppColors.gold;
    }
  }

  Widget _badge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  void _showDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['requestId'] ?? 'N/A',
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15)),
                _badge(data['status'] ?? 'Pending'),
              ],
            ),
            const SizedBox(height: 12),
            Text(data['service'] ?? 'Unknown Service',
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 16),
            _row('Date', data['date'] ?? 'N/A'),
            _row('Technician', data['technician'] ?? 'Unassigned'),
            _row('Amount', data['amount'] ?? '₱0.00'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.lightGray,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
            Text(value, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Service History',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/customer'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: customerNav,
        activeRoute: '/customer/history',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Service History',
                      style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Track the status of your past and ongoing requests.',
                      style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final f = _filters[index];
                        final isSelected = _statusFilter == f;
                        return ChoiceChip(
                          label: Text(f),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _statusFilter = f),
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.gold,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.background : AppColors.lightGray,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? AppColors.gold : AppColors.border),
                          ),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('service_requests')
                    .where('userId', isEqualTo: user?.uid)
                    // Tinanggal ang orderBy dito para hindi na kailangan ng Index
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }

                  // Sa app na lang tayo mag-sort (Client-side sorting)
                  final docs = snapshot.data?.docs ?? [];
                  final sortedDocs = List.from(docs);
                  sortedDocs.sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    if (aTime == null || bTime == null) return 0;
                    return bTime.compareTo(aTime); // Descending order
                  });

                  final filteredDocs = _statusFilter == 'All' 
                    ? sortedDocs 
                    : sortedDocs.where((doc) => doc['status'] == _statusFilter).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text('No records found.', style: TextStyle(color: AppColors.lightGray)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'Pending';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showDetails(data),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(data['requestId'] ?? 'N/A',
                                          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13)),
                                      _badge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(data['service'] ?? 'Service',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: AppColors.lightGray),
                                      const SizedBox(width: 6),
                                      Text(data['date'] ?? 'N/A', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                      const SizedBox(width: 16),
                                      if (data['technician'] != 'Unassigned') ...[
                                        const Icon(Icons.engineering_outlined, size: 14, color: AppColors.lightGray),
                                        const SizedBox(width: 6),
                                        Text(data['technician'] ?? '', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                      ],
                                    ],
                                  ),
                                  const Divider(color: AppColors.border, height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(data['amount'] ?? '₱0.00',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                      const Row(
                                        children: [
                                          Text('Details', style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600)),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gold, size: 12),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
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
}
