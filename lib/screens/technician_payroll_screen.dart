import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../services/user_service.dart';

class TechnicianPayrollScreen extends StatefulWidget {
  const TechnicianPayrollScreen({super.key});

  @override
  State<TechnicianPayrollScreen> createState() => _TechnicianPayrollScreenState();
}

class _TechnicianPayrollScreenState extends State<TechnicianPayrollScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;

  String _techDisplayName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTechInfo();
  }

  Future<void> _loadTechInfo() async {
    final userData = await UserService().getCurrentUserData(forceRefresh: true);
    if (mounted && userData != null) {
      setState(() {
        _techDisplayName = userData['displayName'] ?? userData['firstName'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _peso(double v) => '₱${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  void _showDetails(Map<String, dynamic> r, int completedCount) {
    final double basic = completedCount > 0 ? (r['basicSalary'] ?? 0).toDouble() : 0.0;
    final double allowances = completedCount > 0 ? (r['allowances'] ?? 0).toDouble() : 0.0;
    final double overtime = completedCount > 0 ? (r['overtime'] ?? 0).toDouble() : 0.0;
    final double deductions = completedCount > 0 ? (r['deductions'] ?? 0).toDouble() : 0.0;
    final double gross = basic + allowances + overtime;
    final double net = gross - deductions;
    final status = r['status'] ?? 'Draft';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Salary Breakdown', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                _badge(completedCount > 0 ? status : 'Pending Work'),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow('Basic Salary', _peso(basic)),
            _detailRow('Allowances', '+ ${_peso(allowances)}'),
            _detailRow('Overtime', '+ ${_peso(overtime)}'),
            _detailRow('Deductions', '- ${_peso(deductions)}'),
            const Divider(color: AppColors.border, height: 24),
            _detailRow('Gross Total', _peso(gross), isBold: true),
            _detailRow('Net Pay', _peso(net), isBold: true, color: AppColors.gold),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
          Text(value,
              style: TextStyle(
                color: color ?? AppColors.white,
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _badge(String status) {
    Color color = status == 'Paid' ? AppColors.success : status == 'Processed' ? AppColors.warning : AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        title: 'Payroll & Earnings',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/technician'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: technicianNav,
        activeRoute: '/technician/payroll',
        userName: _techDisplayName,
        userRole: 'Technician',
      ),
      body: SafeArea(
        child: _isLoading || _techDisplayName.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('payroll')
                    .where('employee', isEqualTo: _techDisplayName)
                    .snapshots(),
                builder: (context, payrollSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('service_requests')
                        .where('technician', isEqualTo: _techDisplayName)
                        .snapshots(),
                    builder: (context, requestSnapshot) {
                      if (payrollSnapshot.connectionState == ConnectionState.waiting ||
                          requestSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                      }

                      final docs = payrollSnapshot.data?.docs ?? [];
                      final requests = requestSnapshot.data?.docs ?? [];
                      final completedJobsCount = requests.where((d) => (d.data() as Map)['status'] == 'Completed').length;

                      if (docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Text('No payroll records found for $_techDisplayName.',
                                style: const TextStyle(color: AppColors.lightGray), textAlign: TextAlign.center),
                          ),
                        );
                      }

                      docs.sort((a, b) {
                        final aTime = (a.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
                        final bTime = (b.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
                        if (aTime == null || bTime == null) return 0;
                        return bTime.compareTo(aTime);
                      });

                      final currentDoc = docs.first;
                      final currentData = currentDoc.data() as Map<String, dynamic>;
                      
                      // If no completed jobs yet, force earnings to ₱0!
                      final double basic = completedJobsCount > 0 ? (currentData['basicSalary'] ?? 0).toDouble() : 0.0;
                      final double allowances = completedJobsCount > 0 ? (currentData['allowances'] ?? 0).toDouble() : 0.0;
                      final double overtime = completedJobsCount > 0 ? (currentData['overtime'] ?? 0).toDouble() : 0.0;
                      final double deductions = completedJobsCount > 0 ? (currentData['deductions'] ?? 0).toDouble() : 0.0;
                      final double gross = basic + allowances + overtime;
                      final double net = gross - deductions;
                      final currentStatus = completedJobsCount > 0 ? (currentData['status'] ?? 'Draft') : 'No Completed Jobs';

                      final historyDocs = docs.length > 1 ? docs.sublist(1) : <QueryDocumentSnapshot>[];

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text('Payroll & Earnings',
                              style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Review your real-time salary breakdown and history.',
                              style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                          const SizedBox(height: 24),

                          // ---- Current Period Summary ----
                          const Text('CURRENT PERIOD (ESTIMATED)',
                              style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.surfaceLight, AppColors.surface],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Current Pay Period', style: TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
                                    _badge(currentStatus),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text('Estimated Net Pay', style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(_peso(net),
                                    style: const TextStyle(color: AppColors.gold, fontSize: 32, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                const Divider(color: AppColors.border),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _summaryStat('Gross', _peso(gross)),
                                    Container(width: 1, height: 24, color: AppColors.border),
                                    _summaryStat('Deductions', _peso(deductions)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ---- History Section ----
                          const Text('PAYROLL HISTORY',
                              style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          if (historyDocs.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('No previous payroll history.', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                              ),
                            )
                          else
                            ...historyDocs.map((doc) {
                              final hData = doc.data() as Map<String, dynamic>;
                              final hBasic = completedJobsCount > 0 ? (hData['basicSalary'] ?? 0).toDouble() : 0.0;
                              final hAllowances = completedJobsCount > 0 ? (hData['allowances'] ?? 0).toDouble() : 0.0;
                              final hOvertime = completedJobsCount > 0 ? (hData['overtime'] ?? 0).toDouble() : 0.0;
                              final hDeductions = completedJobsCount > 0 ? (hData['deductions'] ?? 0).toDouble() : 0.0;
                              final hNet = (hBasic + hAllowances + hOvertime) - hDeductions;
                              final hStatus = completedJobsCount > 0 ? (hData['status'] ?? 'Processed') : 'No Completed Jobs';
                              final timestamp = hData['updatedAt'] as Timestamp?;
                              final dateStr = timestamp != null ? '${timestamp.toDate().month}/${timestamp.toDate().day}/${timestamp.toDate().year}' : 'Recent Period';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => _showDetails(hData, completedJobsCount),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Period: $dateStr',
                                                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                            const SizedBox(height: 4),
                                            Text('Net Pay: ${_peso(hNet)}',
                                                style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
                                          ],
                                        ),
                                        _badge(hStatus),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _summaryStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF7A7E9E), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
