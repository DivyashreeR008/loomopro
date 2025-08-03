
import 'package:loomo/screens/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductDetailsScreen extends StatelessWidget {
  final DocumentSnapshot product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final data = product.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(data['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.network(data['imageUrl']),
            const SizedBox(height: 20),
            Text(
              data['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '\₹${data['price']}',
              style: const TextStyle(fontSize: 20, color: Colors.teal),
            ),
            const SizedBox(height: 10),
            Text(data['description']),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final sellerId = data['sellerId'];
                final sellerDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
                final sellerName = sellerDoc.exists && sellerDoc.data() != null
                    ? sellerDoc.data()!['name'] ?? 'Unknown Seller'
                    : 'Unknown Seller';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      sellerId: sellerId,
                      sellerName: sellerName,
                    ),
                  ),
                );
              },
              child: const Text('Contact Seller'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Payment Options'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Simulating online payment...')),
                              );
                              // TODO: Implement actual online payment gateway integration
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Payment successful! Order placed.')),
                              );
                            },
                            child: const Text('Pay Online'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order placed! Money will be collected via post.')),
                              );
                            },
                            child: const Text('Cash via Post'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: const Text('Buy Now'),
            ),
          ],
        ),
      ),
    );
  }
}
