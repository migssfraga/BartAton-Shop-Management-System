import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AdminPaymentRecordsScreen extends StatefulWidget {
  const AdminPaymentRecordsScreen({super.key});

  @override
  State<AdminPaymentRecordsScreen> createState() => _AdminPaymentRecordsScreenState();
}

class _AdminPaymentRecordsScreenState extends State<AdminPaymentRecordsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  String _statusFilter = 'All';

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Recent';
    return DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'Failed':
        return AppColors.danger;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Payment Records',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin/payments',
        userName: 'Admin',
        userRole: 'Administrator',
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('payments').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            }

            final docs = snapshot.data?.docs ?? [];
            
            // Sort client-side by createdAt descending
            docs.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

            final transactions = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': 'TXN-${doc.id.substring(0, 5).toUpperCase()}',
                'customer': data['customerName'] ?? 'Valued Customer',
                'type': data['description'] ?? 'Service Payment',
                'amount': data['amount'] ?? '₱0.00',
                'method': data['method'] ?? 'GCash',
                'date': _formatDate(data['createdAt'] as Timestamp?),
                'reference': data['reference'] ?? 'REF-N/A',
                'status': data['status'] ?? 'Completed',
              };
            }).toList();

            final filtered = _statusFilter == 'All'
                ? transactions
                : transactions.where((t) => t['status'] == _statusFilter).toList();

            final totalCount = transactions.length;
            final completedCount = transactions.where((t) => t['status'] == 'Completed').length;
            final pendingCount = transactions.where((t) => t['status'] == 'Pending').length;
            final failedCount = transactions.where((t) => t['status'] == 'Failed').length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Payment Records',
                    style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('All live transactions across the platform in real-time.',
                    style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                const SizedBox(height: 20),

                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width >= 900
                      ? 4
                      : (MediaQuery.of(context).size.width >= 600 ? 2 : 2),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: MediaQuery.of(context).size.width >= 900
                      ? 1.6
                      : (MediaQuery.of(context).size.width >= 600 ? 1.7 : 1.4),
                  children: [
                    _statCard('Total Payments', '$totalCount', AppColors.gold, Icons.receipt_long_outlined),
                    _statCard('Completed', '$completedCount', AppColors.success, Icons.check_circle_outline),
                    _statCard('Pending', '$pendingCount', AppColors.gold, Icons.hourglass_empty),
                    _statCard('Failed', '$failedCount', AppColors.danger, Icons.error_outline),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'Completed', 'Pending', 'Failed'].map((f) {
                      final isSelected = _statusFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
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
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Center(child: Text('No transactions found.', style: TextStyle(color: AppColors.lightGray))),
                  )
                else
                  ...filtered.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
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
                                  Text(t['id']!,
                                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                  _badge(t['status']!),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(t['customer']!,
                                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14.5)),
                              Text(t['type']!, style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet_outlined, size: 12, color: AppColors.lightGray),
                                  const SizedBox(width: 5),
                                  Text(t['method']!, style: const TextStyle(color: AppColors.lightGray, fontSize: 11.5)),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.calendar_today, size: 12, color: AppColors.lightGray),
                                  const SizedBox(width: 5),
                                  Text(t['date']!, style: const TextStyle(color: AppColors.lightGray, fontSize: 11.5)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Ref: ${t['reference']}', style: const TextStyle(color: Color(0xFF7A7E9E), fontSize: 11)),
                              const SizedBox(height: 10),
                              Text(t['amount']!,
                                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.lightGray, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
