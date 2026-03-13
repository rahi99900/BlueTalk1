

class VoiceRoomModel {
  final String id;
  final String groupId;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;

  const VoiceRoomModel({
    required this.id,
    required this.groupId,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
  });

  factory VoiceRoomModel.fromJson(Map<String, dynamic> json) {
    return VoiceRoomModel(
      id: json['id'],
      groupId: json['group_id'],
      name: json['name'],
      description: json['description'],
      createdBy: json['created_by'],
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
      'group_id': groupId,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
