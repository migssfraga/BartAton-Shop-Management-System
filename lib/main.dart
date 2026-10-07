import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/service_request_screen.dart';
import 'screens/service_bookings_screen.dart';
import 'screens/appointment_scheduling_screen.dart';
import 'screens/washing_machine_rental_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/service_history_screen.dart';
import 'screens/customer_chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_appointments_screen.dart';
import 'screens/admin_rentals_screen.dart';
import 'screens/admin_customers_screen.dart';
import 'screens/admin_inventory_screen.dart';
import 'screens/admin_technicians_screen.dart';
import 'screens/admin_finance_screen.dart';
import 'screens/admin_schedule_screen.dart';
import 'screens/admin_service_history_screen.dart';
import 'screens/admin_payroll_screen.dart';
import 'screens/admin_payment_records_screen.dart';
import 'screens/admin_chat_screen.dart';
import 'screens/admin_reports_screen.dart';
import 'screens/admin_settings_screen.dart';
import 'screens/technician_requests_screen.dart';
import 'screens/technician_schedule_screen.dart';
import 'screens/technician_history_screen.dart';
import 'screens/technician_payroll_screen.dart';
import 'screens/technician_profile_screen.dart';
import 'screens/customer_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/technician_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(const BartAtonApp());
}

class BartAtonApp extends StatelessWidget {
  const BartAtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BartAton Shop System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/customer/services': (context) => const ServiceBookingsScreen(),
        '/customer/book-service': (context) => const ServiceRequestScreen(),
        '/customer/appointments': (context) => const AppointmentSchedulingScreen(),
        '/customer/rentals': (context) => const WashingMachineRentalScreen(),
        '/customer/payments': (context) => const PaymentScreen(),
        '/customer/history': (context) => const ServiceHistoryScreen(),
        '/customer/chat': (context) => const CustomerChatScreen(),
        '/customer/profile': (context) => const ProfileScreen(),
        '/customer': (context) => const CustomerDashboardScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/technician': (context) => const TechnicianDashboardScreen(),
        '/technician/requests': (context) => const TechnicianRequestsScreen(),
        '/technician/schedule': (context) => const TechnicianScheduleScreen(),
        '/technician/history': (context) => const TechnicianServiceHistoryScreen(),
        '/technician/payroll': (context) => const TechnicianPayrollScreen(),
        '/technician/profile': (context) => const TechnicianProfileScreen(),
        '/admin/appointments': (context) => const AdminAppointmentsScreen(),
        '/admin/rentals': (context) => const AdminRentalsScreen(),
        '/admin/customers': (context) => const AdminCustomersScreen(),
        '/admin/inventory': (context) => const AdminInventoryScreen(),
        '/admin/technicians': (context) => const AdminTechniciansScreen(),
        '/admin/finance': (context) => const AdminFinanceScreen(),
        '/admin/schedule': (context) => const AdminScheduleScreen(),
        '/admin/history': (context) => const AdminServiceHistoryScreen(),
        '/admin/payroll': (context) => const AdminPayrollScreen(),
        '/admin/payments': (context) => const AdminPaymentRecordsScreen(),
        '/admin/chat': (context) => const AdminChatScreen(),
        '/admin/reports': (context) => const AdminReportsScreen(),
        '/admin/settings': (context) => const AdminSettingsScreen(),
        // TODO: add the rest of the routes as you build each screen:
        // '/admin/schedule', '/admin/history', '/admin/finance',
        // '/admin/inventory', '/admin/technicians', '/admin/payroll',
        // '/admin/payments', '/admin/chat', '/admin/reports', '/admin/settings',
        // '/technician/requests', '/technician/schedule', '/technician/history',
        // '/technician/payroll', '/technician/profile'
      },
    );
  }
}
