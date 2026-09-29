import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../services/user_service.dart';

class TechnicianRequestsScreen extends StatefulWidget {
  const TechnicianRequestsScreen({super.key});

  @override
  State<TechnicianRequestsScreen> createState() => _TechnicianRequestsScreenState();
}

class _TechnicianRequestsScreenState extends State<TechnicianRequestsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;
  String _techDisplayName = 'Technician';

  @override
  void initState() {
    super.initState();
    _loadTechInfo();
  }

  Future<void> _loadTechInfo() async {
    final userData = await UserService().getCurrentUserData();
    if (mounted && userData != null) {
      setState(() {
        _techDisplayName = userData['displayName'] ?? 'Technician';
      });
    }
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    await _firestore.collection('service_requests').doc(docId).update({'status': newStatus});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: AppColors.surfaceLight),
      );
    }
  }

  void _showRequestDetails(Map<String, dynamic> req) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
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
                      Text(req['requestId'] ?? 'N/A', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14)),
                      StatusBadge(status: req['status'] ?? 'Pending'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(req['service'] ?? 'Unknown Service', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(req['problem'] ?? 'No description provided.', style: const TextStyle(color: AppColors.lightGray, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  _detailItem(Icons.person, 'Customer', req['customerName'] ?? 'Unknown'),
                  _detailItem(Icons.phone, 'Contact Number', req['contact'] ?? 'N/A'),
                  _detailItem(Icons.location_on, 'Address', req['address'] ?? 'N/A'),
                  _detailItem(Icons.access_time, 'Preferred Time', '${req['date']} ${req['time']}'),
                  
                  if (req['hasPhoto'] == true) ...[
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 16),
                    const Text('ATTACHED PHOTO', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
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
                        child: Icon(Icons.image_outlined, color: Colors.white24, size: 40),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  const Text('Notes / Instructions', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                    child: Text(
                      (req['notes'] ?? '').isEmpty ? 'No notes provided.' : req['notes'],
                      style: const TextStyle(color: AppColors.lightGray, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF7A7E9E), fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
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
        title: 'Assigned Requests',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/technician'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: technicianNav,
        activeRoute: '/technician/requests',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assigned Requests', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Manage and update your service tasks.', style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('service_requests')
                    .where('technician', isEqualTo: _techDisplayName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  if (snapshot.hasError) return const Center(child: Text('No active assignments.', style: TextStyle(color: AppColors.lightGray)));
                  
                  final docs = snapshot.data?.docs ?? [];
                  
                  // Filter out Completed and Cancelled jobs for this view
                  final activeDocs = docs.where((doc) {
                    final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
                    return status != 'Completed' && status != 'Cancelled';
                  }).toList();

                  if (activeDocs.isEmpty) return const Center(child: Text('No active assignments.', style: TextStyle(color: AppColors.lightGray)));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: activeDocs.length,
                    itemBuilder: (context, index) {
                      final doc = activeDocs[index];
                      final req = doc.data() as Map<String, dynamic>;
                      return _buildRequestCard(doc.id, req);
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

  Widget _buildRequestCard(String docId, Map<String, dynamic> req) {
    final status = req['status'] ?? 'Pending';
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
              Text(req['requestId'] ?? 'N/A', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12.5)),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Text(req['service'] ?? 'Unknown', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(req['customerName'] ?? 'Unknown', style: const TextStyle(color: AppColors.lightGray, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.lightGray),
              const SizedBox(width: 6),
              Expanded(child: Text(req['address'] ?? 'N/A', style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.lightGray),
              const SizedBox(width: 6),
              Text('${req['date']} ${req['time']}', style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              if (status == 'Pending')
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(docId, 'Confirmed'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                          child: const Text('ACCEPT'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _firestore.collection('service_requests').doc(docId).update({
                            'technician': 'Unassigned',
                            'status': 'Pending',
                          }),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), foregroundColor: AppColors.danger),
                          child: const Text('DECLINE'),
                        ),
                      ),
                    ],
                  ),
                ),
              if (status == 'Confirmed')
                Expanded(child: ElevatedButton(onPressed: () => _updateStatus(docId, 'In Progress'), child: const Text('START SERVICE'))),
              if (status == 'In Progress')
                Expanded(child: ElevatedButton(onPressed: () => _updateStatus(docId, 'Completed'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white), child: const Text('MARK COMPLETE'))),
              if (status == 'Completed')
                const Expanded(child: Center(child: Text('Service Finished', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 10),
              if (status != 'Pending') // Only show Details alone if not pending for layout reasons
                OutlinedButton(onPressed: () => _showRequestDetails(req), child: const Text('DETAILS')),
            ],
          ),
          if (status == 'Pending') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => _showRequestDetails(req), child: const Text('VIEW DETAILS')),
            ),
          ],
        ],
      ),
    );
  }
}
