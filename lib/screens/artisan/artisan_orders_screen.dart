
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/models/order_model.dart';

class ArtisanOrdersScreen extends StatefulWidget {
  const ArtisanOrdersScreen({super.key});

  @override
  State<ArtisanOrdersScreen> createState() => _ArtisanOrdersScreenState();
}

class _ArtisanOrdersScreenState extends State<ArtisanOrdersScreen> {
  late final Query _ordersQuery;

  @override
  void initState() {
    super.initState();
    final artisanId = FirebaseAuth.instance.currentUser!.uid;
    _ordersQuery = FirebaseDatabase.instance
        .ref('orders')
        .orderByChild('artisanId')
        .equalTo(artisanId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sales'),
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
              child: Text('You have no sales yet.'),
            );
          }

          final ordersMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final orders = ordersMap.entries.map((entry) {
            return Order.fromMap(Map<String, dynamic>.from(entry.value));
          }).toList();
          
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderId.substring(0, 6)}...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Image.network(order.productPhotoUrl, width: 50, height: 50, fit: BoxFit.cover),
                        title: Text(order.productName),
                        subtitle: Text('Price: \u20B9${order.price.toStringAsFixed(2)}'),
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
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer: ${order.customerName}'),
                            Text('Phone: ${order.customerPhone}'),
                          ],
                        ),
                      ),
                    ],
                  ),
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
