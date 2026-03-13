class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final DateTime? dob;
  final bool isProfileComplete;
  final bool isOnline;
  final String? fcmToken;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.dob,
    this.isProfileComplete = false,
    this.isOnline = false,
    this.fcmToken,
  });

  bool get isEmpty => id.isEmpty;

  static const empty = UserModel(id: '', email: '');

  UserModel copyWith({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? gender,
    DateTime? dob,
    bool? isProfileComplete,
    bool? isOnline,
    String? fcmToken,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isOnline: isOnline ?? this.isOnline,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      gender: json['gender'] as String?,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      fcmToken: json['fcm_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'is_profile_complete': isProfileComplete,
      'is_online': isOnline,
      'fcm_token': fcmToken,
    };
  }
}
