

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? profilePicUrl;
  final String createdBy;
  final String? adminId;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.profilePicUrl,
    required this.createdBy,
    this.adminId,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return GroupModel(
      id: id ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown Group',
      description: json['subtitle'] ?? json['description'],
      // Support both old 'color' field and new 'profile_pic_url'
      profilePicUrl: json['profile_pic_url'] ?? json['color'],
      createdBy: json['created_by'] ?? '',
      adminId: json['admin_id'],
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : (json['created_at'].runtimeType.toString() == 'Timestamp'
              ? (json['created_at'] as dynamic).toDate()
              : DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtitle': description,
      'profile_pic_url': profilePicUrl,
      'created_by': createdBy,
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? profilePicUrl,
    String? createdBy,
    String? adminId,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      createdBy: createdBy ?? this.createdBy,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
