import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'add_user_screen.dart';
import 'user_detail_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
    List<User> users = await _dbHelper.getUsers();
    setState(() {
      _users = users;
      _filteredUsers = users;
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
          title: Text('Filter Users'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Sort by Name (A-Z)'),
                  trailing: Checkbox(
                    value: _isSortedAZ,
                    onChanged: (bool? value) {
                      _toggleSortOrderAZ();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                ListTile(
                  title: Text('Sort by Name (Z-A)'),
                  trailing: Checkbox(
                    value: _isSortedZA,
                    onChanged: (bool? value) {
                      _toggleSortOrderZA();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                ListTile(
                  title: Text('Filter by Age (>=)'),
                  trailing: DropdownButton<int>(
                    value: _filterAge,
                    items: List.generate(100, (index) => index + 1)
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
                ListTile(
                  title: Text('Filter by DOB (After)'),
                  trailing: TextButton(
                    child: Text(_filterDOB == null
                        ? 'Select Date'
                        : DateFormat('dd/MM/yyyy').format(_filterDOB!)),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
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
              child: Text('Clear Filters'),
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
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.copy),
                title: Text('Copy to Clipboard'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: shareText));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contact details copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Other Sharing Options'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showShareOptions(shareText, user);
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

  // Helper methods for sharing
  void _showShareOptions(String text, User user) {
    Share.share(text);
  }

  void _toggleFavorite(User user) async {
    await _dbHelper.toggleFavorite(user.id!);
    setState(() {
      user.isFavorite = user.isFavorite == 1 ? 0 : 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(user.isFavorite == 1 ? 'User marked as favorite!' : 'User marked as unfavorite!'),
        duration: Duration(seconds: 2), // Reduced duration
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
      appBar: AppBar(
        title: Text('User List'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
        onPressed: _navigateToAddUserScreen,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.teal.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by Name or City',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10.0,
                children: [
                  ChoiceChip(
                    label: Text('All'),
                    selected: _selectedGender == 'All',
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedGender = 'All';
                        _filterUsers();
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text('Male'),
                    selected: _selectedGender == 'Male',
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedGender = 'Male';
                        _filterUsers();
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text('Female'),
                    selected: _selectedGender == 'Female',
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedGender = 'Female';
                        _filterUsers();
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text('Other'),
                    selected: _selectedGender == 'Other',
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedGender = 'Other';
                        _filterUsers();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  User user = _filteredUsers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(8.0),
                      leading: CircleAvatar(
                        backgroundImage: user.profileImagePath != null
                            ? FileImage(File(user.profileImagePath!))
                            : null,
                        child: user.profileImagePath == null
                            ? Icon(Icons.person)
                            : null,
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Text(user.name),
                            SizedBox(width: 5),
                            if (user.isEmailVerified)
                              Icon(Icons.verified, color: Colors.green, size: 20),
                          ],
                        ),
                      ),
                      subtitle: Text(user.city),
                      trailing: Wrap(
                        spacing: 0, // No space between icons
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              user.isFavorite == 1 ? Icons.favorite : Icons.favorite_border,
                              color: user.isFavorite == 1 ? Colors.red : null,
                            ),
                            onPressed: () => _toggleFavorite(user),
                          ),

                          PopupMenuButton<String>(
                            onSelected: (String value) {
                              switch (value) {
                                case 'edit':
                                  _editUser(user);
                                  break;
                                case 'delete':
                                  _confirmDeleteUser(user.id!);
                                  break;
                                case 'share':
                                  _shareUser(user);
                                  break;
                                case 'details':
                                  _navigateToUserDetailScreen(user);
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return {'Edit', 'Delete', 'Share', 'Details'}.map((String choice) {
                                return PopupMenuItem<String>(
                                  value: choice.toLowerCase(),
                                  child: Text(choice),
                                );
                              }).toList();
                            },
                          ),
                        ],
                      ),
                      onTap: () => _navigateToUserDetailScreen(user),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}