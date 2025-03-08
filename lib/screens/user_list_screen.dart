import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'add_user_screen.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _dbHelper = DatabaseHelper();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  TextEditingController _searchController = TextEditingController();
  String _selectedGender = 'All';
  bool _isSortedAZ = false;
  bool _isSortedZA = false;
  int? _filterAge;
  DateTime? _filterDOB;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    List<User> users = await _dbHelper.getUsers();
    setState(() {
      _users = users;
      _filteredUsers = users;
      _isLoading = false;
    });
  }

  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        bool matchesSearch = user.name.toLowerCase().contains(query) ||
            user.city.toLowerCase().contains(query);
        bool matchesGender = _selectedGender == 'All' || user.gender == _selectedGender;
        bool matchesAge = _filterAge == null || user.age >= _filterAge!;
        bool matchesDOB = _filterDOB == null || DateTime.now().subtract(Duration(days: 365 * user.age)).isAfter(_filterDOB!);
        return matchesSearch && matchesGender && matchesAge && matchesDOB;
      }).toList();
      _sortUsers();
    });
  }

  void _sortUsers() {
    setState(() {
      _filteredUsers.sort((a, b) {
        if (a.isFavorite != b.isFavorite) {
          return b.isFavorite - a.isFavorite;
        }
        if (_isSortedAZ) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        if (_isSortedZA) {
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        }
        return 0;
      });
    });
  }

  void _toggleSortOrderAZ() {
    setState(() {
      _isSortedAZ = !_isSortedAZ;
      _isSortedZA = false;
      _sortUsers();
    });
  }

  void _toggleSortOrderZA() {
    setState(() {
      _isSortedZA = !_isSortedZA;
      _isSortedAZ = false;
      _sortUsers();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filter Users', style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterOption(
                  title: 'Sort by Name (A-Z)',
                  isSelected: _isSortedAZ,
                  onChanged: (bool? value) {
                    _toggleSortOrderAZ();
                    Navigator.of(context).pop();
                  },
                ),
                _buildFilterOption(
                  title: 'Sort by Name (Z-A)',
                  isSelected: _isSortedZA,
                  onChanged: (bool? value) {
                    _toggleSortOrderZA();
                    Navigator.of(context).pop();
                  },
                ),
                Divider(),
                ListTile(
                  title: Text('Filter by Age (>=)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<int>(
                      value: _filterAge,
                      hint: Text('Select'),
                      underline: SizedBox(),
                      items: [5, 18, 25, 30, 40, 50, 60]
                          .map((age) => DropdownMenuItem<int>(
                        value: age,
                        child: Text('$age'),
                      ))
                          .toList(),
                      onChanged: (int? value) {
                        setState(() {
                          _filterAge = value;
                          _filterUsers();
                          Navigator.of(context).pop();
                        });
                      },
                    ),
                  ),
                ),
                ListTile(
                  title: Text('Filter by DOB (After)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFFF0F4F8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _filterDOB == null
                          ? 'Select Date'
                          : DateFormat('dd/MM/yyyy').format(_filterDOB!),
                      style: TextStyle(color: Colors.black87),
                    ),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF5D3FD3),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _filterDOB = picked;
                          _filterUsers();
                          Navigator.of(context).pop();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Clear Filters',
                  style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                setState(() {
                  _isSortedAZ = false;
                  _isSortedZA = false;
                  _filterAge = null;
                  _filterDOB = null;
                  _filterUsers();
                  Navigator.of(context).pop();
                });
              },
            ),
            TextButton(
              child: Text('Apply',
                  style: TextStyle(color: Color(0xFF5D3FD3), fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String title,
    required bool isSelected,
    required Function(bool?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF5D3FD3).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? Color(0xFF5D3FD3) : Colors.black87,
        )),
        trailing: Checkbox(
          value: isSelected,
          activeColor: Color(0xFF5D3FD3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _navigateToAddUserScreen() async {
    bool? userAdded = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddUserScreen()),
    );
    if (userAdded == true) {
      _fetchUsers(); // Refresh user list
    }
  }

  void _editUser(User user) async {
    bool? userEdited = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddUserScreen(user: user)),
    );
    if (userEdited == true) {
      _fetchUsers(); // Refresh user list
    }
  }

  void _deleteUser(int userId) async {
    await _dbHelper.deleteUser(userId);
    _fetchUsers(); // Refresh user list
  }

  void _confirmDeleteUser(int userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this user?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser(userId);
              },
            ),
          ],
        );
      },
    );
  }

  void _shareUser(User user) {
    final String dobString = DateFormat('dd/MM/yyyy').format(
        DateTime.now().subtract(Duration(days: 365 * user.age)));

    String shareText = """
Contact Details:
Name: ${user.name}
Email: ${user.email}
Mobile: ${user.mobile}
Date of Birth: $dobString
City: ${user.city}
Gender: ${user.gender}
""";

    // Show a sharing dialog with options
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Share ${user.name}'s Details"),
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
                  Clipboard.setData(ClipboardData(text: shareText));
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
                  child: Icon(Icons.share, color: Color(0xFF4ECDC4)),
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
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleFavorite(User user) async {
    await _dbHelper.toggleFavorite(user.id!);
    setState(() {
      user.isFavorite = user.isFavorite == 1 ? 0 : 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user.isFavorite == 1 ? 'Added to favorites!' : 'Removed from favorites',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: user.isFavorite == 1 ? Color(0xFFFFA726) : Colors.grey[700],
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    _sortUsers();
  }

  void _navigateToUserDetailScreen(User user) async {
    bool? userEdited = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailScreen(user: user)),
    );
    if (userEdited == true) {
      _fetchUsers(); // Refresh user list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Explore Profiles',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                child: Icon(Icons.filter_list, color: Color(0xFF5D3FD3)),
              ),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF5D3FD3),
        elevation: 4,
        onPressed: _navigateToAddUserScreen,
      ),
      body: _isLoading
          ? Center(
        child: SpinKitDoubleBounce(
          color: Color(0xFF5D3FD3),
          size: 50.0,
        ),
      )
          : Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Name or City',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildGenderChip('All'),
                  SizedBox(width: 8),
                  _buildGenderChip('Male'),
                  SizedBox(width: 8),
                  _buildGenderChip('Female'),
                  SizedBox(width: 8),
                  _buildGenderChip('Other'),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: _filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                User user = _filteredUsers[index];
                return _buildUserCard(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String gender) {
    bool isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
          _filterUsers();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF5D3FD3) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          gender,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No profiles found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final String dobString = DateFormat('dd/MM/yyyy').format(
        DateTime.now().subtract(Duration(days: 365 * user.age)));

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          // Profile Header
          InkWell(
            onTap: () => _navigateToUserDetailScreen(user),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      backgroundImage: user.profileImagePath != null
                          ? FileImage(File(user.profileImagePath!))
                          : null,
                      child: user.profileImagePath == null
                          ? Icon(Icons.person, size: 40, color: Colors.grey)
                          : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            if (user.isEmailVerified)
                              Icon(Icons.verified, color: Colors.green, size: 16),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${user.age} years • ${user.gender}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              user.city,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      user.isFavorite == 1 ? Icons.favorite : Icons.favorite_border,
                      color: user.isFavorite == 1 ? Colors.redAccent : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(user),
                  ),
                ],
              ),
            ),
          ),

          // Actions row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  color: Color(0xFF4ECDC4),
                  label: 'Edit',
                  onTap: () => _editUser(user),
                ),
                _buildActionDivider(),
                _buildActionButton(
                  icon: Icons.share,
                  color: Color(0xFF5D3FD3),
                  label: 'Share',
                  onTap: () => _shareUser(user),
                ),
                _buildActionDivider(),
                _buildActionButton(
                  icon: Icons.delete,
                  color: Colors.redAccent,
                  label: 'Delete',
                  onTap: () => _confirmDeleteUser(user.id!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.withOpacity(0.2),
    );
  }
}