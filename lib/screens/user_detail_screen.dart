import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import '../models/user_model.dart';
import '../database/database_helper.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  UserDetailScreen({required this.user});

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool isEmailVerified = false;
  final _dbHelper = DatabaseHelper();
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _otp;

  @override
  void initState() {
    super.initState();
    isEmailVerified = widget.user.isEmailVerified;
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate OTP
      _otp = (1000 + Random().nextInt(9000)).toString();
      int expiration = DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch;

      // Update OTP in database
      await _dbHelper.updateOtp(widget.user.email, _otp!, expiration);

      // Email configuration
      String username = 'ragraichura3@gmail.com';
      String password = 'dkwlasocqhzbrpjr';

      final smtpServer = gmail(username, password);
      final message = Message()
        ..from = Address(username, 'rag app')
        ..recipients.add(widget.user.email)
        ..subject = 'OTP for Email Verification'
        ..text = 'Your OTP for email verification is: $_otp';

      await send(message, smtpServer);

      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to ${widget.user.email}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtp(String enteredOtp) async {
    if (_otp == enteredOtp) {
      await _dbHelper.updateEmailVerificationStatus(widget.user.email, true);
      setState(() {
        isEmailVerified = true;
        _isOtpSent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dobString = DateFormat('dd/MM/yyyy').format(
      DateTime.now().subtract(Duration(days: 365 * widget.user.age)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
        backgroundColor: Colors.teal,
        actions: [
          Icon(
            isEmailVerified ? Icons.verified : Icons.verified_outlined,
            color: isEmailVerified ? Colors.green : Colors.grey,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.user.profileImagePath != null)
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: FileImage(File(widget.user.profileImagePath!)),
                ),
              ),
            SizedBox(height: 16),
            _buildDetailCard(Icons.person, 'Name', widget.user.name),
            SizedBox(height: 8),
            _buildDetailCard(Icons.email, 'Email', widget.user.email, isEmail: true),
            SizedBox(height: 8),
            if (_isOtpSent)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (value) {
                    if (value.length == 4) {
                      _verifyOtp(value);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid OTP'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            SizedBox(height: 8),
            _buildDetailCard(Icons.phone, 'Mobile', widget.user.mobile),
            SizedBox(height: 8),
            _buildDetailCard(Icons.cake, 'Date of Birth', dobString),
            SizedBox(height: 8),
            _buildDetailCard(Icons.location_city, 'City', widget.user.city),
            SizedBox(height: 8),
            _buildDetailCard(Icons.person_outline, 'Gender', widget.user.gender),
            SizedBox(height: 16),
            if (isEmailVerified)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'User Verified',
                      style: TextStyle(fontSize: 18, color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value, {bool isEmail = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                '$label: $value',
                style: TextStyle(fontSize: 18),
              ),
            ),
            if (isEmail && !isEmailVerified)
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: _isLoading ? CircularProgressIndicator() : Text('Verify'),
              ),
          ],
        ),
      ),
    );
  }
}