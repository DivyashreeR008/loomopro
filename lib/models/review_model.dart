
class Review {
  final String reviewId;
  final String productId;
  final String customerId;
  final String customerName;
  final double rating; // 1.0 to 5.0
  final String comment;
  final DateTime createdAt;

  Review({
    required this.reviewId,
    required this.productId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'productId': productId,
      'customerId': customerId,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      reviewId: map['reviewId'],
      productId: map['productId'],
      customerId: map['customerId'],
      customerName: map['customerName'],
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
