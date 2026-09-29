import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AdminTechniciansScreen extends StatefulWidget {
  const AdminTechniciansScreen({super.key});

  @override
  State<AdminTechniciansScreen> createState() => _AdminTechniciansScreenState();
}

class _AdminTechniciansScreenState extends State<AdminTechniciansScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;

  void _openAddTechnicianForm() {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final specializationController = TextEditingController(text: 'General Appliance Repair');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Technician', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Provide complete login and profile details for the technician.', style: TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: AppColors.gold, fontSize: 13),
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.gold, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    labelStyle: const TextStyle(color: AppColors.gold, fontSize: 13),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.gold, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Gmail Address (@gmail.com)',
                    labelStyle: const TextStyle(color: AppColors.gold, fontSize: 13),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.gold, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Temporary Password (min 6 chars)',
                    labelStyle: const TextStyle(color: AppColors.gold, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.gold, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specializationController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Specialization / Notes',
                    labelStyle: const TextStyle(color: AppColors.gold, fontSize: 13),
                    prefixIcon: const Icon(Icons.engineering_outlined, color: AppColors.gold, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
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
              onPressed: isLoading ? null : () async {
                final name = nameController.text.trim();
                final contact = contactController.text.trim();
                final email = emailController.text.trim().toLowerCase();
                final password = passwordController.text;

                if (name.isEmpty || contact.isEmpty || email.isEmpty || password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields. Password must be at least 6 characters.'), backgroundColor: AppColors.danger),
                  );
                  return;
                }

                if (!email.endsWith('@gmail.com')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Technician email must be a valid @gmail.com address.'), backgroundColor: AppColors.danger),
                  );
                  return;
                }

                setDialogState(() => isLoading = true);

                try {
                  // Create Firebase Auth account using secondary app so Admin remains logged in
                  FirebaseApp secondaryApp = await Firebase.initializeApp(
                    name: 'TechApp_${DateTime.now().millisecondsSinceEpoch}',
                    options: Firebase.app().options,
                  );
                  FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
                  UserCredential cred = await secondaryAuth.createUserWithEmailAndPassword(email: email, password: password);
                  final uid = cred.user?.uid;
                  await secondaryApp.delete();

                  if (uid != null) {
                    await _firestore.collection('users').doc(uid).set({
                      'uid': uid,
                      'displayName': name,
                      'email': email,
                      'mobile': contact,
                      'specialization': specializationController.text.trim(),
                      'role': 'technician',
                      'active': true,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    await _firestore.collection('payroll').doc(name).set({
                      'employee': name,
                      'role': 'Technician',
                      'basicSalary': 0.0,
                      'allowances': 0.0,
                      'overtime': 0.0,
                      'deductions': 0.0,
                      'status': 'Draft',
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$name successfully added as Technician!'), backgroundColor: AppColors.success),
                      );
                    }
                  }
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add technician: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2))
                : const Text('Add Technician', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _editTechnician(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['displayName'] ?? '');
    final contactController = TextEditingController(text: data['mobile'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Edit Technician', style: TextStyle(color: AppColors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'Full name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contactController,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(hintText: 'Contact number'),
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
              await _firestore.collection('users').doc(doc.id).update({
                'displayName': nameController.text.trim(),
                'mobile': contactController.text.trim(),
              });
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleActive(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final currentActive = data['active'] ?? true;
    await _firestore.collection('users').doc(doc.id).update({'active': !currentActive});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['displayName']} ${!currentActive ? 'activated' : 'deactivated'}.'),
          backgroundColor: AppColors.surfaceLight,
        ),
      );
    }
  }

  void _viewPerformance(String techName, String contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('service_requests').where('technician', isEqualTo: techName).snapshots(),
        builder: (context, snapshot) {
          final requests = snapshot.data?.docs ?? [];
          final assigned = requests.where((d) => (d.data() as Map)['status'] == 'Assigned').length;
          final pending = requests.where((d) => (d.data() as Map)['status'] == 'Pending').length;
          final completed = requests.where((d) => (d.data() as Map)['status'] == 'Completed').length;
          final total = requests.length;
          final rate = total > 0 ? (completed / total) : 0.0;

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
                Text(techName, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Text(contact, style: const TextStyle(color: AppColors.lightGray, fontSize: 12.5)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _perfStat('Assigned', assigned, AppColors.gold)),
                    Expanded(child: _perfStat('Pending', pending, AppColors.warning)),
                    Expanded(child: _perfStat('Completed', completed, AppColors.success)),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: rate.clamp(0.0, 1.0),
                  backgroundColor: AppColors.border,
                  color: AppColors.gold,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                const Text('Completion rate across assigned jobs',
                    style: TextStyle(color: AppColors.lightGray, fontSize: 11.5)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _perfStat(String label, int value, Color color) {
    return Column(
      children: [
        Text('$value', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 11.5)),
      ],
    );
  }

  Widget _statusBadge(bool active) {
    final color = active ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(active ? 'Active' : 'Inactive',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Technician / Staff',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin/technicians',
        userName: 'Admin',
        userRole: 'Administrator',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        onPressed: _openAddTechnicianForm,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Technician', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .where('role', isEqualTo: 'technician')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('No technicians found. Add a technician to get started.',
                      style: TextStyle(color: AppColors.lightGray), textAlign: TextAlign.center),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                const Text('Technician / Staff',
                    style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Manage your service team and track their workload in real-time.',
                    style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                const SizedBox(height: 20),
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['displayName'] ?? 'Technician';
                  final contact = data['mobile'] ?? data['email'] ?? 'No contact';
                  final active = data['active'] ?? true;

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('service_requests').where('technician', isEqualTo: name).snapshots(),
                    builder: (context, reqSnapshot) {
                      final requests = reqSnapshot.data?.docs ?? [];
                      final assigned = requests.where((d) => (d.data() as Map)['status'] == 'Assigned').length;
                      final pending = requests.where((d) => (d.data() as Map)['status'] == 'Pending').length;
                      final completed = requests.where((d) => (d.data() as Map)['status'] == 'Completed').length;

                      return Padding(
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
                                children: [
                                  const CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.gold,
                                    child: Icon(Icons.engineering, color: AppColors.background, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                                        Text(contact, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  _statusBadge(active),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _jobPill('Assigned', assigned, AppColors.gold),
                                  const SizedBox(width: 8),
                                  _jobPill('Pending', pending, AppColors.warning),
                                  const SizedBox(width: 8),
                                  _jobPill('Completed', completed, AppColors.success),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _viewPerformance(name, contact),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.lightGray,
                                        side: const BorderSide(color: AppColors.border),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Performance', style: TextStyle(fontSize: 11.5)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _editTechnician(doc),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.lightGray,
                                        side: const BorderSide(color: AppColors.border),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Edit', style: TextStyle(color: AppColors.white, fontSize: 11.5)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _toggleActive(doc),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: active ? AppColors.danger : AppColors.success,
                                        side: BorderSide(color: active ? AppColors.danger : AppColors.success),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                      child: Text(active ? 'Deactivate' : 'Activate', style: const TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _jobPill(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
