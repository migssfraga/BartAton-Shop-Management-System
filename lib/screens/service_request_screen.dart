import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../services/user_service.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  static const List<String> _serviceTypes = [
    'Washing Machine Repair',
    'Refrigerator Repair',
    'Dryer Repair',
    'Aircon Installation',
    'General Maintenance',
  ];

  static const List<String> _applianceTypes = [
    'Washing Machine',
    'Refrigerator',
    'Dryer',
    'Air Conditioner',
    'Other',
  ];

  String? _serviceType;
  String? _applianceType;
  
  // Specialized Aircon Fields
  String? _airconType; // Window, Split, Cabinet
  String? _horsePower; // 0.5, 1.0, 1.5, 2.0
  String? _installTask; // New Install, Relocation, Cleaning
  
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  bool _photoAttached = false;
  bool _isSubmitting = false;

  final _problemController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userData = await UserService().getCurrentUserData();
    if (mounted && userData != null) {
      setState(() {
        _addressController.text = userData['address'] ?? '';
        _contactController.text = userData['mobile'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _problemController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.background,
            surface: AppColors.surface,
            onSurface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferredTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.background,
            surface: AppColors.surface,
            onSurface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _preferredTime = picked);
  }

  void _pickPhoto() {
    setState(() => _photoAttached = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo attached (demo only).'),
        backgroundColor: AppColors.surfaceLight,
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_serviceType == null || _applianceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Service and Appliance Type.'), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_preferredDate == null || _preferredTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a preferred date and time.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      final userData = await UserService().getCurrentUserData();
      final now = DateTime.now();
      final requestId = 'SR-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';

      await _firestore.collection('service_requests').add({
        'requestId': requestId,
        'userId': user?.uid,
        'customerName': userData?['displayName'] ?? 'Customer',
        'service': _serviceType,
        'appliance': _applianceType,
        // Specialized data
        'airconType': _airconType,
        'horsePower': _horsePower,
        'installTask': _installTask,
        
        'problem': _problemController.text.trim(),
        'date': '${_preferredDate!.month}/${_preferredDate!.day}/${_preferredDate!.year}',
        'time': _preferredTime!.format(context),
        'address': _addressController.text.trim(),
        'contact': _contactController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': 'Pending',
        'hasPhoto': _photoAttached, // Added flag for photo
        'technician': 'Unassigned',
        'amount': '₱0.00',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 10),
              Text('Request Submitted', style: TextStyle(color: AppColors.white, fontSize: 16)),
            ],
          ),
          content: const Text(
            'Your service request has been sent to Admin. Wait for confirmation.',
            style: TextStyle(color: AppColors.lightGray, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // back to list
              },
              child: const Text('OK', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting request: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Book a Service',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pop(),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: customerNav,
        activeRoute: '/customer/services',
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Request a Service', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Fill in the details for your repair or installation.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
              const SizedBox(height: 30),

              _sectionTitle('SERVICE TYPE'),
              _dropdown(
                value: _serviceType,
                hint: 'Select service type',
                items: _serviceTypes,
                onChanged: (v) {
                  setState(() {
                    _serviceType = v;
                    if (v == 'Aircon Installation') {
                      _applianceType = 'Air Conditioner';
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              if (_serviceType == 'Aircon Installation') ...[
                _sectionTitle('AIRCON DETAILS'),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        value: _airconType,
                        hint: 'Type',
                        items: ['Window Type', 'Split Type', 'Cabinet Type'],
                        onChanged: (v) => setState(() => _airconType = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdown(
                        value: _horsePower,
                        hint: 'Horse Power',
                        items: ['0.5 HP', '1.0 HP', '1.5 HP', '2.0 HP', '2.5 HP+'],
                        onChanged: (v) => setState(() => _horsePower = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _dropdown(
                  value: _installTask,
                  hint: 'Task Needed',
                  items: ['New Installation', 'Relocation', 'System Repiping'],
                  onChanged: (v) => setState(() => _installTask = v),
                ),
                const SizedBox(height: 20),
              ],

              if (_serviceType != 'Aircon Installation') ...[
                _sectionTitle('APPLIANCE TYPE'),
                _dropdown(
                  value: _applianceType,
                  hint: 'Select appliance type',
                  items: _applianceTypes,
                  onChanged: (v) => setState(() => _applianceType = v),
                ),
                const SizedBox(height: 20),
              ],

              _sectionTitle('PROBLEM / DESCRIPTION'),
              _buildModernTextField(
                controller: _problemController,
                hint: 'e.g. Aircon needs cleaning, Washing machine not draining...',
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('DATE'),
                        _pickerField(
                          icon: Icons.calendar_today,
                          text: _preferredDate == null
                              ? 'Select date'
                              : '${_preferredDate!.month}/${_preferredDate!.day}/${_preferredDate!.year}',
                          onTap: _pickDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('TIME'),
                        _pickerField(
                          icon: Icons.access_time,
                          text: _preferredTime == null ? 'Select time' : _preferredTime!.format(context),
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _sectionTitle('SERVICE ADDRESS'),
              _buildModernTextField(
                controller: _addressController,
                hint: 'House No., Street, Barangay, City',
              ),
              const SizedBox(height: 20),

              _sectionTitle('CONTACT NUMBER'),
              _buildModernTextField(
                controller: _contactController,
                hint: '09XX XXX XXXX',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              _sectionTitle('ATTACH PHOTO'),
              InkWell(
                onTap: _pickPhoto,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151921),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _photoAttached ? AppColors.gold : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _photoAttached ? Icons.check_circle : Icons.add_a_photo_outlined,
                        color: _photoAttached ? AppColors.gold : Colors.white24,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _photoAttached ? 'Photo Attached' : 'Upload actual photo of the appliance',
                        style: TextStyle(
                          color: _photoAttached ? Colors.white : Colors.white24,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                    : const Text('SUBMIT REQUEST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(text, style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      );

  Widget _buildModernTextField({required TextEditingController controller, required String hint, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF151921),
        contentPadding: const EdgeInsets.all(18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.gold)),
      ),
    );
  }

  Widget _dropdown({required String? value, required String hint, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF151921), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gold),
          decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: const TextStyle(color: Colors.white24)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Required' : null,
        ),
      ),
    );
  }

  Widget _pickerField({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFF151921), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))),
          ],
        ),
      ),
    );
  }
}
