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
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      name: map['name'],
      email: map['email'],
      mobile: map['mobile'],
      age: int.parse(map['age'].toString()),
      city: map['city'],
      gender: map['gender'],
      password: map['password'],
      isFavorite: int.parse(map['isFavorite'].toString()),
      profileImagePath: map['profileImagePath']?.toString(),
      otp: map['otp']?.toString(),
      otpExpiration: map['otpExpiration'] != null ? int.tryParse(map['otpExpiration'].toString()) : null,
      isEmailVerified: map['isEmailVerified'] == 1,
    );
  }
}