import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  bool _isPdfGenerating = false;
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
          backgroundColor: Color(0xFF5D3FD3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
          backgroundColor: Color(0xFF4ECDC4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid OTP'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isPdfGenerating = true;
    });

    try {
      final pdf = pw.Document();

      // Create a PDF document
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'User Profile',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Container(
                    width: 120,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: PdfColors.purple, width: 2),
                    ),
                    child: widget.user.profileImagePath != null
                        ? pw.ClipOval(
                      child: pw.Image(
                        pw.MemoryImage(
                          File(widget.user.profileImagePath!).readAsBytesSync(),
                        ),
                        fit: pw.BoxFit.cover,
                      ),
                    )
                        : pw.Center(
                      child: pw.Text(
                        widget.user.name.substring(0, 1).toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 40,
                          color: PdfColors.purple,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildPdfDetailRow('Name', widget.user.name),
                _buildPdfDetailRow('Email', widget.user.email),
                _buildPdfDetailRow('Mobile', widget.user.mobile),
                _buildPdfDetailRow('Date of Birth', DateFormat('dd/MM/yyyy').format(
                  DateTime.now().subtract(Duration(days: 365 * widget.user.age)),
                )),
                _buildPdfDetailRow('City', widget.user.city),
                _buildPdfDetailRow('Gender', widget.user.gender),
                _buildPdfDetailRow('Email Verified', isEmailVerified ? 'Yes' : 'No'),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save the PDF
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${widget.user.name.replaceAll(' ', '_')}_profile.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      await Share.shareFiles([filePath], text: 'User Profile for ${widget.user.name}');

      setState(() {
        _isPdfGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generated and shared!'),
          backgroundColor: Color(0xFF5D3FD3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isPdfGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    final String dobString = DateFormat('dd/MM/yyyy').format(
        DateTime.now().subtract(Duration(days: 365 * widget.user.age)));

    String shareText = """
Contact Details:
Name: ${widget.user.name}
Email: ${widget.user.email}
Mobile: ${widget.user.mobile}
Date of Birth: $dobString
City: ${widget.user.city}
Gender: ${widget.user.gender}
""";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Share ${widget.user.name}'s Details"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF5D3FD3).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.copy, color: Color(0xFF5D3FD3)),
                ),
                title: Text('Copy to Clipboard'),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contact details copied to clipboard'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.picture_as_pdf, color: Color(0xFF4ECDC4)),
                ),
                title: Text('Generate PDF'),
                onTap: () {
                  Navigator.of(context).pop();
                  _generatePdf();
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFA726).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.share, color: Color(0xFFFFA726)),
                ),
                title: Text('Other Sharing Options'),
                onTap: () {
                  Navigator.of(context).pop();
                  Share.share(shareText);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String dobString = DateFormat('dd/MM/yyyy').format(
      DateTime.now().subtract(Duration(days: 365 * widget.user.age)),
    );

    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Profile Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF5D3FD3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.share, color: Color(0xFF5D3FD3)),
              ),
              onPressed: _showShareDialog,
            ),
          ),
        ],
      ),
      body: _isPdfGenerating
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitDoubleBounce(
              color: Color(0xFF5D3FD3),
              size: 50.0,
            ),
            SizedBox(height: 16),
            Text(
              'Generating PDF...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5D3FD3),
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header with image
            Center(
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF5D3FD3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.user.profileImagePath != null
                      ? FileImage(File(widget.user.profileImagePath!))
                      : null,
                  child: widget.user.profileImagePath == null
                      ? Text(
                    widget.user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 40,
                      color: Color(0xFF5D3FD3),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Name and verification status
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.user.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 8),
                      if (isEmailVerified)
                        Icon(Icons.verified, color: Color(0xFF4ECDC4), size: 20),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${widget.user.age} years • ${widget.user.gender}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        widget.user.city,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Section title
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D3FD3),
                ),
              ),
            ),

            // User details in cards
            _buildDetailCard(Icons.email, 'Email', widget.user.email, isEmail: true),
            SizedBox(height: 12),

            // OTP verification section if needed
            if (_isOtpSent)
              Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D3FD3),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Enter OTP',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xFF5D3FD3), width: 2),
                          ),
                          prefixIcon: Icon(Icons.security, color: Color(0xFF5D3FD3)),
                        ),
                        keyboardType: TextInputType.number,
                        onSubmitted: (value) {
                          if (value.length == 4) {
                            _verifyOtp(value);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter a valid 4-digit OTP'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

            _buildDetailCard(Icons.phone, 'Mobile', widget.user.mobile),
            SizedBox(height: 12),
            _buildDetailCard(Icons.cake, 'Date of Birth', dobString),
            SizedBox(height: 12),
            _buildDetailCard(Icons.location_city, 'City', widget.user.city),
            SizedBox(height: 12),
            _buildDetailCard(Icons.person_outline, 'Gender', widget.user.gender),

            SizedBox(height: 32),

            // Actions section
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D3FD3),
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    color: Color(0xFF4ECDC4),
                    label: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  _buildActionButton(
                    icon: Icons.picture_as_pdf,
                    color: Color(0xFF5D3FD3),
                    label: 'Generate PDF Profile',
                    onTap: _generatePdf,
                  ),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                  _buildActionButton(
                    icon: Icons.share,
                    color: Color(0xFFFFA726),
                    label: 'Share Contact Details',
                    onTap: _showShareDialog,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value, {bool isEmail = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF5D3FD3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Color(0xFF5D3FD3)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isEmail && !isEmailVerified)
              TextButton.icon(
                onPressed: _isLoading ? null : _sendOtp,
                icon: _isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF5D3FD3),
                    strokeWidth: 2,
                  ),
                )
                    : Icon(Icons.verified_outlined, color: Color(0xFF5D3FD3)),
                label: Text(
                  'Verify',
                  style: TextStyle(color: Color(0xFF5D3FD3)),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFF5D3FD3).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}