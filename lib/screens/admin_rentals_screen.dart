import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class _Machine {
  String id;
  String name;
  String model;
  String capacity;
  String pricePerDay;
  bool available;

  _Machine({
    required this.id,
    required this.name,
    required this.model,
    required this.capacity,
    required this.pricePerDay,
    required this.available,
  });
}

class AdminRentalsScreen extends StatefulWidget {
  const AdminRentalsScreen({super.key});

  @override
  State<AdminRentalsScreen> createState() => _AdminRentalsScreenState();
}

class _AdminRentalsScreenState extends State<AdminRentalsScreen> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tabController;
  final _firestore = FirebaseFirestore.instance;

  // For now, machines are semi-static but manageable via Admin
  final List<_Machine> _machines = [
    _Machine(id: 'M001', name: 'Twin Tub Washer', model: 'BartAton TT-700', capacity: '7.0 kg', pricePerDay: '₱150', available: true),
    _Machine(id: 'M002', name: 'Fully Automatic Washer', model: 'BartAton FA-850', capacity: '8.5 kg', pricePerDay: '₱220', available: false),
    _Machine(id: 'M003', name: 'Compact Washer', model: 'BartAton CW-500', capacity: '5.0 kg', pricePerDay: '₱120', available: true),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
      case 'Returned':
        return AppColors.success;
      case 'Overdue':
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

  Future<void> _updateRentalStatus(String docId, String newStatus) async {
    await _firestore.collection('rentals').doc(docId).update({'status': newStatus});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: AppColors.surfaceLight));
    }
  }

  void _openMachineForm({_Machine? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final modelController = TextEditingController(text: existing?.model ?? '');
    final capacityController = TextEditingController(text: existing?.capacity ?? '');
    final priceController = TextEditingController(text: existing?.pricePerDay ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(existing == null ? 'Add Machine' : 'Edit Machine',
            style: const TextStyle(color: AppColors.white, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Machine name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: modelController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Model'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: capacityController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Capacity (e.g. 7.0 kg)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Price per day (e.g. ₱150)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              setState(() {
                if (existing != null) {
                  existing.name = nameController.text.trim();
                  existing.model = modelController.text.trim();
                  existing.capacity = capacityController.text.trim();
                  existing.pricePerDay = priceController.text.trim();
                } else {
                  _machines.add(_Machine(
                    id: 'M${(_machines.length + 1).toString().padLeft(3, '0')}',
                    name: nameController.text.trim(),
                    model: modelController.text.trim(),
                    capacity: capacityController.text.trim(),
                    pricePerDay: priceController.text.trim(),
                    available: true,
                  ));
                }
              });
              Navigator.of(context).pop();
            },
            child: Text(existing == null ? 'Add' : 'Save',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteMachine(_Machine machine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Machine', style: TextStyle(color: AppColors.white, fontSize: 16)),
        content: Text('Remove "${machine.name}" from inventory?',
            style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _machines.remove(machine));
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
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
        title: 'Rental Management',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(items: adminNav, activeRoute: '/admin/rentals'),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.background,
            onPressed: () => _openMachineForm(),
            child: const Icon(Icons.add),
          );
        },
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
                  const Text('Rental Management', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Manage machines and track active rentals.', style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
                indicatorPadding: const EdgeInsets.all(4),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.background,
                unselectedLabelColor: AppColors.lightGray,
                tabs: const [Tab(text: 'Machines'), Tab(text: 'Active Rentals')],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildMachinesTab(), _buildRentalsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachinesTab() {
    if (_machines.isEmpty) {
      return const Center(child: Text('No machines yet.', style: TextStyle(color: AppColors.lightGray)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: _machines.length,
      itemBuilder: (context, index) {
        final m = _machines[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.local_laundry_service_outlined, color: AppColors.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name,
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${m.model} · ${m.capacity}',
                          style: const TextStyle(color: AppColors.lightGray, fontSize: 11.5)),
                      Row(
                        children: [
                          Text('${m.pricePerDay}/day',
                              style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12.5)),
                          const SizedBox(width: 8),
                          _badge(m.available ? 'Available' : 'Rented'),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openMachineForm(existing: m),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.lightGray, size: 19),
                ),
                IconButton(
                  onPressed: () => _deleteMachine(m),
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 19),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRentalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('rentals').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No rentals found.', style: TextStyle(color: AppColors.lightGray)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final r = doc.data() as Map<String, dynamic>;
            final status = r['status'] ?? 'Pending Approval';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r['rentalId'] ?? 'N/A', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13)),
                      _badge(status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(r['machineName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Customer: ${r['customerName']}', style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
                  const SizedBox(height: 8),
                  _infoRow(Icons.calendar_today, 'Start: ${r['startDate']} (${r['days']} days)'),
                  _infoRow(Icons.local_shipping_outlined, 'Option: ${r['option']}'),
                  const Divider(color: AppColors.border, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r['totalPrice'] ?? '₱0.00', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      if (status == 'Pending Approval')
                        ElevatedButton(
                          onPressed: () => _updateRentalStatus(doc.id, 'Active'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                          child: const Text('APPROVE'),
                        )
                      else if (status == 'Active')
                        OutlinedButton(
                          onPressed: () => _updateRentalStatus(doc.id, 'Returned'),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border)),
                          child: const Text('PROCESS RETURN', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
        ],
      ),
    );
  }
}
