import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final nameRegex = RegExp(r'^[a-zA-ZñÑ\s\-\.]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Enter valid $fieldName (letters only)';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'At least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim().toLowerCase();
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!gmailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid Gmail address (e.g. name@gmail.com)';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      return 'Enter a valid mobile number (e.g. 0917...)';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Delivery address is required';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleCreateAccount() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;
      final uid = user?.uid;
      if (uid != null) {
        try {
          await user?.sendEmailVerification();
        } catch (_) {}

        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'displayName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'address': _addressController.text.trim(),
          'role': 'customer',
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Verification email sent. Please verify your inbox.'), 
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'An error occurred.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02040A),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Create Account',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Join BartAton Shop & enjoy reliable service',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _firstNameController,
                            hint: 'First Name',
                            icon: Icons.person_outline,
                            validator: (v) => _validateName(v, 'First name'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            controller: _lastNameController,
                            hint: 'Last Name',
                            icon: Icons.person_outline,
                            validator: (v) => _validateName(v, 'Last name'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      controller: _usernameController,
                      hint: 'Username',
                      icon: Icons.alternate_email,
                      validator: _validateUsername,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      controller: _mobileController,
                      hint: 'Mobile Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validateMobile,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      controller: _addressController,
                      hint: 'Delivery / Service Address',
                      icon: Icons.location_on_outlined,
                      validator: _validateAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      controller: _passwordController, 
                      hint: 'Password', 
                      icon: Icons.lock_outline, 
                      obscure: _obscurePassword,
                      validator: _validatePassword,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      controller: _confirmPasswordController, 
                      hint: 'Confirm Password', 
                      icon: Icons.lock_outline, 
                      obscure: _obscureConfirm,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirm password is required';
                        if (v != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                      suffix: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5))),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleCreateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.background,
                          elevation: 4,
                          shadowColor: AppColors.gold.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2.5))
                            : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.white60, fontSize: 14),
                            children: [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(text: 'Log In', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14.5),
        validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required field' : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
