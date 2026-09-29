import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AdminServiceHistoryScreen extends StatefulWidget {
  const AdminServiceHistoryScreen({super.key});

  @override
  State<AdminServiceHistoryScreen> createState() => _AdminServiceHistoryScreenState();
}

class _AdminServiceHistoryScreenState extends State<AdminServiceHistoryScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  String _statusFilter = 'All';
  String _query = '';

  static const List<String> _statuses = [
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

  void _showDetails(Map<String, dynamic> r) {
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
                Text(r['requestId'] ?? 'N/A',
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15)),
                _badge(r['status'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 12),
            Text(r['service'] ?? 'Unknown',
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 16),
            _row('Customer', r['customerName'] ?? 'Unknown'),
            _row('Date', r['date'] ?? 'N/A'),
            _row('Technician', r['technician'] ?? 'Unassigned'),
            _row('Amount', r['amount'] ?? '₱0.00'),
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
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Service History',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin/history',
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
                  const Text('All service requests across every customer.',
                      style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.white, fontSize: 13.5),
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by customer, request ID or service...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.lightGray, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statuses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final f = _statuses[index];
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
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }
                  
                  var docs = snapshot.data?.docs ?? [];
                  
                  // Filter client-side for search and status
                  var filtered = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? '';
                    final name = (data['customerName'] ?? '').toString().toLowerCase();
                    final rid = (data['requestId'] ?? '').toString().toLowerCase();
                    final service = (data['service'] ?? '').toString().toLowerCase();
                    
                    final matchesStatus = _statusFilter == 'All' || status == _statusFilter;
                    final matchesQuery = _query.isEmpty ||
                        name.contains(_query.toLowerCase()) ||
                        rid.contains(_query.toLowerCase()) ||
                        service.contains(_query.toLowerCase());
                        
                    return matchesStatus && matchesQuery;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No records found.', style: TextStyle(color: AppColors.lightGray)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final r = filtered[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _showDetails(r),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r['requestId'] ?? 'N/A',
                                        style: const TextStyle(
                                            color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    _badge(r['status'] ?? 'N/A'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(r['service'] ?? 'Unknown',
                                    style: const TextStyle(
                                        color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14.5)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 12, color: AppColors.lightGray),
                                    const SizedBox(width: 4),
                                    Text(r['customerName'] ?? 'Unknown', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 12, color: AppColors.lightGray),
                                    const SizedBox(width: 5),
                                    Text(r['date'] ?? 'N/A', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                    const SizedBox(width: 14),
                                    const Icon(Icons.engineering, size: 12, color: AppColors.lightGray),
                                    const SizedBox(width: 5),
                                    Text(r['technician'] ?? 'Unassigned', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(r['amount'] ?? '₱0.00',
                                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
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
