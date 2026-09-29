import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _technicianFilter = 'All';
  List<String> _technicians = ['All'];

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    final snapshot = await _firestore
        .collection('users')
        .get();
    
    if (mounted) {
      setState(() {
        final techs = snapshot.docs
            .where((doc) {
              final data = doc.data();
              final role = data['role']?.toString().toLowerCase();
              final active = data['active'] ?? true;
              return role == 'technician' && active == true;
            })
            .map((doc) => doc.data()['displayName'] as String? ?? 'Unknown Tech')
            .toList();
        _technicians = ['All', ...techs];
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'Confirmed':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.danger;
      case 'In Progress':
      case 'Assigned':
        return AppColors.warning;
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

  DateTime _parseDate(String dateStr) {
    try {
      // Assuming date format is "MM/DD/YYYY"
      final parts = dateStr.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Schedule',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin/schedule',
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
                  const Text('Master Schedule',
                      style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Monitor all technician assignments and activities.',
                      style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
                  const SizedBox(height: 20),
                  
                  // Technician Filter
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _technicians.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final t = _technicians[index];
                        final isSelected = _technicianFilter == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _technicianFilter = t),
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.gold,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.background : AppColors.lightGray,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? AppColors.gold : AppColors.border),
                          ),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Live Data Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('service_requests').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  
                  // Filter by Technician and Day
                  final filteredDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final tech = data['technician'] ?? 'Unassigned';
                    final date = _parseDate(data['date'] ?? '');
                    
                    final matchesTech = _technicianFilter == 'All' || tech == _technicianFilter;
                    final matchesDay = _selectedDay == null || isSameDay(date, _selectedDay);
                    
                    return matchesTech && matchesDay;
                  }).toList();

                  // Sort by time (roughly)
                  filteredDocs.sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['time'] ?? '';
                    final bTime = (b.data() as Map<String, dynamic>)['time'] ?? '';
                    return aTime.compareTo(bTime);
                  });

                  return Column(
                    children: [
                      // Calendar Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TableCalendar(
                            firstDay: DateTime.now().subtract(const Duration(days: 30)),
                            lastDay: DateTime.now().add(const Duration(days: 120)),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = isSameDay(_selectedDay, selectedDay) ? null : selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                            calendarFormat: CalendarFormat.week,
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.gold, size: 20),
                              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.gold, size: 20),
                            ),
                            calendarStyle: const CalendarStyle(
                              defaultTextStyle: TextStyle(color: Colors.white),
                              weekendTextStyle: TextStyle(color: Colors.white),
                              selectedDecoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                              selectedTextStyle: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold),
                              todayDecoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                              todayTextStyle: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Title for the list
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDay == null ? 'All Upcoming Tasks' : DateFormat('MMMM d, yyyy').format(_selectedDay!),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text('${filteredDocs.length} Jobs', style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Job List
                      Expanded(
                        child: filteredDocs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_busy, color: Colors.white.withOpacity(0.05), size: 60),
                                    const SizedBox(height: 12),
                                    Text('No jobs scheduled for this selection.', 
                                        style: TextStyle(color: Colors.white.withOpacity(0.2))),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: filteredDocs.length,
                                itemBuilder: (context, index) {
                                  final data = filteredDocs[index].data() as Map<String, dynamic>;
                                  final status = data['status'] ?? 'Pending';
                                  
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
                                        Container(
                                          width: 4, height: 40,
                                          decoration: BoxDecoration(color: _statusColor(status), borderRadius: BorderRadius.circular(2)),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(data['service'] ?? 'Service', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                                              const SizedBox(height: 4),
                                              Text('${data['customerName']} • ${data['technician']}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.access_time, size: 12, color: AppColors.gold),
                                                  const SizedBox(width: 6),
                                                  Text(data['time'] ?? '', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                                  if (_selectedDay == null) ...[
                                                    const SizedBox(width: 12),
                                                    const Icon(Icons.calendar_today, size: 12, color: AppColors.gold),
                                                    const SizedBox(width: 6),
                                                    Text(data['date'] ?? '', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        _badge(status),
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
          ],
        ),
      ),
    );
  }
}
