import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';

/// Top bar used on every dashboard: hamburger + title + notification + avatar
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBackTap;
  final bool showBackButton;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool hasNotification;

  const AppHeader({
    super.key,
    required this.title,
    this.onMenuTap,
    this.onBackTap,
    this.showBackButton = false,
    this.onNotificationTap,
    this.onProfileTap,
    this.hasNotification = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  Future<void> _handleProfileTap(BuildContext context) async {
    if (onProfileTap != null) {
      onProfileTap!();
      return;
    }

    final userData = await UserService().getCurrentUserData();
    if (userData != null) {
      final role = userData['role'] ?? 'customer';
      if (context.mounted) {
        if (role == 'admin') {
          Navigator.of(context).pushNamed('/admin/settings');
        } else if (role == 'technician') {
          Navigator.of(context).pushNamed('/technician/profile');
        } else {
          Navigator.of(context).pushNamed('/customer/profile');
        }
      }
    }
  }

  Future<void> _showNotificationCenter(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final userData = await UserService().getCurrentUserData();
    final role = userData?['role'] ?? 'customer';
    final userId = user?.uid;
    final techName = userData?['displayName'] ?? userData?['firstName'] ?? '';

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                  const Text('Notifications',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.lightGray, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                role == 'admin' 
                    ? 'Live system-wide updates.' 
                    : role == 'technician' 
                        ? 'Updates on your assigned repair jobs.' 
                        : 'Updates on your bookings, payments, and rentals.',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: role == 'admin' 
                      ? FirebaseFirestore.instance.collection('service_requests').snapshots()
                      : role == 'technician'
                          ? FirebaseFirestore.instance.collection('service_requests').where('technician', isEqualTo: techName).snapshots()
                          : FirebaseFirestore.instance.collection('service_requests').where('userId', isEqualTo: userId).snapshots(),
                  builder: (context, reqSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: role == 'admin'
                          ? FirebaseFirestore.instance.collection('payments').snapshots()
                          : role == 'technician'
                              ? FirebaseFirestore.instance.collection('payments').where('userId', isEqualTo: 'NONE').snapshots()
                              : FirebaseFirestore.instance.collection('payments').where('userId', isEqualTo: userId).snapshots(),
                      builder: (context, paySnapshot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: role == 'admin'
                              ? FirebaseFirestore.instance.collection('rentals').snapshots()
                              : role == 'technician'
                                  ? FirebaseFirestore.instance.collection('rentals').where('userId', isEqualTo: 'NONE').snapshots()
                                  : FirebaseFirestore.instance.collection('rentals').where('userId', isEqualTo: userId).snapshots(),
                          builder: (context, rentalSnapshot) {
                            if (reqSnapshot.connectionState == ConnectionState.waiting &&
                                paySnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                            }

                            final requests = reqSnapshot.data?.docs ?? [];
                            final payments = paySnapshot.data?.docs ?? [];
                            final rentals = rentalSnapshot.data?.docs ?? [];

                            List<Map<String, dynamic>> allNotifs = [];

                            for (var doc in requests) {
                              final data = doc.data() as Map<String, dynamic>;
                              final status = data['status'] ?? 'Pending';
                              String title = 'Service Request: ${data['service'] ?? 'Repair'}';
                              String subtitle = 'Status: $status';

                              if (role == 'admin') {
                                subtitle = 'Customer: ${data['customerName'] ?? 'Client'} • Status: $status';
                              } else if (role == 'technician') {
                                title = 'New Assigned Job';
                                subtitle = 'Customer: ${data['customerName']} • Date: ${data['date']} (${data['time']})';
                              } else {
                                if (status == 'Confirmed' || status == 'Assigned' || status == 'In Progress') {
                                  title = 'Request Approved';
                                  subtitle = 'Your request for ${data['service']} has been $status.';
                                } else if (status == 'Completed') {
                                  title = 'Service Completed';
                                  subtitle = 'Your service request has been successfully completed.';
                                }
                              }

                              allNotifs.add({
                                'title': title,
                                'subtitle': subtitle,
                                'time': data['createdAt'] as Timestamp?,
                                'icon': Icons.assignment_outlined,
                                'color': AppColors.gold,
                              });
                            }

                            if (role == 'admin') {
                              for (var doc in payments) {
                                final data = doc.data() as Map<String, dynamic>;
                                allNotifs.add({
                                  'title': 'Payment Received: ${data['amount'] ?? '₱0'}',
                                  'subtitle': 'Via ${data['method'] ?? 'GCash'} • Ref: ${data['reference'] ?? 'N/A'}',
                                  'time': data['createdAt'] as Timestamp?,
                                  'icon': Icons.payments_outlined,
                                  'color': AppColors.success,
                                });
                              }

                              for (var doc in rentals) {
                                final data = doc.data() as Map<String, dynamic>;
                                final status = data['status'] ?? 'Active';
                                allNotifs.add({
                                  'title': 'Washing Machine Rental',
                                  'subtitle': 'Machine: ${data['machineName'] ?? 'Unit'} • Status: $status',
                                  'time': data['createdAt'] as Timestamp?,
                                  'icon': Icons.local_shipping_outlined,
                                  'color': AppColors.warning,
                                });
                              }
                            } else if (role == 'customer') {
                              for (var doc in payments) {
                                final data = doc.data() as Map<String, dynamic>;
                                allNotifs.add({
                                  'title': 'Payment Successful',
                                  'subtitle': 'Via ${data['method'] ?? 'GCash'} • Ref: ${data['reference'] ?? 'N/A'}',
                                  'time': data['createdAt'] as Timestamp?,
                                  'icon': Icons.payments_outlined,
                                  'color': AppColors.success,
                                });
                              }

                              for (var doc in rentals) {
                                final data = doc.data() as Map<String, dynamic>;
                                final status = data['status'] ?? 'Active';
                                allNotifs.add({
                                  'title': 'Rental Update',
                                  'subtitle': 'Machine: ${data['machineName'] ?? 'Unit'} • Status: $status',
                                  'time': data['createdAt'] as Timestamp?,
                                  'icon': Icons.local_shipping_outlined,
                                  'color': AppColors.warning,
                                });
                              }
                            }

                            // Sort by time descending
                            allNotifs.sort((a, b) {
                              final tA = a['time'] as Timestamp?;
                              final tB = b['time'] as Timestamp?;
                              if (tA == null || tB == null) return 0;
                              return tB.compareTo(tA);
                            });

                            if (allNotifs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.notifications_off_outlined, color: Colors.white.withOpacity(0.1), size: 60),
                                    const SizedBox(height: 12),
                                    Text('No notifications yet.', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              controller: scrollController,
                              itemCount: allNotifs.length,
                              itemBuilder: (context, index) {
                                final n = allNotifs[index];
                                final time = n['time'] as Timestamp?;
                                final timeStr = time != null ? _formatTimeAgo(time.toDate()) : 'Recently';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: (n['color'] as Color).withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(n['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                                            const SizedBox(height: 2),
                                            Text(n['subtitle']!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11.5)),
                                            const SizedBox(height: 4),
                                            Text(timeStr, style: TextStyle(color: AppColors.gold.withOpacity(0.7), fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.85),
            border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Row(
            children: [
              if (showBackButton)
                _headerButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: onBackTap ?? () => Navigator.of(context).pop(),
                )
              else if (onMenuTap != null)
                _headerButton(
                  icon: Icons.menu_rounded,
                  onTap: onMenuTap!,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Stack(
                children: [
                  _headerButton(
                    icon: Icons.notifications_outlined,
                    onTap: onNotificationTap ?? () => _showNotificationCenter(context),
                  ),
                  if (hasNotification)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _handleProfileTap(context),
                child: Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
                    ),
                    child: const CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.gold,
                      child: Icon(Icons.person_rounded, color: AppColors.background, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.white, size: 22),
        ),
      ),
    );
  }
}

/// Colored status badge used across tables (Pending, Completed, Failed, etc.)
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color _bg() {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'confirmed':
      case 'active':
        return AppColors.success.withOpacity(0.15);
      case 'failed':
      case 'cancelled':
      case 'rejected':
        return AppColors.danger.withOpacity(0.15);
      case 'in progress':
      case 'assigned':
        return AppColors.warning.withOpacity(0.15);
      default:
        return AppColors.gold.withOpacity(0.15);
    }
  }

  Color _fg() {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'confirmed':
      case 'active':
        return AppColors.success;
      case 'failed':
      case 'cancelled':
      case 'rejected':
        return AppColors.danger;
      case 'in progress':
      case 'assigned':
        return AppColors.warning;
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: _bg(), borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(color: _fg(), fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}
