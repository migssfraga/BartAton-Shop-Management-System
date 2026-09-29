import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _serviceLabel = '';
  String _customerName = '';
  String _referenceNumber = '';
  String _amountDueStr = '₱0.00';
  String _requestId = '';
  bool _hasPending = false;
  bool _isLoadingData = true;

  String? _selectedMethod = 'GCash';
  final _gcashNumberController = TextEditingController();
  bool _isProcessing = false;

  List<Map<String, dynamic>> _currentMethods = [
    {'label': 'GCash', 'icon': Icons.account_balance_wallet_outlined, 'desc': 'Pay via GCash App'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingPayment();
  }

  Future<void> _loadPendingPayment() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoadingData = true);

    try {
      // Fetchbilled and approved requests. 
      // Simplified query to avoid index errors that cause infinite loading.
      final snapshot = await _firestore
          .collection('service_requests')
          .where('userId', isEqualTo: user.uid)
          .where('isBilled', isEqualTo: true)
          .get();

      if (mounted) {
        // Filter locally to find the one that is NOT paid and has active status
        final pendingDocs = snapshot.docs.where((doc) {
          final data = doc.data();
          final status = data['status'] ?? '';
          final isPaid = data['isPaid'] ?? false;
          final activeStatuses = ['Confirmed', 'Assigned', 'In Progress'];
          return !isPaid && activeStatuses.contains(status);
        }).toList();

        if (pendingDocs.isNotEmpty) {
          final data = pendingDocs.first.data();
          final docId = pendingDocs.first.id;
          final allowedMethod = data['paymentMethodAllowed'] ?? 'GCash Only';
          
          setState(() {
            _requestId = docId;
            _serviceLabel = data['service'] ?? 'Service Payment';
            _customerName = data['customerName'] ?? 'User';
            _referenceNumber = data['requestId'] ?? 'REF-NEW';
            _amountDueStr = data['amount'] ?? '₱0.00';
            _hasPending = true;
            
            _currentMethods = [
              {'label': 'GCash', 'icon': Icons.account_balance_wallet_outlined, 'desc': 'Pay via GCash App'},
            ];
            if (allowedMethod == 'GCash or Cash') {
              _currentMethods.add({'label': 'Cash', 'icon': Icons.payments_outlined, 'desc': 'Pay after service'});
            }
          });
        } else {
          setState(() => _hasPending = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading payments: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _payNow() async {
    if (!_hasPending) return;
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_selectedMethod == 'GCash' && _gcashNumberController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid GCash mobile number.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isProcessing = true);
    
    // Professional delay for "processing"
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = _auth.currentUser;
      final batch = _firestore.batch();

      // 1. Create payment record
      final paymentRef = _firestore.collection('payments').doc();
      batch.set(paymentRef, {
        'userId': user?.uid,
        'customerName': _customerName,
        'description': _serviceLabel,
        'reference': _referenceNumber,
        'amount': _amountDueStr,
        'method': _selectedMethod,
        'status': 'Completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Mark service request as paid
      final requestRef = _firestore.collection('service_requests').doc(_requestId);
      batch.update(requestRef, {'isPaid': true});

      await batch.commit();

      if (!mounted) return;
      setState(() => _isProcessing = false);

      _showSuccessState();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showSuccessState() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.background.withOpacity(0.95),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 80),
                ),
                const SizedBox(height: 24),
                const Text('Payment Successful!', 
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Transaction ID: $_referenceNumber', 
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadPendingPayment(); 
                    },
                    child: const Text('BACK TO DASHBOARD'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Checkout',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/customer'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(items: customerNav, activeRoute: '/customer/payments'),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
        : SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!_hasPending) _buildEmptyState()
              else ...[
                _buildSectionTitle('BILLING SUMMARY'),
                _buildProfessionalBillCard(),
                const SizedBox(height: 32),
                
                _buildSectionTitle('PAYMENT METHOD'),
                const SizedBox(height: 12),
                ..._currentMethods.map((m) => _buildMethodTile(m)),
                
                if (_selectedMethod == 'GCash') _buildGCashInput(),
                
                const SizedBox(height: 40),
                _buildPayButton(),
              ],
              
              const SizedBox(height: 48),
              _buildSectionTitle('RECENT TRANSACTIONS'),
              const SizedBox(height: 16),
              _buildTransactionHistory(),
            ],
          ),
        ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.receipt_long_outlined, color: Colors.white.withOpacity(0.05), size: 100),
        const SizedBox(height: 24),
        const Text('No Pending Bills', 
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('You don\'t have any unpaid service requests from Admin at the moment.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14, height: 1.5)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, 
        style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5));
  }

  Widget _buildProfessionalBillCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_serviceLabel, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Icon(Icons.info_outline, color: Colors.white24, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text('Invoice: $_referenceNumber', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount Due', style: TextStyle(color: AppColors.lightGray, fontSize: 14)),
              Text(_amountDueStr, style: const TextStyle(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(Map<String, dynamic> method) {
    final bool isSelected = _selectedMethod == method['label'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method['label']),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold.withOpacity(0.05) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.05), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gold.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(method['icon'], color: isSelected ? AppColors.gold : Colors.white24, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method['label'], style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
                    Text(method['desc'], style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                  ],
                ),
              ),
              if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGCashInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GCash Account Number', style: TextStyle(color: AppColors.lightGray, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: _gcashNumberController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '09XX XXX XXXX',
              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Colors.white24),
              filled: true,
              fillColor: const Color(0xFF151921),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.gold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _payNow,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isProcessing 
          ? const CircularProgressIndicator(color: AppColors.background)
          : Text(_selectedMethod == 'GCash' ? 'PAY NOW' : 'CONFIRM ORDER', 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final user = _auth.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('payments')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.gold)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading transactions.', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)));
        }

        final docs = snapshot.data?.docs ?? [];
        
        // Sort client-side by createdAt descending to avoid index errors
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No previous transactions.', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final p = doc.data() as Map<String, dynamic>;
            final timestamp = p['createdAt'] as Timestamp?;
            final dateStr = timestamp != null ? DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate()) : 'Recent';
            final amount = p['amount'] ?? '₱0.00';
            final method = p['method'] ?? 'GCash';
            final desc = p['description'] ?? 'Service Payment';
            final ref = p['reference'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(desc, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                        const SizedBox(height: 2),
                        Text('$method • $dateStr', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11.5)),
                        if (ref.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('Ref: $ref', style: TextStyle(color: AppColors.gold.withOpacity(0.7), fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PAID',
                          style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
