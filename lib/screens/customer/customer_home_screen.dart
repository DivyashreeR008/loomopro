
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/models/product_model.dart';
import 'package:loomopro/screens/customer/customer_orders_screen.dart';
import 'package:loomopro/screens/shared/product_detail_screen.dart';
import 'package:loomopro/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  // This query is more efficient as it filters on the server.
  final Query _productsRef = FirebaseDatabase.instance
      .ref('products')
      .orderByChild('status')
      .equalTo('Live'); // In production, just use 'Live'

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await FirebaseAuth.instance.signOut();
    // Clear cached data on sign out
    await prefs.remove('user_role');
    await prefs.remove('has_artisan_profile');
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            onPressed: () {
               Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CustomerOrdersScreen(),
              ));
            },
            tooltip: 'My Orders',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _productsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('''No products available right now.
 Please check back later!'''),
            );
          }

          final productsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final products = productsMap.entries.map((entry) {
            return Product.fromMap(Map<String, dynamic>.from(entry.value));
          }).toList();
          
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (products.isEmpty) {
             return const Center(
              child: Text('No products available right now.\n Please check back later!'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(product: product),
                  ));
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Hero(
                          tag: 'product-image-${product.productId}',
                          child: Image.network(
                            product.photoUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '\u20B9${product.price.toStringAsFixed(2)}',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
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
}
