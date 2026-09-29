import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AdminPayrollScreen extends StatefulWidget {
  const AdminPayrollScreen({super.key});

  @override
  State<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;

  String _peso(double v) => '₱${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return AppColors.success;
      case 'Processed':
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

  void _editPayrollRecord(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final basicController = TextEditingController(text: (data['basicSalary'] ?? 18000).toString());
    final allowancesController = TextEditingController(text: (data['allowances'] ?? 1500).toString());
    final overtimeController = TextEditingController(text: (data['overtime'] ?? 0).toString());
    final deductionsController = TextEditingController(text: (data['deductions'] ?? 1500).toString());
    String status = data['status'] ?? 'Draft';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final double basic = double.tryParse(basicController.text) ?? 0.0;
          final double allowances = double.tryParse(allowancesController.text) ?? 0.0;
          final double overtime = double.tryParse(overtimeController.text) ?? 0.0;
          final double deductions = double.tryParse(deductionsController.text) ?? 0.0;
          final double gross = basic + allowances + overtime;
          final double net = gross - deductions;

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Payroll: ${data['employee']}', style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(data['role'] ?? 'Technician', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  TextField(
                    controller: basicController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.white),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Basic Salary (₱)',
                      labelStyle: const TextStyle(color: AppColors.gold, fontSize: 13),
                      prefixIcon: const Icon(Icons.attach_money, color: AppColors.gold, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: allowancesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.white),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Allowances / Bonuses (₱)',
                      labelStyle: const TextStyle(color: AppColors.gold, fontSize: 13),
                      prefixIcon: const Icon(Icons.card_giftcard, color: AppColors.gold, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: overtimeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.white),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Overtime Pay (₱)',
                      labelStyle: const TextStyle(color: AppColors.gold, fontSize: 13),
                      prefixIcon: const Icon(Icons.timer_outlined, color: AppColors.gold, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: deductionsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.white),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Deductions (₱)',
                      labelStyle: const TextStyle(color: AppColors.danger, fontSize: 13),
                      prefixIcon: const Icon(Icons.money_off, color: AppColors.danger, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: ['Draft', 'Processed', 'Paid'].contains(status) ? status : 'Draft',
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      labelText: 'Payroll Status',
                      labelStyle: const TextStyle(color: AppColors.gold, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.background,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                    ),
                    items: ['Draft', 'Processed', 'Paid'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDialogState(() => status = v ?? 'Draft'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Gross:', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
                            Text(_peso(gross), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Net Pay:', style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(_peso(net), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.background),
                onPressed: () async {
                  await _firestore.collection('payroll').doc(doc.id).update({
                    'basicSalary': double.tryParse(basicController.text) ?? 0.0,
                    'allowances': double.tryParse(allowancesController.text) ?? 0.0,
                    'overtime': double.tryParse(overtimeController.text) ?? 0.0,
                    'deductions': double.tryParse(deductionsController.text) ?? 0.0,
                    'status': status,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payroll record updated successfully.'), backgroundColor: AppColors.surfaceLight),
                    );
                  }
                },
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _processAllPayroll(List<QueryDocumentSnapshot> docs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Process All Payroll', style: TextStyle(color: AppColors.white, fontSize: 16)),
        content: const Text(
          'This will update all draft payroll records to "Processed" and prepare them for disbursement. Continue?',
          style: TextStyle(color: AppColors.lightGray, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
          ),
          TextButton(
            onPressed: () async {
              final batch = _firestore.batch();
              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['status'] == 'Draft') {
                  batch.update(doc.reference, {'status': 'Processed', 'updatedAt': FieldValue.serverTimestamp()});
                }
              }
              await batch.commit();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All draft payrolls processed successfully.'), backgroundColor: AppColors.surfaceLight),
                );
              }
            },
            child: const Text('Confirm', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> r) {
    final double basic = (r['basicSalary'] ?? 0).toDouble();
    final double allowances = (r['allowances'] ?? 0).toDouble();
    final double overtime = (r['overtime'] ?? 0).toDouble();
    final double deductions = (r['deductions'] ?? 0).toDouble();
    final double gross = basic + allowances + overtime;
    final double net = gross - deductions;

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
                Text(r['employee'] ?? 'Employee', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                _badge(r['status'] ?? 'Draft'),
              ],
            ),
            Text(r['role'] ?? 'Technician', style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
            const SizedBox(height: 16),
            _row('Basic Salary', _peso(basic)),
            _row('Allowances', '+ ${_peso(allowances)}'),
            _row('Overtime', '+ ${_peso(overtime)}'),
            _row('Deductions', '- ${_peso(deductions)}'),
            const Divider(color: AppColors.border, height: 24),
            _row('Gross Salary', _peso(gross), bold: true),
            const SizedBox(height: 4),
            _row('Net Salary', _peso(net), bold: true, color: AppColors.gold),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
          Text(value,
              style: TextStyle(
                color: color ?? AppColors.white,
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Payroll',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin/payroll',
        userName: 'Admin',
        userRole: 'Administrator',
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('payroll').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            }

            final docs = snapshot.data?.docs ?? [];
            double totalNet = 0.0;

            final seenEmployees = <String>{};
            final uniqueDocs = <QueryDocumentSnapshot>[];

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final empName = (data['employee'] ?? '').toString().trim().toLowerCase();
              if (empName.isNotEmpty && !seenEmployees.contains(empName)) {
                seenEmployees.add(empName);
                uniqueDocs.add(doc);
              }
            }

            final records = uniqueDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final basic = (data['basicSalary'] ?? 0).toDouble();
              final allowances = (data['allowances'] ?? 0).toDouble();
              final overtime = (data['overtime'] ?? 0).toDouble();
              final deductions = (data['deductions'] ?? 0).toDouble();
              final gross = basic + allowances + overtime;
              final net = gross - deductions;
              totalNet += net;

              return {
                'doc': doc,
                'employee': data['employee'] ?? 'Employee',
                'role': data['role'] ?? 'Technician',
                'gross': gross,
                'net': net,
                'status': data['status'] ?? 'Draft',
                'data': data,
              };
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Payroll',
                    style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Manage real-time salaries for staff and technicians.',
                    style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Net Payroll (this period)',
                          style: TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
                      Text(_peso(totalNet), style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All records are fully synced & calculated live.'), backgroundColor: AppColors.surfaceLight),
                          );
                        },
                        icon: const Icon(Icons.calculate_outlined, size: 18),
                        label: const Text('Calculate', style: TextStyle(fontSize: 12.5)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.lightGray,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _processAllPayroll(docs),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Process', style: TextStyle(fontSize: 12.5)),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (records.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Text('No payroll records found.', style: TextStyle(color: AppColors.lightGray)),
                    ),
                  )
                else
                  ...records.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _viewDetails(r['data'] as Map<String, dynamic>),
                          onLongPress: () => _editPayrollRecord(r['doc'] as DocumentSnapshot),
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
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r['employee'] as String,
                                            style: const TextStyle(
                                                color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                                        Text(r['role'] as String, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _badge(r['status'] as String),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.lightGray),
                                          onPressed: () => _editPayrollRecord(r['doc'] as DocumentSnapshot),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Gross: ${_peso(r['gross'] as double)}',
                                        style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                    Text('Net: ${_peso(r['net'] as double)}',
                                        style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
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
}
