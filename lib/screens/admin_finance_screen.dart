import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;

  double _totalIncome = 0;
  double _totalExpenses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);
    
    // 1. Calculate Income from Payments collection
    final paymentsSnapshot = await _firestore.collection('payments').get();
    double income = 0;
    for (var doc in paymentsSnapshot.docs) {
      final amountStr = doc.data()['amount']?.toString().replaceAll('₱', '').replaceAll(',', '') ?? '0';
      income += double.tryParse(amountStr) ?? 0;
    }

    // 2. Calculate Expenses from Expenses collection
    final expensesSnapshot = await _firestore.collection('expenses').get();
    double expenses = 0;
    for (var doc in expensesSnapshot.docs) {
      final amount = doc.data()['amount'] ?? 0;
      expenses += (amount is num) ? amount.toDouble() : 0;
    }

    if (mounted) {
      setState(() {
        _totalIncome = income;
        _totalExpenses = expenses;
        _isLoading = false;
      });
    }
  }

  void _openAddExpense() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Supplies';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Expense', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Expense Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Amount', prefixText: '₱ '),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: category,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                items: ['Supplies', 'Equipment', 'Salary', 'Maintenance', 'Others']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: isSaving ? null : (v) => setDialogState(() => category = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context), 
              child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray))
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                final title = titleController.text.trim();
                final amountText = amountController.text.trim();
                
                if (title.isEmpty || amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.')));
                  return;
                }

                setDialogState(() => isSaving = true);

                try {
                  await _firestore.collection('expenses').add({
                    'title': title,
                    'amount': double.tryParse(amountText) ?? 0,
                    'category': category,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadFinancialData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Expense saved successfully!'), backgroundColor: AppColors.success)
                    );
                  }
                } catch (e) {
                  setDialogState(() => isSaving = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.danger)
                    );
                  }
                }
              },
              child: isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                : const Text('SAVE EXPENSE'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeso(double v) => '₱${NumberFormat('#,###').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Finance',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(items: adminNav, activeRoute: '/admin/finance'),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
        : RefreshIndicator(
            onRefresh: _loadFinancialData,
            color: AppColors.gold,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Financial Overview', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // Main Stat Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.gold.withOpacity(0.15), AppColors.surface]),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('NET PROFIT', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Text(_formatPeso(_totalIncome - _totalExpenses), 
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    _miniStatCard('Income', _formatPeso(_totalIncome), AppColors.success, Icons.arrow_upward),
                    const SizedBox(width: 12),
                    _miniStatCard('Expenses', _formatPeso(_totalExpenses), AppColors.danger, Icons.arrow_downward),
                  ],
                ),

                const SizedBox(height: 40),
                const Text('Recent Transactions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Combined Transaction History (Income & Expenses)
                _buildCombinedHistory(),
              ],
            ),
          ),
    );
  }

  Widget _miniStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('payments').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (context, paySnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('expenses').orderBy('createdAt', descending: true).limit(5).snapshots(),
          builder: (context, expSnapshot) {
            if (paySnapshot.connectionState == ConnectionState.waiting || expSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox();
            }

            final payments = paySnapshot.data?.docs ?? [];
            final expenses = expSnapshot.data?.docs ?? [];
            
            // Merge and sort
            List<Map<String, dynamic>> all = [];
            for (var d in payments) {
              final data = d.data() as Map<String, dynamic>;
              all.add({...data, 'isIncome': true});
            }
            for (var d in expenses) {
              final data = d.data() as Map<String, dynamic>;
              all.add({...data, 'isIncome': false});
            }
            
            all.sort((a, b) {
              final tA = a['createdAt'] as Timestamp?;
              final tB = b['createdAt'] as Timestamp?;
              if (tA == null || tB == null) return 0;
              return tB.compareTo(tA);
            });

            if (all.isEmpty) {
              return Center(child: Text('No transactions recorded.', style: TextStyle(color: Colors.white.withOpacity(0.2))));
            }

            return Column(
              children: all.take(10).map((tx) {
                final isInc = tx['isIncome'] ?? false;
                final timestamp = tx['createdAt'] as Timestamp?;
                final date = timestamp != null ? DateFormat('MMM d').format(timestamp.toDate()) : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.02))),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: (isInc ? AppColors.success : AppColors.danger).withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(isInc ? Icons.add : Icons.remove, color: isInc ? AppColors.success : AppColors.danger, size: 16),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isInc ? (tx['description'] ?? 'Payment') : (tx['title'] ?? 'Expense'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            Text('$date • ${isInc ? (tx['method'] ?? 'GCash') : (tx['category'] ?? 'Others')}', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('${isInc ? '+' : '-'}${tx['isIncome'] ? tx['amount'] : _formatPeso(tx['amount'] ?? 0)}', 
                          style: TextStyle(color: isInc ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
