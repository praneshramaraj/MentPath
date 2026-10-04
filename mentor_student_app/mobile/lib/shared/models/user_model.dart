class User {
  final String id;
  final String email;
  final String fullName;
  final String role; // student, mentor, hod, admin
  final bool isActive;
  final bool isProfileComplete;
  final String? phoneNumber;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.isProfileComplete,
    this.phoneNumber,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'student',
      isActive: json['is_active'] ?? true,
      isProfileComplete: json['is_profile_complete'] ?? false,
      phoneNumber: json['phone_number'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'is_profile_complete': isProfileComplete,
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TokenData {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final User user;

  const TokenData({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      expiresIn: json['expires_in'] ?? 3600,
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}
