class User {
  int? id;
  String name;
  String email;
  String mobile;
  int age;
  String city;
  String gender;
  String password;
  int isFavorite;
  String? profileImagePath;
  String? otp;
  int? otpExpiration;
  bool isEmailVerified;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.age,
    required this.city,
    required this.gender,
    required this.password,
    this.isFavorite = 0,
    this.profileImagePath,
    this.otp,
    this.otpExpiration,
    this.isEmailVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'age': age,
      'city': city,
      'gender': gender,
      'password': password,
      'isFavorite': isFavorite,
      'profileImagePath': profileImagePath,
      'otp': otp,
      'otpExpiration': otpExpiration,
      'isEmailVerified': isEmailVerified ? 1 : 0,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      mobile: map['mobile'],
      age: map['age'],
      city: map['city'],
      gender: map['gender'],
      password: map['password'],
      isFavorite: map['isFavorite'],
      profileImagePath: map['profileImagePath'],
      otp: map['otp'],
      otpExpiration: map['otpExpiration'],
      isEmailVerified: map['isEmailVerified'] == 1,
    );
  }
}