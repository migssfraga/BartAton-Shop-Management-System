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
          final techQuery = await _firestore
              .collection('users')
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
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D12),
      body: Stack(
        children: [
          // Workshop Background Image with Dark Overlay
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1581092160607-ee22621dd758?q=80&w=1920&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF0B0D12)),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.82),
            ),
          ),

          // Top-Left Yellow Banner Shape
          Positioned(
            top: 0,
            left: 0,
            child: ClipPath(
              clipper: TopLeftYellowClipper(),
              child: Container(
                width: isWideScreen ? 360 : 220,
                height: isWideScreen ? 360 : 220,
                color: AppColors.gold,
              ),
            ),
          ),

          // Bottom-Right Yellow Banner Shape
          Positioned(
            bottom: 0,
            right: 0,
            child: ClipPath(
              clipper: BottomRightYellowClipper(),
              child: Container(
                width: isWideScreen ? 400 : 240,
                height: isWideScreen ? 400 : 240,
                color: AppColors.gold,
              ),
            ),
          ),

          // Content Layer
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1150),
                  child: isWideScreen
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Side Branding
                            Expanded(
                              flex: 5,
                              child: _buildBrandingSection(isMobile: false),
                            ),
                            const SizedBox(width: 48),
                            // Right Side Login Card
                            Expanded(
                              flex: 5,
                              child: _buildLoginCard(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildBrandingSection(isMobile: true),
                            const SizedBox(height: 32),
                            _buildLoginCard(),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingSection({required bool isMobile}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        Image.asset(
          'assets/logo.png',
          height: isMobile ? 120 : 180,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),

        // Slogan with lines: — BUILD TODAY, SOLVE TOMORROW —
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 24 : 40,
              height: 2,
              color: AppColors.gold,
            ),
            const SizedBox(width: 12),
            Text(
              'BUILD TODAY, SOLVE TOMORROW',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 11 : 13,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: isMobile ? 24 : 40,
              height: 2,
              color: AppColors.gold,
            ),
          ],
        ),
        const SizedBox(height: 40),

        // 3 Feature Cards
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFeatureCard(
              icon: Icons.shopping_cart_outlined,
              title: 'Quality\nProducts',
            ),
            const SizedBox(width: 16),
            _buildFeatureCard(
              icon: Icons.verified_user_outlined,
              title: 'Reliable\nService',
            ),
            const SizedBox(width: 16),
            _buildFeatureCard(
              icon: Icons.groups_outlined,
              title: 'Trusted\nCommunity',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
  }) {
    return Container(
      width: 105,
      height: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141720).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gold, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF12141B).withOpacity(0.93),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.gold,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          RichText(
            text: const TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
              children: [
                TextSpan(text: 'Welcome '),
                TextSpan(text: 'Back!', style: TextStyle(color: AppColors.gold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log in to your account to continue to BartAton Shop System.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 32),

          // Email / Username Input
          _buildInputField(
            controller: _emailController,
            hint: 'Email or Username',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 18),

          // Password Input
          _buildInputField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 16),

          // Remember Me & Forgot Password Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 22,
                    width: 22,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.gold,
                      checkColor: Colors.black,
                      side: const BorderSide(color: AppColors.gold, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Remember Me',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Forgot Password?',
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // LOGIN Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                elevation: 6,
                shadowColor: AppColors.gold.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('LOGIN',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1.5)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 28),

          // OR Divider
          Row(
            children: [
              Expanded(
                  child: Divider(
                      color: Colors.white.withOpacity(0.12), thickness: 1)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR',
                    style: TextStyle(
                        color: Colors.white30,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                  child: Divider(
                      color: Colors.white.withOpacity(0.12), thickness: 1)),
            ],
          ),

          const SizedBox(height: 24),

          // Sign Up Footer
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/register'),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.white60, fontSize: 13.5),
                  children: [
                    TextSpan(text: "Don't have an account? "),
                    TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                            color: AppColors.gold, fontWeight: FontWeight.bold)),
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
        color: const Color(0xFF1D2029).withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class TopLeftYellowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.75, 0);
    path.lineTo(size.width * 0.42, size.height * 0.38);
    path.lineTo(size.width * 0.52, size.height * 0.38);
    path.lineTo(0, size.height * 0.95);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomRightYellowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, size.height);
    path.lineTo(size.width * 0.25, size.height);
    path.lineTo(size.width * 0.58, size.height * 0.62);
    path.lineTo(size.width * 0.48, size.height * 0.62);
    path.lineTo(size.width, size.height * 0.05);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
