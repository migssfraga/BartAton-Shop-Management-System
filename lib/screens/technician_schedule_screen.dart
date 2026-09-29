import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../services/user_service.dart';

class TechnicianScheduleScreen extends StatefulWidget {
  const TechnicianScheduleScreen({super.key});

  @override
  State<TechnicianScheduleScreen> createState() => _TechnicianScheduleScreenState();
}

class _TechnicianScheduleScreenState extends State<TechnicianScheduleScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _techDisplayName = 'Technician';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTechInfo();
    _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  }

  Future<void> _loadTechInfo() async {
    final userData = await UserService().getCurrentUserData(forceRefresh: true);
    if (mounted && userData != null) {
      setState(() {
        _techDisplayName = userData['displayName'] ?? userData['firstName'] ?? 'Technician';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'In Progress':
        return AppColors.warning;
      case 'Assigned':
      case 'Confirmed':
        return AppColors.gold;
      default:
        return AppColors.lightGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'My Schedule',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/technician'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: technicianNav,
        activeRoute: '/technician/schedule',
        userName: _techDisplayName,
        userRole: 'Technician',
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('service_requests')
                    .where('technician', isEqualTo: _techDisplayName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }

                  final allDocs = snapshot.data?.docs ?? [];

                  // Filter jobs for selected day
                  final selectedJobs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = _parseDate(data['date'] ?? '');
                    return _selectedDay == null || isSameDay(date, _selectedDay);
                  }).toList();

                  selectedJobs.sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['time'] ?? '';
                    final bTime = (b.data() as Map<String, dynamic>)['time'] ?? '';
                    return aTime.compareTo(bTime);
                  });

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('My Schedule',
                                style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text('Track your upcoming tasks and availability in real-time.',
                                style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TableCalendar(
                            firstDay: DateTime.now().subtract(const Duration(days: 30)),
                            lastDay: DateTime.now().add(const Duration(days: 120)),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                            calendarFormat: CalendarFormat.month,
                            eventLoader: (day) {
                              return allDocs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final date = _parseDate(data['date'] ?? '');
                                return isSameDay(date, day);
                              }).toList();
                            },
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.gold),
                              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.gold),
                            ),
                            daysOfWeekStyle: const DaysOfWeekStyle(
                              weekdayStyle: TextStyle(color: AppColors.lightGray, fontSize: 12),
                              weekendStyle: TextStyle(color: AppColors.lightGray, fontSize: 12),
                            ),
                            calendarStyle: CalendarStyle(
                              outsideDaysVisible: false,
                              defaultTextStyle: const TextStyle(color: AppColors.white),
                              weekendTextStyle: const TextStyle(color: AppColors.white),
                              todayDecoration: BoxDecoration(
                                border: Border.all(color: AppColors.gold, width: 1.5),
                                shape: BoxShape.circle,
                              ),
                              todayTextStyle: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                              selectedDecoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                              selectedTextStyle: const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold),
                              markerDecoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                              markersMaxCount: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDay == null ? 'Scheduled Jobs' : 'Jobs for ${_selectedDay!.month}/${_selectedDay!.day}/${_selectedDay!.year}',
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text('${selectedJobs.length} Job(s)', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: selectedJobs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_available, color: Colors.white.withOpacity(0.1), size: 60),
                                    const SizedBox(height: 12),
                                    const Text('No jobs scheduled for this day.', style: TextStyle(color: AppColors.lightGray)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: selectedJobs.length,
                                itemBuilder: (context, index) {
                                  final data = selectedJobs[index].data() as Map<String, dynamic>;
                                  final service = data['service'] ?? 'Repair Service';
                                  final customer = data['customerName'] ?? 'Valued Customer';
                                  final time = data['time'] ?? 'Anytime';
                                  final address = data['address'] ?? 'No address';
                                  final status = data['status'] ?? 'Assigned';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: _statusColor(status),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(service,
                                                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                                  StatusBadge(status: status),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(customer, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time, size: 12, color: AppColors.lightGray),
                                                  const SizedBox(width: 4),
                                                  Text(time, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                                  const SizedBox(width: 12),
                                                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.lightGray),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(address,
                                                        style: const TextStyle(color: AppColors.lightGray, fontSize: 12),
                                                        overflow: TextOverflow.ellipsis),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
