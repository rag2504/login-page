import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static const String apiUrl = "https://66d56529f5859a704265e791.mockapi.io/users";

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<bool> validateUser(String email, String password) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl?email=$email&password=$password'));
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        return usersJson.isNotEmpty;
      } else {
        print("Error validating user: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error validating user: $e");
      return false;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl?email=$email'));
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        if (usersJson.isNotEmpty) {
          return User.fromMap(usersJson.first);
        }
      } else {
        print("Error fetching user by email: ${response.body}");
      }
      return null;
    } catch (e) {
      print("Error fetching user by email: $e");
      return null;
    }
  }

  Future<int> insertUser(User user) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(user.toMap()),
      );
      if (response.statusCode == 201) {
        return 1; // Success indication
      } else {
        print("Error inserting user: ${response.body}");
        return -1; // Error indication
      }
    } catch (e) {
      print("Error inserting user: $e");
      return -1; // Error indication
    }
  }

  Future<int> updateUser(User user) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/${user.id}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(user.toMap()),
      );
      if (response.statusCode == 200) {
        return 1; // Success indication
      } else {
        print("Error updating user: ${response.body}");
        return -1; // Error indication
      }
    } catch (e) {
      print("Error updating user: $e");
      return -1; // Error indication
    }
  }

  Future<int> deleteUser(int id) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/$id'));
      if (response.statusCode == 200) {
        return 1; // Success indication
      } else {
        print("Error deleting user: ${response.body}");
        return -1; // Error indication
      }
    } catch (e) {
      print("Error deleting user: $e");
      return -1; // Error indication
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        return usersJson.map((json) => User.fromMap(json)).toList();
      } else {
        print("Error fetching users: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching users: $e");
      return [];
    }
  }

  Future<List<User>> getFavoriteUsers() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl?isFavorite=1'));
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        return usersJson.map((json) => User.fromMap(json)).toList();
      } else {
        print("Error fetching favorite users: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching favorite users: $e");
      return [];
    }
  }

  Future<void> toggleFavorite(int id) async {
    try {
      final user = await getUserById(id);
      if (user != null) {
        user.isFavorite = user.isFavorite == 1 ? 0 : 1;
        await updateUser(user);
      }
    } catch (e) {
      print("Error toggling favorite: $e");
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/$id'));
      if (response.statusCode == 200) {
        return User.fromMap(jsonDecode(response.body));
      } else {
        print("Error fetching user by ID: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching user by ID: $e");
      return null;
    }
  }

  Future<void> updateOtp(String email, String otp, int expiration) async {
    try {
      final user = await getUserByEmail(email);
      if (user != null) {
        user.otp = otp;
        user.otpExpiration = expiration;
        await updateUser(user);
      }
    } catch (e) {
      print("Error updating OTP: $e");
    }
  }

  Future<void> updateEmailVerificationStatus(String email, bool isVerified) async {
    try {
      final user = await getUserByEmail(email);
      if (user != null) {
        user.isEmailVerified = isVerified;
        await updateUser(user);
      }
    } catch (e) {
      print("Error updating email verification status: $e");
    }
  }

  Future<void> resetPassword(String email, String newPassword) async {
    try {
      final user = await getUserByEmail(email);
      if (user != null) {
        user.password = newPassword;
        user.otp = null;
        user.otpExpiration = null;
        await updateUser(user);
      }
    } catch (e) {
      print("Error resetting password: $e");
    }
  }

  Future<User?> validateOtp(String email, String otp) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl?email=$email&otp=$otp&otpExpiration>${DateTime.now().millisecondsSinceEpoch}'));
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        if (usersJson.isNotEmpty) {
          return User.fromMap(usersJson.first);
        }
      } else {
        print("Error validating OTP: ${response.body}");
      }
      return null;
    } catch (e) {
      print("Error validating OTP: $e");
      return null;
    }
  }
}