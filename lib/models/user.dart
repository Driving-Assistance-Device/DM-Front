class User {
  final int userId;
  final String email;
  final String name;
  final String? password;
  final String? refreshToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.userId,
    required this.email,
    required this.name,
    this.password,
    this.refreshToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return DateTime.fromMillisecondsSinceEpoch(0); 
      if (date is String) return DateTime.tryParse(date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return User(
      userId: json['userId'] ?? json['user_id'],
      email: json['email'],
      name: json['name'],
      password: json['password'],
      refreshToken: json['refreshToken'],
      createdAt: parseDate(json['createdAt'] ?? json['created_at'])!,
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at'])!,
    );
  }

}