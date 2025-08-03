
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/models/order_model.dart';
import 'package:loomopro/models/review_model.dart';

class AddReviewScreen extends StatefulWidget {
  final Order order;
  const AddReviewScreen({super.key, required this.order});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 0.0;
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final reviewRef = FirebaseDatabase.instance.ref('reviews').push();

      final newReview = Review(
        reviewId: reviewRef.key!,
        productId: widget.order.productId,
        customerId: user.uid,
        customerName: user.displayName ?? 'Anonymous',
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await reviewRef.set(newReview.toJson());

      // Mark the order as reviewed to prevent multiple reviews
      await FirebaseDatabase.instance
          .ref('orders/${widget.order.orderId}/orderStatus')
          .set('Reviewed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your review!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: Image.network(widget.order.productPhotoUrl),
              title: Text(widget.order.productName),
              subtitle: const Text('How was your product?'),
            ),
            const Divider(height: 32),
            const Text(
              'Your Rating',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    _rating > index ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Your Review',
                hintText: 'Share your thoughts about the product...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Submit Review'),
                  ),
          ],
        ),
      ),
    );
  }
}
