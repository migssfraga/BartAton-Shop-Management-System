import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../services/user_service.dart';

class _Machine {
  final String id;
  final String name;
  final String model;
  final String capacity;
  final double pricePerDay;
  final bool available;
  final String type;

  const _Machine({
    required this.id,
    required this.name,
    required this.model,
    required this.capacity,
    required this.pricePerDay,
    required this.available,
    required this.type,
  });
}

class WashingMachineRentalScreen extends StatefulWidget {
  const WashingMachineRentalScreen({super.key});

  @override
  State<WashingMachineRentalScreen> createState() => _WashingMachineRentalScreenState();
}

class _WashingMachineRentalScreenState extends State<WashingMachineRentalScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _selectedCategory = 'All';

  static const List<_Machine> _machines = [
    _Machine(id: 'M001', name: 'Twin Tub Washer', model: 'BartAton TT-700', capacity: '7.0 kg', pricePerDay: 150.0, available: true, type: 'Top Load'),
    _Machine(id: 'M002', name: 'Fully Automatic', model: 'BartAton FA-850', capacity: '8.5 kg', pricePerDay: 220.0, available: true, type: 'Front Load'),
    _Machine(id: 'M003', name: 'Compact Washer', model: 'BartAton CW-500', capacity: '5.0 kg', pricePerDay: 120.0, available: true, type: 'Top Load'),
    _Machine(id: 'M004', name: 'Heavy Duty Dryer', model: 'BartAton HD-900', capacity: '9.0 kg', pricePerDay: 180.0, available: true, type: 'Dryer'),
  ];

  List<_Machine> get _filteredMachines {
    if (_selectedCategory == 'All') return _machines;
    return _machines.where((m) => m.type == _selectedCategory).toList();
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'dryer': return Icons.dry_cleaning_outlined;
      default: return Icons.local_laundry_service_outlined;
    }
  }

  void _showRentalForm(_Machine machine) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    int days = 1;
    String deliveryOption = 'Pick up';
    double deliveryFee = 50.0;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double totalPrice = (machine.pricePerDay * days) + (deliveryOption == 'Deliver' ? deliveryFee : 0);

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: SizedBox(width: 40, child: Divider(thickness: 4, color: AppColors.border))),
                  const SizedBox(height: 16),
                  Text('Rent ${machine.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  const Text('Start Date', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.gold, size: 18),
                          const SizedBox(width: 10),
                          Text('${selectedDate.month}/${selectedDate.day}/${selectedDate.year}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text('Number of Days', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _counterBtn(Icons.remove, () { if (days > 1) setModalState(() => days--); }),
                      Container(
                        width: 60,
                        alignment: Alignment.center,
                        child: Text('$days', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      _counterBtn(Icons.add, () { setModalState(() => days++); }),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text('Option', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Pick up', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: 'Pick up',
                          groupValue: deliveryOption,
                          activeColor: AppColors.gold,
                          onChanged: (v) => setModalState(() => deliveryOption = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Deliver', style: TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: const Text('+₱50', style: TextStyle(color: AppColors.gold, fontSize: 11)),
                          value: 'Deliver',
                          groupValue: deliveryOption,
                          activeColor: AppColors.gold,
                          onChanged: (v) => setModalState(() => deliveryOption = v!),
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(color: AppColors.border, height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Price', style: TextStyle(color: Colors.white, fontSize: 16)),
                      Text('₱${totalPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submitRental(machine, selectedDate, days, deliveryOption, totalPrice),
                      child: const Text('CONFIRM RENTAL'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.gold, size: 20),
      ),
    );
  }

  Future<void> _submitRental(_Machine machine, DateTime start, int days, String option, double total) async {
    final user = _auth.currentUser;
    final userData = await UserService().getCurrentUserData();
    final now = DateTime.now();
    final rentalId = 'RNT-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    await _firestore.collection('rentals').add({
      'rentalId': rentalId,
      'userId': user?.uid,
      'customerName': userData?['displayName'] ?? 'Customer',
      'machineName': machine.name,
      'model': machine.model,
      'startDate': '${start.month}/${start.day}/${start.year}',
      'days': days,
      'option': option,
      'totalPrice': '₱${total.toStringAsFixed(2)}',
      'status': 'Pending Approval',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Request Sent', style: TextStyle(color: Colors.white)),
        content: const Text('Your rental request has been sent to Admin for approval.', style: TextStyle(color: AppColors.lightGray)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: AppColors.gold)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Washing Machine Rental',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/customer'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(items: customerNav, activeRoute: '/customer/rentals'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('rentals').where('userId', isEqualTo: user?.uid).where('status', isEqualTo: 'Active').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Rental', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      _buildActiveRentalCard(snapshot.data!.docs.first.data() as Map<String, dynamic>),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const Text('Choose a Machine', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Top Load', 'Front Load', 'Dryer'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (v) => setState(() => _selectedCategory = cat),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.gold,
                      labelStyle: TextStyle(color: isSelected ? AppColors.background : AppColors.lightGray, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.gold : AppColors.border)),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            ..._filteredMachines.map((m) => _machineCard(m)),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gold.withOpacity(0.1))),
              child: Column(
                children: [
                  const Text('How it works', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _guideItem(Icons.touch_app_outlined, 'Select a machine and rental period'),
                  _guideItem(Icons.verified_user_outlined, 'Admin will confirm your request'),
                  _guideItem(Icons.local_shipping_outlined, 'Receive your machine at your doorstep'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRentalCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.gold.withOpacity(0.2), AppColors.surface]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.gold, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['machineName'] ?? 'Machine', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Ends on: ${data['startDate']}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
          const StatusBadge(status: 'Active'),
        ],
      ),
    );
  }

  Widget _guideItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.lightGray, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _machineCard(_Machine machine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                  child: Icon(_iconFor(machine.type), color: AppColors.gold, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(machine.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                      Text(machine.model, style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _featureTag(Icons.scale_outlined, machine.capacity),
                          const SizedBox(width: 8),
                          _featureTag(Icons.bolt, 'Eco'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daily Rate', style: TextStyle(color: AppColors.lightGray, fontSize: 11)),
                    Text('₱${machine.pricePerDay.toInt()}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _showRentalForm(machine),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('RENT NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lightGray, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 11)),
        ],
      ),
    );
  }
}
