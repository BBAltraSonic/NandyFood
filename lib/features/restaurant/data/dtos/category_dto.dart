class RestaurantCategoryDTO {
  final String id;
  final String name;
  final String? iconUrl;

  const RestaurantCategoryDTO({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory RestaurantCategoryDTO.fromRow(Map<String, dynamic> row) {
    final name = (row['name'] ?? row['label'] ?? '').toString();
    return RestaurantCategoryDTO(
      id: (row['id'] ?? name.toLowerCase()).toString(),
      name: name,
      iconUrl: row['icon_url'] as String?,
    );
  }
}

