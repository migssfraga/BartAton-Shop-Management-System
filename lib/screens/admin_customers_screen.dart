import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  String _statusFilter = 'All';
  String _query = '';

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  void _viewCustomer(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.gold,
                  child: Icon(Icons.person, color: AppColors.background, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['displayName'] ?? 'Unknown', 
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(data['email'] ?? '', style: const TextStyle(color: AppColors.lightGray, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),
            _detailRow(Icons.phone_outlined, 'Mobile Number', data['mobile'] ?? 'N/A'),
            _detailRow(Icons.location_on_outlined, 'Address', data['address'] ?? 'No address set'),
            _detailRow(Icons.calendar_today_outlined, 'Member Since', _formatDate(data['createdAt'] as Timestamp?)),
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF7A7E9E), fontSize: 11.5)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.white, fontSize: 14)),
              ],
            ),
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
        title: 'Customer Directory',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin/customers',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registered Customers',
                      style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Search and manage your customer database.',
                      style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.white, fontSize: 14),
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white24),
                      filled: true,
                      fillColor: AppColors.surface,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'customer')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  
                  // Client-side search filtering
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['displayName'] ?? '').toString().toLowerCase();
                    final email = (data['email'] ?? '').toString().toLowerCase();
                    final q = _query.toLowerCase();
                    return name.contains(q) || email.contains(q);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, color: Colors.white.withOpacity(0.05), size: 80),
                          const SizedBox(height: 16),
                          Text(_query.isEmpty ? 'No customers yet.' : 'No matches found.', 
                              style: TextStyle(color: Colors.white.withOpacity(0.2))),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.gold,
                              child: Icon(Icons.person, color: AppColors.background, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['displayName'] ?? 'Unknown',
                                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(data['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _viewCustomer(data),
                              icon: const Icon(Icons.chevron_right, color: AppColors.gold),
                            ),
                          ],
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
