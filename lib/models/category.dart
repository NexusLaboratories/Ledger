class Category {
  final String id;
  final String? userId;
  final String? parentCategoryId;
  final String name;
  final String? description;
  final String? iconId;

  Category({
    required this.id,
    this.userId,
    this.parentCategoryId,
    required this.name,
    this.description,
    this.iconId,
  });

  Map<String, dynamic> toMap() => {
    'category_id': id,
    'user_id': userId,
    'parent_category_id': parentCategoryId,
    'category_name': name,
    'category_description': description,
    'category_icon': iconId,
  };

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['category_id'] as String,
      userId: map['user_id'] as String?,
      parentCategoryId: map['parent_category_id'] as String?,
      name: map['category_name'] as String,
      description: map['category_description'] as String?,
      iconId: map['category_icon'] as String?,
    );
  }
}
