
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/models/product_model.dart';
import 'package:loomopro/screens/artisan/add_product_screen.dart';
import 'package:loomopro/screens/artisan/artisan_orders_screen.dart';
import 'package:loomopro/screens/welcome_screen.dart';
import 'package:loomopro/services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArtisanDashboardScreen extends StatefulWidget {
  const ArtisanDashboardScreen({super.key});

  @override
  State<ArtisanDashboardScreen> createState() => _ArtisanDashboardScreenState();
}

class _ArtisanDashboardScreenState extends State<ArtisanDashboardScreen> {
  late final DatabaseReference _productsRef;
  final CacheService _cacheService = CacheService();
  Stream<DatabaseEvent> get _productsStream => _productsRef.onValue;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _signOut(context);
      });
      _productsRef = FirebaseDatabase.instance.ref('products'); // Dummy ref
    } else {
      _productsRef = FirebaseDatabase.instance
          .ref('products')
          .orderByChild('artisanId')
          .equalTo(user.uid)
          .ref;
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await FirebaseAuth.instance.signOut();
    
    _cacheService.clear();
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
        title: const Text('My Products'),
        actions: [          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ArtisanOrdersScreen(),
              ));
            },
            tooltip: 'My Sales',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                'You have not added any products yet.\nTap the + button to add your first one!',
                textAlign: TextAlign.center,
              ),
            );
          }

          final productsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final products = productsMap.entries.map((entry) {
            return Product.fromMap(Map<String, dynamic>.from(entry.value));
          }).toList();
          
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Image.network(product.photoUrl, width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(product.name),
                  subtitle: Text('Price: \u20B9${product.price.toStringAsFixed(2)}'),
                  trailing: Chip(
                    label: Text(product.status),
                    backgroundColor: product.status == 'Live' ? Colors.green[100] : 
                                     product.status == 'Sold Out' ? Colors.red[100] : Colors.orange[100],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Product',
      ),
    );
  }
}
