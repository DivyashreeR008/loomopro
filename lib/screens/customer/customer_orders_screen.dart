
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/models/order_model.dart';
import 'package:loomopro/screens/customer/add_review_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  late final Query _ordersQuery;

  @override
  void initState() {
    super.initState();
    final customerId = FirebaseAuth.instance.currentUser!.uid;
    _ordersQuery = FirebaseDatabase.instance
        .ref('orders')
        .orderByChild('customerId')
        .equalTo(customerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _ordersQuery.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('You have not placed any orders yet.'),
            );
          }

          final ordersMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final orders = ordersMap.entries.map((entry) {
            // The key is the orderId, we need to add it to the map before parsing
            final orderData = Map<String, dynamic>.from(entry.value);
            orderData['orderId'] = entry.key;
            return Order.fromMap(orderData);
          }).toList();
          
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // For simplicity, we assume 'Paid' status means delivered for now.
              // In a real app, you'd have a 'Delivered' status.
              final bool canReview = order.orderStatus == 'Paid';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Image.network(order.productPhotoUrl, width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(order.productName),
                      subtitle: Text('Ordered on: ${order.createdAt.toLocal().toString().substring(0, 10)}'),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Chip(
                            label: Text(order.orderStatus),
                            backgroundColor: _getStatusColor(order.orderStatus),
                          ),
                          if (order.trackingId != null && order.trackingId!.isNotEmpty)
                            Text('Tracking ID: ${order.trackingId!}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    if (canReview)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => AddReviewScreen(order: order),
                              ));
                            },
                            child: const Text('Write a Review'),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.blue[100]!;
      case 'Pending Cash Transfer':
        return Colors.orange[100]!;
      case 'Shipped':
        return Colors.purple[100]!;
      case 'Delivered':
        return Colors.green[100]!;
      case 'Reviewed':
        return Colors.green[200]!;
      default:
        return Colors.grey[200]!;
    }
  }
}
