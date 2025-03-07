import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AddUserScreen extends StatefulWidget {
  final User? user;

  AddUserScreen({this.user});

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String? _selectedGender;
  String? _selectedCity;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _firstNameController.text = widget.user!.name.split(' ')[0];
      _lastNameController.text = widget.user!.name.split(' ').length > 1 ? widget.user!.name.split(' ')[1] : '';
      _emailController.text = widget.user!.email;
      _mobileController.text = widget.user!.mobile;
      _dobController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(Duration(days: 365 * widget.user!.age)));
      _passwordController.text = widget.user!.password;
      _confirmPasswordController.text = widget.user!.password;
      _selectedGender = widget.user!.gender;
      _selectedCity = widget.user!.city;
      if (widget.user!.profileImagePath != null) {
        _profileImage = File(widget.user!.profileImagePath!);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter a valid name';
    }
    if (value.contains(' ') || value.contains(RegExp(r'[^a-zA-Z]'))) {
      return 'Name cannot contain spaces or special characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[!@#\$&*~]).{6,}$').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter and one special character';
    }
    return null;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _addUser() async {
    if (_formKey.currentState!.validate() && _selectedGender != null && _selectedCity != null) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorSnackBar('Passwords do not match');
        return;
      }

      DateTime dob = DateFormat('dd/MM/yyyy').parse(_dobController.text);
      int age = DateTime.now().year - dob.year;
      if (age < 18) {
        _showErrorSnackBar('Age must be 18 or above');
        return;
      }

      User user = User(
        name: '${_firstNameController.text} ${_lastNameController.text}',
        email: _emailController.text,
        mobile: _mobileController.text,
        age: age,
        city: _selectedCity!,
        gender: _selectedGender!,
        password: _passwordController.text,
        profileImagePath: _profileImage?.path,
      );

      int result;
      if (widget.user == null) {
        result = await _dbHelper.insertUser(user);
      } else {
        user.id = widget.user!.id;
        result = await _dbHelper.updateUser(user);
      }

      if (result != -1) {
        _showSuccessSnackBar('User ${widget.user == null ? 'Added' : 'Updated'} Successfully!');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Failed to ${widget.user == null ? 'add' : 'update'} user.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Color(0xFF4ECDC4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateFormat('dd/MM/yyyy').parse(_dobController.text)
          : DateTime.now().subtract(Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF5D3FD3),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF5D3FD3),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          widget.user == null ? 'Add Profile' : 'Edit Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                _buildFormSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5D3FD3),
            Color(0xFF7B68EE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.user == null ? 'Create Your Profile' : 'Update Your Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                      image: _profileImage != null
                          ? DecorationImage(
                        image: FileImage(_profileImage!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _profileImage == null
                        ? Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    )
                        : null,
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Color(0xFF5D3FD3),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Upload a profile picture',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  hinttext: 'First Name',
                  prefixIcon: Icons.person_outline,
                  validator: _validateName,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  hinttext: 'Last Name',
                  prefixIcon: Icons.person_outline,
                  validator: _validateName,
                ),
              ),
            ],
          ),
          _buildTextField(
            controller: _emailController,
            hinttext: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => RegExp(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$").hasMatch(value!)
                ? null
                : 'Enter a valid email',
          ),
          _buildTextField(
            controller: _mobileController,
            hinttext: 'Mobile Number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) => value!.length == 10 ? null : 'Enter a valid 10-digit number',
          ),
          _buildDateField(
            controller: _dobController,
            labelText: 'Date of Birth',
            validator: (value) => value!.isEmpty ? 'Enter date of birth' : null,
          ),
          _buildDropdownField(
            hinttext: 'Gender',
            prefixIcon: Icons.people_outline,
            value: _selectedGender,
            items: ['Male', 'Female', 'Other'],
            onChanged: (value) => setState(() => _selectedGender = value),
            validator: (value) => value == null ? 'Select gender' : null,
          ),
          _buildDropdownField(
            hinttext: 'City',
            prefixIcon: Icons.location_city_outlined,
            value: _selectedCity,
            items: ["Ahmedabad", "Surat", "Vadodara", "Rajkot", "Bhavnagar", "Jamnagar", "Junagadh", "Gandhinagar"],
            onChanged: (value) => setState(() => _selectedCity = value),
            validator: (value) => value == null ? 'Select city' : null,
          ),
          SizedBox(height: 24),
          Text(
            'Security',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildPasswordField(
            controller: _passwordController,
            hinttext: 'Password',
            isVisible: _isPasswordVisible,
            onVisibilityChanged: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hinttext: 'Confirm Password',
            isVisible: _isConfirmPasswordVisible,
            onVisibilityChanged: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          ),
          SizedBox(height: 30),
          _buildSubmitButton(),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hinttext,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: hinttext,
          prefixIcon: Icon(prefixIcon, color: Color(0xFF5D3FD3)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFF5D3FD3), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          errorStyle: TextStyle(
            fontSize: 12,
            color: Colors.redAccent,
          ),
          errorMaxLines: 3, // Allows error text to display multiple lines
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hinttext,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: hinttext,
          prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF5D3FD3)),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Color(0xFF5D3FD3),
            ),
            onPressed: onVisibilityChanged,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFF5D3FD3), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          errorStyle: TextStyle(
            fontSize: 12,
            color: Colors.redAccent,
          ),
          errorMaxLines: 3, // Allows error text to display multiple lines
        ),
        validator: _validatePassword,
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(context),
        decoration: InputDecoration(
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: 'DD/MM/YYYY',
          prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF5D3FD3)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFF5D3FD3), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          errorStyle: TextStyle(
            fontSize: 12,
            color: Colors.redAccent,
          ),
          errorMaxLines: 2, // Allows error text to display multiple lines
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String hinttext,
    required IconData prefixIcon,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
    required String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: 'Select $hinttext',
          prefixIcon: Icon(prefixIcon, color: Color(0xFF5D3FD3)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFF5D3FD3), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          errorStyle: TextStyle(
            fontSize: 12,
            color: Colors.redAccent,
          ),
          errorMaxLines: 2, // Allows error text to display multiple lines
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF5D3FD3)),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(15),
        isExpanded: true, // Makes sure the dropdown uses all available space
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _addUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF5D3FD3),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: Color(0xFF5D3FD3).withOpacity(0.5),
        ),
        child: Text(
          widget.user == null ? 'Create Profile' : 'Update Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}