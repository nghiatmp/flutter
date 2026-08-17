import 'dart:convert';

/// Model biểu diễn user trong app.
/// Password chỉ dùng để cache tài khoản demo gần nhất cho màn login tự điền.
class UserModel {
  const UserModel({
    required this.fullName,
    required this.email,
    required this.password,
    required this.gender,
    required this.hobbies,
    required this.birthDate,
    required this.city,
    required this.acceptedTerms,
  });

  final String fullName;
  final String email;
  final String password;
  final String gender;
  final List<String> hobbies;
  final DateTime birthDate;
  final String city;
  final bool acceptedTerms;

  /// Tạo bản sao với vài field thay đổi, dùng sau khi cập nhật hồ sơ thành công.
  UserModel copyWith({
    String? fullName,
    String? gender,
    List<String>? hobbies,
    DateTime? birthDate,
    String? city,
  }) {
    return UserModel(
      fullName: fullName ?? this.fullName,
      email: email,
      password: password,
      gender: gender ?? this.gender,
      hobbies: hobbies ?? this.hobbies,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      acceptedTerms: acceptedTerms,
    );
  }

  /// Chuyển object UserModel thành Map để dễ encode sang JSON.
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'gender': gender,
      'hobbies': hobbies,
      'birthDate': birthDate.toIso8601String(),
      'city': city,
      'acceptedTerms': acceptedTerms,
    };
  }

  /// Tạo UserModel từ Map.
  /// Hàm này dùng khi đọc JSON từ local storage rồi parse ngược lại thành object.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      password: map['password'] as String? ?? '',
      gender: map['gender'] as String? ?? '',
      hobbies: (map['hobbies'] as List<dynamic>? ?? [])
          .map((item) => item as String)
          .toList(),
      birthDate:
          DateTime.tryParse(map['birthDate'] as String? ?? '') ??
          DateTime(2000),
      city: map['city'] as String? ?? '',
      acceptedTerms: map['acceptedTerms'] as bool? ?? false,
    );
  }

  /// Tạo user từ response backend.
  factory UserModel.fromApi(Map<String, dynamic> map, {String password = ''}) {
    return UserModel(
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: password,
      gender: map['gender'] as String? ?? '',
      hobbies: (map['hobbies'] as List<dynamic>? ?? [])
          .map((item) => item as String)
          .toList(),
      birthDate:
          DateTime.tryParse(map['birthDate'] as String? ?? '') ??
          DateTime(2000),
      city: map['city'] as String? ?? '',
      acceptedTerms: map['acceptedTerms'] as bool? ?? false,
    );
  }

  /// Encode user thành JSON string để lưu vào shared_preferences.
  String toJson() => jsonEncode(toMap());

  /// Decode JSON string từ local storage thành UserModel.
  factory UserModel.fromJson(String source) {
    return UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
