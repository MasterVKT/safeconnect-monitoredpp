// Simple User model for the monitored app
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String userType;
  final bool isEmailVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.userType,
    required this.isEmailVerified,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle fields that may not be present in pairing response
    // The pairing endpoint returns: first_name, last_name, user_type but not
    // is_email_verified and created_at
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'],
      userType: json['user_type'] ?? 'UNKNOWN',
      // Default to true for pairing since the user has already authenticated
      isEmailVerified: json['is_email_verified'] ?? true,
      // Use current time or parsed time - default to now if not provided
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'user_type': userType,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
