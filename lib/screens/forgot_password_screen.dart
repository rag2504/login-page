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
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  String _email = '';
  String _otp = '';
  String _newPassword = '';
  bool _isOtpSent = false;
  bool _isOtpVerified = false;

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      User? user = await _dbHelper.getUserByEmail(_email);

      if (user != null) {
        // Generate a random 4-digit OTP
        String otp = (1000 + Random().nextInt(9000)).toString();
        int expiration = DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch;

        await _dbHelper.updateOtp(_email, otp, expiration);

        // Email sending configuration
        String username = 'ragraichura3@gmail.com'; // Replace with your email
        String password = 'dkwl asoc qhzb rpjr'; // Replace with your app-specific password

        final smtpServer = gmail(username, password);
        final message = Message()
          ..from = Address(username, 'Your App Name')
          ..recipients.add(_email)
          ..subject = 'OTP for Password Reset'
          ..text = 'Your OTP for password reset is: $otp';

        try {
          print('Attempting to send email...');
          final sendReport = await send(message, smtpServer);
          print('Message sent: ' + sendReport.toString());

          setState(() {
            _isOtpSent = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP sent to your email!')));
        } on MailerException catch (e) {
          print('Message not sent: ${e.toString()}');
          for (var p in e.problems) {
            print('Problem: ${p.code}: ${p.msg}');
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send OTP. Please try again.')));
        } catch (e) {
          print('An unexpected error occurred: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unexpected error occurred. Please try again.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not found!')));
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      User? user = await _dbHelper.validateOtp(_email, _otp);

      if (user != null) {
        setState(() {
          _isOtpVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP verified! You can now reset your password.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid or expired OTP.')));
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await _dbHelper.resetPassword(_email, _newPassword);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password has been reset successfully!')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
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
              child: Form(
                key: _formKey,
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
                    SizedBox(height: 20),
                    if (!_isOtpSent)
                      Column(
                        children: [
                          TextFormField(
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
                            validator: (value) =>
                            value!.isEmpty || !value.contains('@')
                                ? 'Enter a valid email'
                                : null,
                            onSaved: (value) => _email = value!,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _sendOtp,
                            child: Text('Send OTP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal, // Updated
                              padding: EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                              textStyle: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    if (_isOtpSent && !_isOtpVerified)
                      Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'OTP',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                            value!.isEmpty ? 'Enter the OTP' : null,
                            onSaved: (value) => _otp = value!,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _verifyOtp,
                            child: Text('Verify OTP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal, // Updated
                              padding: EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                              textStyle: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    if (_isOtpVerified)
                      Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                            ),
                            obscureText: true,
                            validator: (value) =>
                            value!.isEmpty ? 'Enter your new password' : null,
                            onSaved: (value) => _newPassword = value!,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _resetPassword,
                            child: Text('Reset Password'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal, // Updated
                              padding: EdgeInsets.symmetric(
                                  horizontal: 50, vertical: 15),
                              textStyle: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
