import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../services/user_service.dart';

class TechnicianServiceHistoryScreen extends StatefulWidget {
  const TechnicianServiceHistoryScreen({super.key});

  @override
  State<TechnicianServiceHistoryScreen> createState() => _TechnicianServiceHistoryScreenState();
}

class _TechnicianServiceHistoryScreenState extends State<TechnicianServiceHistoryScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  String _query = '';
  String _statusFilter = 'All';
  String _techDisplayName = '';

  static const List<String> _filters = ['All', 'Completed', 'In Progress', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadTechInfo();
  }

  Future<void> _loadTechInfo() async {
    final userData = await UserService().getCurrentUserData();
    if (mounted && userData != null) {
      setState(() {
        _techDisplayName = userData['displayName'] ?? '';
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.danger;
      case 'In Progress':
        return AppColors.warning;
      default:
        return AppColors.gold;
    }
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
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _detailRow('Customer', r['customerName'] ?? 'Unknown'),
            _detailRow('Date', r['date'] ?? 'N/A'),
            _detailRow('Address', r['address'] ?? 'N/A'),
            _detailRow('Amount', r['amount'] ?? '₱0.00'),
            const SizedBox(height: 12),
            const Text('Notes', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
            const SizedBox(height: 4),
            Text(r['problem'] ?? 'No problem description.', style: const TextStyle(color: AppColors.white, fontSize: 13, height: 1.4)),
            if ((r['notes'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Admin/Technician Notes', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
              Text(r['notes'], style: const TextStyle(color: AppColors.white, fontSize: 13, height: 1.4)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
            Text(value, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _badge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Service History',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/technician'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: technicianNav,
        activeRoute: '/technician/history',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Service History',
                      style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Review your past and completed service tasks.',
                      style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.white, fontSize: 14),
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search customer or service...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.lightGray, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
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
            Expanded(
              child: _techDisplayName.isEmpty 
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('service_requests')
                    .where('technician', isEqualTo: _techDisplayName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }
                  
                  var docs = snapshot.data?.docs ?? [];

                  // Sort client-side by createdAt descending to avoid index errors
                  docs.sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    if (aTime == null || bTime == null) return 0;
                    return bTime.compareTo(aTime);
                  });
                  
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
                                Text(r['customerName'] ?? 'Unknown', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 12, color: AppColors.lightGray),
                                        const SizedBox(width: 5),
                                        Text(r['date'] ?? 'N/A', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                      ],
                                    ),
                                    Text(r['amount'] ?? '₱0.00',
                                        style: const TextStyle(
                                            color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
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
