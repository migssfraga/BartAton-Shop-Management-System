import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AppointmentSchedulingScreen extends StatefulWidget {
  const AppointmentSchedulingScreen({super.key});

  @override
  State<AppointmentSchedulingScreen> createState() => _AppointmentSchedulingScreenState();
}

class _AppointmentSchedulingScreenState extends State<AppointmentSchedulingScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Sample available time slots — replace with real availability from your
  // backend (e.g. slots already booked should be excluded per technician/day).
  static const List<String> _timeSlots = [
    '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM',
    '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM',
  ];

  static const List<String> _serviceTypes = [
    'Washing Machine Repair',
    'Refrigerator Repair',
    'Dryer Repair',
    'Aircon Installation',
    'General Maintenance',
  ];

  // Sample technicians — replace with real staff list from your backend.
  static const List<String> _technicians = [
    'Any Available Technician',
    'Carlos Reyes',
    'Ben Torres',
    'Angela Cruz',
  ];

  String? _selectedTime;
  String? _selectedService;
  String _selectedTechnician = _technicians.first;
  bool _isConfirming = false;

  bool get _isReady => _selectedDay != null && _selectedTime != null && _selectedService != null;

  Future<void> _confirmAppointment() async {
    if (!_isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date, time and service type.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isConfirming = true);

    // TODO: Replace with a real API/Firestore write — create an appointment
    // document with status: 'Pending' (or 'Confirmed' if auto-approved),
    // the selected date/time/service/technician, and the customer's id.
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isConfirming = false);

    final dateLabel = '${_selectedDay!.month}/${_selectedDay!.day}/${_selectedDay!.year}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 10),
            Text('Appointment Confirmed', style: TextStyle(color: AppColors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          '$_selectedService\n$dateLabel at $_selectedTime\nTechnician: $_selectedTechnician',
          style: const TextStyle(color: AppColors.lightGray, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
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
        title: 'Appointment Scheduling',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/customer'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: customerNav,
        activeRoute: '/customer/appointments',
        userName: 'Maria Santos',
        userRole: 'Customer',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Appointment Scheduling',
                style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Pick a date and time that works for you.',
                style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
            const SizedBox(height: 20),

            // ---- Calendar card ----
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 1)),
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
                availableGestures: AvailableGestures.horizontalSwipe,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.gold),
                  rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.gold),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: AppColors.lightGray, fontSize: 11.5),
                  weekendStyle: TextStyle(color: AppColors.lightGray, fontSize: 11.5),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: const TextStyle(color: AppColors.white),
                  weekendTextStyle: const TextStyle(color: AppColors.white),
                  disabledTextStyle: const TextStyle(color: Color(0xFF4A4E70)),
                  todayDecoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold, width: 1.4),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                  selectedDecoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  selectedTextStyle: const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---- Available time slots ----
            _sectionCard(
              title: 'Available Time',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _timeSlots.map((time) {
                  final isSelected = _selectedTime == time;
                  return ChoiceChip(
                    label: Text(time),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedTime = time),
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.gold,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.background : AppColors.lightGray,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? AppColors.gold : AppColors.border),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ---- Service type ----
            _sectionCard(
              title: 'Service Type',
              child: Column(
                children: _serviceTypes.map((s) {
                  final isSelected = _selectedService == s;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedService = s),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.gold.withOpacity(0.1) : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? AppColors.gold : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? AppColors.gold : AppColors.lightGray,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(s,
                                style: TextStyle(
                                  color: isSelected ? AppColors.white : AppColors.lightGray,
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ---- Technician ----
            _sectionCard(
              title: 'Technician',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedTechnician,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.white, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.lightGray),
                items: _technicians.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedTechnician = v ?? _technicians.first),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isConfirming ? null : _confirmAppointment,
              child: _isConfirming
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.background),
                    )
                  : const Text('CONFIRM APPOINTMENT'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
