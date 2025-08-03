
import 'package:firebase_database/firebase_database.dart';

class Product {
  final String productId;
  final String artisanId;
  final String name;
  final String description;
  final String photoUrl;
  final String? audioDescriptionUrl;
  final double price;
  final String status; // e.g., 'Pending Approval', 'Live', 'Sold Out'
  final DateTime createdAt;

  Product({
    required this.productId,
    required this.artisanId,
    required this.name,
    required this.description,
    required this.photoUrl,
    this.audioDescriptionUrl,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'artisanId': artisanId,
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'audioDescriptionUrl': audioDescriptionUrl,
      'price': price,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['productId'],
      artisanId: map['artisanId'],
      name: map['name'],
      description: map['description'],
      photoUrl: map['photoUrl'],
      audioDescriptionUrl: map['audioDescriptionUrl'],
      price: (map['price'] as num).toDouble(),
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Helper to get a Product from a Firebase snapshot
  factory Product.fromSnapshot(DataSnapshot snapshot) {
    final map = snapshot.value as Map<String, dynamic>;
    return Product.fromMap(map);
  }
}
