class Meal {
  final String name;
  final String category;
  final String area;
  final String imageUrl;

  const Meal({
    required this.name,
    required this.category,
    required this.area,
    required this.imageUrl,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: (json['strMeal'] as String?) ?? 'Без названия',
      category: (json['strCategory'] as String?) ?? '',
      area: (json['strArea'] as String?) ?? '',
      imageUrl: (json['strMealThumb'] as String?) ?? '',
    );
  }
}
