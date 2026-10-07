import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/stat_card.dart';

class _InventoryItem {
  final String docId;
  final String id;
  String name;
  String category;
  int quantity;
  String unitPrice;
  String supplier;

  _InventoryItem({
    required this.docId,
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.supplier,
  });

  String get stockStatus {
    if (quantity <= 0) return 'Out of Stock';
    if (quantity <= 5) return 'Low Stock';
    return 'In Stock';
  }
}

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _seedDefaultInventoryIfEmpty();
  }

  Future<void> _seedDefaultInventoryIfEmpty() async {
    try {
      final snapshot = await _firestore.collection('inventory').limit(1).get();
      if (snapshot.docs.isEmpty) {
        final defaultItems = [
          {'id': 'INV-001', 'name': 'Drive Belt (Universal)', 'category': 'Washing Machine Parts', 'quantity': 24, 'unitPrice': '₱180', 'supplier': 'Metro Parts Supply'},
          {'id': 'INV-002', 'name': 'Water Inlet Valve', 'category': 'Washing Machine Parts', 'quantity': 4, 'unitPrice': '₱350', 'supplier': 'Metro Parts Supply'},
          {'id': 'INV-003', 'name': 'Compressor Relay', 'category': 'Refrigerator Parts', 'quantity': 0, 'unitPrice': '₱420', 'supplier': 'CoolTech Distributors'},
          {'id': 'INV-004', 'name': 'Heating Element', 'category': 'Dryer Parts', 'quantity': 12, 'unitPrice': '₱560', 'supplier': 'CoolTech Distributors'},
          {'id': 'INV-005', 'name': 'Door Gasket Seal', 'category': 'Washing Machine Parts', 'quantity': 3, 'unitPrice': '₱210', 'supplier': 'Metro Parts Supply'},
        ];
        for (var item in defaultItems) {
          await _firestore.collection('inventory').add(item);
        }
      }
    } catch (e) {
      debugPrint('Error seeding inventory: $e');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'In Stock':
        return AppColors.success;
      case 'Out of Stock':
        return AppColors.danger;
      default:
        return AppColors.warning;
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

  void _adjustStock(_InventoryItem item, bool isStockIn) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(isStockIn ? 'Stock In' : 'Stock Out', style: const TextStyle(color: AppColors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
            const SizedBox(height: 4),
            Text('Current quantity: ${item.quantity}',
                style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
          ),
          TextButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount <= 0) return;
              
              final newQty = isStockIn ? (item.quantity + amount) : (item.quantity - amount).clamp(0, 999999);

              await _firestore.collection('inventory').doc(item.docId).update({
                'quantity': newQty,
              });

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isStockIn ? 'Added' : 'Removed'} $amount ${item.name}. New quantity: $newQty'),
                    backgroundColor: AppColors.surfaceLight,
                  ),
                );
              }
            },
            child: const Text('Confirm', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openItemForm({_InventoryItem? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final categoryController = TextEditingController(text: existing?.category ?? '');
    final quantityController = TextEditingController(text: existing?.quantity.toString() ?? '0');
    final priceController = TextEditingController(text: existing?.unitPrice ?? '');
    final supplierController = TextEditingController(text: existing?.supplier ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(existing == null ? 'Add Item' : 'Edit Item',
            style: const TextStyle(color: AppColors.white, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Item name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoryController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Category'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Quantity'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Unit price (e.g. ₱180)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: supplierController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'Supplier'),
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
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final qty = int.tryParse(quantityController.text) ?? 0;
              
              if (existing != null) {
                await _firestore.collection('inventory').doc(existing.docId).update({
                  'name': nameController.text.trim(),
                  'category': categoryController.text.trim(),
                  'quantity': qty,
                  'unitPrice': priceController.text.trim(),
                  'supplier': supplierController.text.trim(),
                });
              } else {
                final snapshot = await _firestore.collection('inventory').get();
                final newId = 'INV-${(snapshot.docs.length + 1).toString().padLeft(3, '0')}';
                await _firestore.collection('inventory').add({
                  'id': newId,
                  'name': nameController.text.trim(),
                  'category': categoryController.text.trim(),
                  'quantity': qty,
                  'unitPrice': priceController.text.trim(),
                  'supplier': supplierController.text.trim(),
                });
              }

              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(existing == null ? 'Add' : 'Save',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteItem(_InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Item', style: TextStyle(color: AppColors.white, fontSize: 16)),
        content: Text('Remove "${item.name}" from inventory?',
            style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
          ),
          TextButton(
            onPressed: () async {
              await _firestore.collection('inventory').doc(item.docId).delete();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
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
        title: 'Inventory',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin/inventory',
        userName: 'Admin',
        userRole: 'Administrator',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        onPressed: () => _openItemForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('inventory').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            }

            final docs = snapshot.data?.docs ?? [];
            final items = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _InventoryItem(
                docId: doc.id,
                id: data['id'] ?? 'INV-000',
                name: data['name'] ?? '',
                category: data['category'] ?? '',
                quantity: data['quantity'] ?? 0,
                unitPrice: data['unitPrice'] ?? '',
                supplier: data['supplier'] ?? '',
              );
            }).toList();

            final filtered = _statusFilter == 'All'
                ? items
                : items.where((i) => i.stockStatus == _statusFilter).toList();

            final totalItems = items.length;
            final availableStock = items.where((i) => i.stockStatus == 'In Stock').length;
            final lowStock = items.where((i) => i.stockStatus == 'Low Stock').length;
            final outOfStock = items.where((i) => i.stockStatus == 'Out of Stock').length;

            final screenWidth = MediaQuery.of(context).size.width;
            int gridColumns = screenWidth >= 900 ? 4 : (screenWidth >= 600 ? 2 : 2);
            double cardAspectRatio = screenWidth >= 900 ? 1.6 : (screenWidth >= 600 ? 1.7 : 1.4);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                const Text('Inventory Management',
                    style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Track parts and supplies used for repairs in real-time.',
                    style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                const SizedBox(height: 20),

                GridView.count(
                  crossAxisCount: gridColumns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: cardAspectRatio,
                  children: [
                    StatCard(icon: Icons.inventory_2_outlined, label: 'Total Items', value: '$totalItems', caption: 'All parts'),
                    StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Available Stock',
                      value: '$availableStock',
                      caption: 'Items in stock',
                      iconBackground: const Color(0x332ECC71),
                      valueColor: AppColors.success,
                    ),
                    StatCard(
                      icon: Icons.warning_amber,
                      label: 'Low Stock',
                      value: '$lowStock',
                      caption: '5 or fewer left',
                      iconBackground: const Color(0x33FF8A3D),
                      valueColor: AppColors.warning,
                    ),
                    StatCard(
                      icon: Icons.remove_circle_outline,
                      label: 'Out of Stock',
                      value: '$outOfStock',
                      caption: 'Needs restocking',
                      iconBackground: const Color(0x33E74C3C),
                      valueColor: AppColors.danger,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'In Stock', 'Low Stock', 'Out of Stock'].map((f) {
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
                    child: Center(child: Text('No items found.', style: TextStyle(color: AppColors.lightGray))),
                  )
                else
                  ...filtered.map((item) => Padding(
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
                                  Text(item.id,
                                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                  _badge(item.stockStatus),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item.name,
                                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14.5)),
                              Text('${item.category} · ${item.supplier}',
                                  style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('Qty: ${item.quantity}',
                                      style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 14),
                                  Text(item.unitPrice,
                                      style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _adjustStock(item, true),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.success,
                                        side: const BorderSide(color: AppColors.success),
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Stock In', style: TextStyle(fontSize: 11.5)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _adjustStock(item, false),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.warning,
                                        side: const BorderSide(color: AppColors.warning),
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Stock Out', style: TextStyle(fontSize: 11.5)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    onPressed: () => _openItemForm(existing: item),
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.lightGray, size: 18),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteItem(item),
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                  ),
                                ],
                              ),
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
}
