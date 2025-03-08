import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import 'user_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _dbHelper = DatabaseHelper();
  List<User> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
    });
    List<User> users = await _dbHelper.getFavoriteUsers();
    setState(() {
      _favorites = users;
      _isLoading = false;
    });
  }

  void _removeFromFavorites(User user) async {
    await _dbHelper.toggleFavorite(user.id!);
    setState(() {
      user.isFavorite = 0;
      _favorites.remove(user);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Removed from favorites',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[700],
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _navigateToUserDetailScreen(User user) async {
    bool? userEdited = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserDetailScreen(user: user)),
    );
    if (userEdited == true) {
      _fetchFavorites(); // Refresh favorites list
    }
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
                    color: Color(0xFFFFA726).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.copy, color: Color(0xFFFFA726)),
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
                  // Assuming you have the share_plus package imported
                  // Share.share(shareText);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'My Favorites',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? Center(
        child: SpinKitDoubleBounce(
          color: Color(0xFFFFA726),
          size: 50.0,
        ),
      )
          : _favorites.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          User user = _favorites[index];
          return _buildFavoriteCard(user);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add profiles to your favorites list',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(User user) {
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
                      Icons.favorite,
                      color: Color(0xFFFFA726),
                    ),
                    onPressed: () => _removeFromFavorites(user),
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
                  icon: Icons.remove_circle_outline,
                  color: Colors.redAccent,
                  label: 'Remove',
                  onTap: () => _removeFromFavorites(user),
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
                  icon: Icons.visibility,
                  color: Color(0xFF4ECDC4),
                  label: 'View',
                  onTap: () => _navigateToUserDetailScreen(user),
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