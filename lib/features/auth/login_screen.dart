import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/hod/hod_dashboard_screen.dart';
import '../../features/faculty/faculty_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  bool _isSignUp = false;
  bool _isHod = false; // false = Faculty, true = HOD

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || (_isSignUp && name.isEmpty)) {
      _showSnackBar("Please fill in all required fields", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // ==========================================
        // SIGN UP FLOW
        // ==========================================
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
          final String node = _isHod ? 'hod' : 'faculty';

          // Realtime DB node keys cannot contain . # $ [ or ]
          final String safeName = name.replaceAll(RegExp(r'[.#$\[\]]'), '_');

          // Save to REALTIME DATABASE using the user's NAME as the node
          await dbRef.child(node).child(safeName).set({
            'uid': userCredential.user!.uid,
            'name': name,
            'email': email,
            'role': _isHod ? 'hod' : 'faculty',
            'createdAt': ServerValue.timestamp, // RTDB specific timestamp
          });

          if (mounted) {
            _showSnackBar("Account created successfully! You can now log in.", Colors.green);
            setState(() {
              _isSignUp = false;
              _passwordController.clear();
            });
          }
        }
      } else {
        // ==========================================
        // SIGN IN FLOW & ROUTING
        // ==========================================
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

          // 1. Check if user is in the HOD node
          final hodSnapshot = await dbRef.child('hod')
              .orderByChild('email')
              .equalTo(email)
              .get();

          if (hodSnapshot.exists && mounted) {
            _showSnackBar("Welcome HOD!", Colors.green);
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HodDashboardScreen())
            );
            return;
          }

          // 2. If not HOD, check the Faculty node
          final facultySnapshot = await dbRef.child('faculty')
              .orderByChild('email')
              .equalTo(email)
              .get();

          if (facultySnapshot.exists && mounted) {
            _showSnackBar("Welcome Faculty!", Colors.green);
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const FacultyDashboardScreen())
            );
            return;
          }

          if (mounted) {
            _showSnackBar("User data not found in database.", Colors.orange);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showSnackBar(e.message ?? "Authentication failed.", Colors.redAccent);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Database Error: $e", Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Please enter your email address first to reset your password.", Colors.orange);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        _showSnackBar("Password reset link sent to your email.", Colors.green);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showSnackBar(e.message ?? "Failed to send reset email.", Colors.redAccent);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 80,
                      color: AppColors.primaryPurple
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  _isSignUp ? "Create Account" : "Welcome Back",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? "Sign up to join the portal"
                      : "Enter your credentials to continue",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isHod = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: !_isHod ? AppColors.primaryPurple : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "As Faculty",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isHod ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isHod = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: _isHod ? AppColors.primaryPurple : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "As HOD",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isHod ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_isSignUp) ...[
                  _buildTextField(
                    controller: _nameController,
                    label: "Full Name",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                ],

                _buildTextField(
                  controller: _emailController,
                  label: "Email Address",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                if (!_isSignUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      ),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 24),

                _isLoading
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: AppColors.primaryPurple),
                  ),
                )
                    : ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isSignUp ? "Create Account" : "Login",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? "Already have an account?" : "Don't have an account?",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          if (!_isSignUp) _nameController.clear();
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryPurple,
                      ),
                      child: Text(
                        _isSignUp ? "Log In" : "Create Account",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: AppColors.primaryPurple.withOpacity(0.7)),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey.shade400,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }
}