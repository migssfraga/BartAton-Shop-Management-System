import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;

  String _statusFilter = 'All';

  List<String> _technicians = [];
  static const List<String> _statuses = [
    'Pending', 'Confirmed', 'Assigned', 'In Progress', 'Completed', 'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    final snapshot = await _firestore.collection('users').get();
    
    if (mounted) {
      setState(() {
        _technicians = snapshot.docs
            .where((doc) {
              final data = doc.data();
              final role = data['role']?.toString().toLowerCase();
              final active = data['active'] ?? true;
              return role == 'technician' && active == true;
            })
            .map((doc) => doc.data()['displayName'] as String? ?? 'Unknown Tech')
            .toList();
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'Confirmed':
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

  Future<void> _updateStatus(String docId, String status) async {
    await _firestore.collection('service_requests').doc(docId).update({'status': status});
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status.'), backgroundColor: AppColors.surfaceLight),
      );
    }
  }

  void _assignTechnician(String docId, String currentStatus) {
    if (_technicians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No technicians registered in the system.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Assign Technician', style: TextStyle(color: AppColors.white, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _technicians.length,
            itemBuilder: (context, index) {
              final t = _technicians[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.engineering, color: AppColors.gold, size: 20),
                title: Text(t, style: const TextStyle(color: AppColors.white, fontSize: 14)),
                onTap: () async {
                  await _firestore.collection('service_requests').doc(docId).update({
                    'technician': t,
                    'status': 'Pending', // Keep as pending until tech accepts
                  });
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Technician $t assigned. Waiting for approval.'), backgroundColor: AppColors.surfaceLight),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
          ),
        ],
      ),
    );
  }

  Future<void> _setBiling(String docId, Map<String, dynamic> data) {
    final priceController = TextEditingController(text: (data['amount'] ?? '').toString().replaceAll(RegExp(r'[^\d.]'), ''));
    String allowedMethod = data['paymentMethodAllowed'] ?? 'GCash Only';

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Set Billing & Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter the service fee and select allowed payment methods for this customer.',
                  style: TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Bill Amount (₱)',
                  labelStyle: const TextStyle(color: AppColors.gold, fontSize: 13),
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.gold, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Allowed Payment Method', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: ['GCash Only', 'GCash or Cash'].contains(allowedMethod) ? allowedMethod : 'GCash Only',
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                ),
                items: ['GCash Only', 'GCash or Cash'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDialogState(() => allowedMethod = v ?? 'GCash Only'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.background),
              onPressed: () async {
                final amountText = priceController.text.trim();
                if (amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid bill amount.'), backgroundColor: AppColors.danger),
                  );
                  return;
                }

                await _firestore.collection('service_requests').doc(docId).update({
                  'amount': '₱$amountText',
                  'paymentMethodAllowed': allowedMethod,
                  'isBilled': true,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Billing successfully set and sent to customer!'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('UPDATE BILL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) {
        return Padding(
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
                  Text(data['requestId'] ?? 'N/A', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15)),
                  _badge(data['status'] ?? 'Pending'),
                ],
              ),
              const SizedBox(height: 12),
              Text(data['service'] ?? 'Unknown',
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 16),
              _detailRow(Icons.person_outline, 'Customer', data['customerName'] ?? 'Unknown'),
              _detailRow(Icons.attach_money, 'Bill Amount', data['amount'] ?? 'Not set'),
              _detailRow(Icons.payment, 'Payment Type', data['paymentMethodAllowed'] ?? 'Not set'),
              _detailRow(Icons.calendar_today, 'Date', data['date'] ?? 'N/A'),
              _detailRow(Icons.access_time, 'Time', data['time'] ?? 'N/A'),
              _detailRow(Icons.location_on_outlined, 'Address', data['address'] ?? 'N/A'),
              
              if (data['service'] == 'Aircon Installation') ...[
                const Divider(color: AppColors.border, height: 24),
                const Text('AIRCON SPECIFICATIONS', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 12),
                _detailRow(Icons.ac_unit, 'Unit Type', data['airconType'] ?? 'N/A'),
                _detailRow(Icons.bolt, 'Horse Power', data['horsePower'] ?? 'N/A'),
                _detailRow(Icons.settings, 'Task', data['installTask'] ?? 'N/A'),
              ],

              if (data['hasPhoto'] == true) ...[
                const Divider(color: AppColors.border, height: 24),
                const Text('ATTACHED PHOTO', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, color: Colors.white24, size: 40),
                        SizedBox(height: 8),
                        Text('Photo Attached by Customer', style: TextStyle(color: Colors.white24, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _setBiling(doc.id, data),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.gold), foregroundColor: AppColors.gold),
                      child: const Text('SET BILLING'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(doc.id, 'Confirmed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Approve', style: TextStyle(fontSize: 12.5)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(doc.id, 'Cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Reject', style: TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _assignTechnician(doc.id, data['status'] ?? 'Pending'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('Assign Tech.', style: TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, 
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
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
        title: 'Appointments',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin/appointments',
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
                  const Text('Appointments',
                      style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Review, approve and assign customer appointments.',
                      style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                  const SizedBox(height: 16),

                  // Status Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statuses.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final label = index == 0 ? 'All' : _statuses[index - 1];
                        final isSelected = _statusFilter == label;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _statusFilter = label),
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
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.gold));

                  // Filter client-side
                  final docs = snapshot.data?.docs ?? [];
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? '';
                    
                    if (_statusFilter == 'All') {
                      // Hide Completed and Cancelled from the main active list
                      return status != 'Completed' && status != 'Cancelled';
                    }
                    return status == _statusFilter;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text('No appointments found.', style: TextStyle(color: AppColors.lightGray)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _openDetails(doc),
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
                                    Text(data['requestId'] ?? 'N/A',
                                        style: const TextStyle(
                                            color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    _badge(data['status'] ?? 'Pending'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(data['customerName'] ?? 'Unknown',
                                    style: const TextStyle(
                                        color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14.5)),
                                Text(data['service'] ?? 'Unknown', style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 12, color: AppColors.lightGray),
                                    const SizedBox(width: 5),
                                    Text('${data['date']} · ${data['time']}',
                                        style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                    const SizedBox(width: 14),
                                    const Icon(Icons.engineering, size: 12, color: AppColors.lightGray),
                                    const SizedBox(width: 5),
                                    Text(data['technician'] ?? 'Unassigned', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
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
