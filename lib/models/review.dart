class Review {
  final String id;
  final String restaurantId;
  final String? reservationId;
  final String userId;
  final String userName;
  final int stars; // 1..5
  final String text;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.restaurantId,
    required this.reservationId,
    required this.userId,
    required this.userName,
    required this.stars,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'reservationId': reservationId,
        'userId': userId,
        'userName': userName,
        'stars': stars,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      reservationId: json['reservationId'] as String?,
      userId: json['userId'] as String,
      userName: (json['userName'] as String?) ?? '',
      stars: json['stars'] as int,
      text: (json['text'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
