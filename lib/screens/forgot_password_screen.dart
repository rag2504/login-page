import 'package:flutter/material.dart';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _dbHelper = DatabaseHelper();
  String _email = '';
  String _otp = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isLoading = false;
  int _otpExpiryTime = 0;
  int _remainingSeconds = 300; // 5 minutes
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers to keep values after form state changes
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Direct Email Sending Function without complex validation
  Future<void> _sendOtp() async {
    // Get email from controller to ensure it's up to date
    _email = _emailController.text.trim();

    if (_email.isEmpty || !_email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          )
      );
      return;
    }

    print("Sending OTP to: $_email");
    setState(() {
      _isLoading = true;
    });

    // Check if user exists
    try {
      User? user = await _dbHelper.getUserByEmail(_email);

      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User not found with this email!'),
              backgroundColor: Colors.red,
            )
        );
        return;
      }

      // Generate OTP
      String otp = (1000 + Random().nextInt(9000)).toString();
      print("Generated OTP: $otp");
      int expiration = DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch;
      _otpExpiryTime = expiration;

      // Update OTP in database
      await _dbHelper.updateOtp(_email, otp, expiration);

      // Email configuration
      String username = 'ragraichura3@gmail.com';
      String password = 'dkwl asoc qhzb rpjr';

      final smtpServer = gmail(username, password);
      final message = Message()
        ..from = Address(username, 'rag app')
        ..recipients.add(_email)
        ..subject = 'OTP for Password Reset'
        ..text = 'Your OTP for password reset is: $otp';

      print("Sending email with OTP: $otp");
      final sendReport = await send(message, smtpServer);
      print("Email sent successfully: $sendReport");

      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });

      // Start the OTP timer
      _startOtpTimer();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to your email!'),
            backgroundColor: Colors.green,
          )
      );
    } catch (e) {
      print("Error in sending OTP: $e");
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: ${e.toString()}'),
            backgroundColor: Colors.red,
          )
      );
    }
  }

  void _startOtpTimer() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _remainingSeconds = (_otpExpiryTime - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
        if (_remainingSeconds < 0) _remainingSeconds = 0;
      });

      return _remainingSeconds > 0 && _isOtpSent && !_isOtpVerified;
    });
  }

  String _formatRemainingTime() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOtp() async {
    // Get OTP from controller
    _otp = _otpController.text.trim();

    if (_otp.isEmpty || _otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid 4-digit OTP'),
            backgroundColor: Colors.red,
          )
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _dbHelper.validateOtp(_email, _otp);

      if (user != null) {
        setState(() {
          _isOtpVerified = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP verified! You can now reset your password.'),
              backgroundColor: Colors.green,
            )
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid or expired OTP.'),
              backgroundColor: Colors.red,
            )
        );
      }
    } catch (e) {
      print("Error in verifying OTP: $e");
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying OTP: ${e.toString()}'),
            backgroundColor: Colors.red,
          )
      );
    }
  }

  Future<void> _resetPassword() async {
    // Get password values from controllers
    _newPassword = _passwordController.text;
    _confirmPassword = _confirmPasswordController.text;

    if (_newPassword.isEmpty || _newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password must be at least 6 characters'),
            backgroundColor: Colors.red,
          )
      );
      return;
    }

    if (_newPassword != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passwords do not match!'),
            backgroundColor: Colors.red,
          )
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _dbHelper.resetPassword(_email, _newPassword);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password has been reset successfully!'),
            backgroundColor: Colors.green,
          )
      );

      // Navigate back to login
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } catch (e) {
      print("Error in resetting password: $e");
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting password: ${e.toString()}'),
            backgroundColor: Colors.red,
          )
      );
    }
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(1, true, 'Email'),
          _buildStepConnector(_isOtpSent),
          _buildStepCircle(2, _isOtpSent, 'Verify OTP'),
          _buildStepConnector(_isOtpVerified),
          _buildStepCircle(3, _isOtpVerified, 'Reset Password'),
        ],
      ),
    );
  }
  Widget _buildStepCircle(int step, bool isActive, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2), // Adjusts spacing
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? Colors.teal : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 4), // Reduced gap for better alignment
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.teal : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 20, // Adjust the width as needed
      height: 4, // Ensure consistent height
      margin: EdgeInsets.symmetric(horizontal: 2), // Reduce unwanted spacing
      decoration: BoxDecoration(
        color: isActive ? Colors.yellow : Colors.grey,
        borderRadius: BorderRadius.circular(2), // Smooth edges
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                    ),
                  ),

                  _buildStepIndicator(),

                  // Only show the current step
                  !_isOtpSent
                      ? _buildEmailStep()
                      : (_isOtpVerified
                      ? _buildPasswordStep()
                      : _buildOtpStep()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                _email = value.trim();
              },
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _sendOtp, // Direct connection to the function
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                child: Text('Send OTP', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpStep() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Show the email that was entered
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.teal),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _email,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isOtpSent = false;
                      });
                    },
                    child: Text('Change'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Timer display
            if (_remainingSeconds > 0 && !_isOtpVerified)
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'OTP expires in: ${_formatRemainingTime()}',
                      style: TextStyle(
                        color: _remainingSeconds < 60 ? Colors.red : Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            TextFormField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'Enter 4-digit OTP',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                hintText: '1234',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              onChanged: (value) {
                _otp = value.trim();
              },
            ),
            SizedBox(height: 10),

            _isLoading
                ? CircularProgressIndicator()
                : Column(
              children: [
                ElevatedButton(
                  onPressed: _verifyOtp,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    child: Text('Verify OTP', style: TextStyle(fontSize: 18)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: _remainingSeconds <= 0 ? _sendOtp : null,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: _remainingSeconds <= 0 ? Colors.teal : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Show the email that was verified
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'OTP verified for $_email',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
              ),
              obscureText: _obscurePassword,
              onChanged: (value) {
                _newPassword = value;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
              ),
              obscureText: _obscureConfirmPassword,
              onChanged: (value) {
                _confirmPassword = value;
              },
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _resetPassword,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                child: Text('Reset Password', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}