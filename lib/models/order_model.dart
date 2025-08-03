
class Order {
  final String orderId;
  final String customerId;
  final String artisanId;
  final String productId;
  final String productName;
  final String productPhotoUrl;
  final double price;
  final String orderStatus; // e.g., 'Pending', 'Paid', 'Shipped', 'Delivered'
  final String paymentId; // From payment gateway
  final DateTime createdAt;
  final String customerName; // Denormalized for easy display
  final String customerPhone; // Denormalized for easy display
  final String? trackingId; // Optional: For delivery tracking

  Order({
    required this.orderId,
    required this.customerId,
    required this.artisanId,
    required this.productId,
    required this.productName,
    required this.productPhotoUrl,
    required this.price,
    required this.orderStatus,
    required this.paymentId,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    this.trackingId,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'artisanId': artisanId,
      'productId': productId,
      'productName': productName,
      'productPhotoUrl': productPhotoUrl,
      'price': price,
      'orderStatus': orderStatus,
      'paymentId': paymentId,
      'createdAt': createdAt.toIso8601String(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'trackingId': trackingId,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      orderId: map['orderId'],
      customerId: map['customerId'],
      artisanId: map['artisanId'],
      productId: map['productId'],
      productName: map['productName'],
      productPhotoUrl: map['productPhotoUrl'],
      price: (map['price'] as num).toDouble(),
      orderStatus: map['orderStatus'],
      paymentId: map['paymentId'],
      createdAt: DateTime.parse(map['createdAt']),
      customerName: map['customerName'] ?? 'N/A', // For backward compatibility
      customerPhone: map['customerPhone'] ?? 'N/A', // For backward compatibility
      trackingId: map['trackingId'],
    );
  }
}
