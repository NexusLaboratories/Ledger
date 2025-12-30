class Tag {
  final String id;
  final String? userId;
  final String? parentTagId;
  final String name;
  final String? description;
  final int? color;
  final String? iconId;

  Tag({
    required this.id,
    this.userId,
    this.parentTagId,
    required this.name,
    this.description,
    this.color,
    this.iconId,
  });

  Map<String, dynamic> toMap() => {
    'tag_id': id,
    'user_id': userId,
    'parent_tag_id': parentTagId,
    'tag_name': name,
    'tag_description': description,
    'tag_color': color,
    'tag_icon': iconId,
  };

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['tag_id'] as String,
      userId: map['user_id'] as String?,
      parentTagId: map['parent_tag_id'] as String?,
      name: map['tag_name'] as String,
      description: map['tag_description'] as String?,
      color: map['tag_color'] as int?,
      iconId: map['tag_icon'] as String?,
    );
  }
}
