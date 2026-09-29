import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _obscure = true;
  bool _rememberMe = false;
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Clear user data cache before logging in to ensure fresh data
      UserService().clearCache();

      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // If user not found in Auth, but exists as a technician in Firestore, create auth account on the fly
        if (e.code == 'user-not-found') {
          final techQuery = await _firestore.collection('users')
              .where('email', isEqualTo: email)
              .where('role', isEqualTo: 'technician')
              .get();

          if (techQuery.docs.isNotEmpty) {
            try {
              userCredential = await _auth.createUserWithEmailAndPassword(
                email: email,
                password: password,
              );
            } catch (createErr) {
              rethrow;
            }
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      final user = userCredential.user;
      final uid = user?.uid;
      if (uid != null && user != null) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (!mounted) return;
        if (userDoc.exists) {
          final role = userDoc.data()?['role'] ?? 'customer';

          switch (role) {
            case 'admin':
              Navigator.of(context).pushReplacementNamed('/admin');
              break;
            case 'technician':
              Navigator.of(context).pushReplacementNamed('/technician');
              break;
            default:
              Navigator.of(context).pushReplacementNamed('/customer');
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'User data not found.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Invalid email or password.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong.';
      });
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your Gmail address to receive a password reset link.', style: TextStyle(color: AppColors.lightGray, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'name@gmail.com',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38),
                filled: true,
                fillColor: AppColors.background,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.background),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.endsWith('@gmail.com')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid @gmail.com address.'), backgroundColor: AppColors.danger),
                );
                return;
              }
              try {
                await _auth.sendPasswordResetEmail(email: email);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent! Check your inbox.'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            child: const Text('Send Link', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02040A), // Very dark background
      body: Stack(
        children: [
          // Background Corner Decorations
          Positioned(
            top: -40,
            left: -60,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 250,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.gold.withOpacity(0.1)],
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -80,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: 300,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold.withOpacity(0.1), AppColors.gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Logo Section
                    Image.asset(
                      'assets/logo.png',
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 40),
                    
                    // Welcome Text
                    Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(text: 'Welcome '),
                              TextSpan(text: 'Back!', style: TextStyle(color: AppColors.gold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Log in to your account to continue',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Email Field
                    _buildInputField(
                      controller: _emailController,
                      hint: 'Email or Username',
                      icon: Icons.email_outlined,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Password Field
                    _buildInputField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white38, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.gold,
                                checkColor: Colors.black,
                                side: const BorderSide(color: AppColors.gold, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Remember Me', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text('Forgot Password?',
                              style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          elevation: 8,
                          shadowColor: AppColors.gold.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
                                  SizedBox(width: 12),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // OR Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Footer
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/register'),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.white60, fontSize: 14),
                          children: [
                            TextSpan(text: "Don't have an account? "),
                            TextSpan(text: 'Sign Up', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                          ],
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151921).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(icon, color: Colors.white38, size: 22),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
