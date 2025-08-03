
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/models/artisan_model.dart';
import 'package:loomopro/models/product_model.dart';
import 'package:loomopro/models/review_model.dart';
import 'package:loomopro/screens/shared/chat_screen.dart';
import 'package:loomopro/services/chat_service.dart';
import 'package:loomopro/services/cache_service.dart';
import 'package:loomopro/services/order_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ChatService _chatService = ChatService();
  final CacheService _cacheService = CacheService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final OrderService _orderService;
  
  Artisan? _artisan;
  bool _isPlayingAudio = false;
  final TextEditingController _reviewController = TextEditingController();
  int _currentRating = 0;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _fetchArtisan();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _orderService.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchArtisan() async {
    final cachedArtisan = _cacheService.getArtisan(widget.product.artisanId);
    if (cachedArtisan != null) {
      if (mounted) setState(() => _artisan = cachedArtisan);
      return;
    }
    try {
      final ref = FirebaseDatabase.instance.ref('artisans/${widget.product.artisanId}');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        final fetchedArtisan = Artisan.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
        if (mounted) {
          setState(() => _artisan = fetchedArtisan);
          _cacheService.setArtisan(fetchedArtisan);
        }
      }
    } catch (e) {
      print('Error fetching artisan: $e');
    }
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review.')),
      );
      return;
    }

    if (_reviewController.text.isEmpty || _currentRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment and select a rating.')),
      );
      return;
    }

    try {
      final reviewsRef = FirebaseDatabase.instance.ref('reviews');
      final newReviewRef = reviewsRef.push();
      final reviewId = newReviewRef.key;

      // Fetch customer name from users node
      final customerRef = FirebaseDatabase.instance.ref('users').child(user.uid);
      final customerSnapshot = await customerRef.get();
      String customerName = 'Anonymous';
      if (customerSnapshot.exists) {
        customerName = customerSnapshot.child('name').value as String? ?? 'Anonymous';
      }

      final newReview = Review(
        reviewId: reviewId!,
        productId: widget.product.productId,
        customerId: user.uid,
        customerName: customerName,
        rating: _currentRating.toDouble(),
        comment: _reviewController.text.trim(),
        createdAt: DateTime.now(),
      );

      await newReviewRef.set(newReview.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        _reviewController.clear();
        setState(() {
          _currentRating = 0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }

  void _navigateToChat() async {
    if (_artisan == null) return;
    final chatRoomId = await _chatService.createOrGetChatRoom(
      widget.product.artisanId,
      widget.product.productId,
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChatScreen(
        chatRoomId: chatRoomId,
        recipientName: _artisan!.name,
      ),
    ));
  }

  Future<void> _playAudio() async {
    if (widget.product.audioDescriptionUrl != null) {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(widget.product.audioDescriptionUrl!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSoldOut = widget.product.status == 'Sold Out';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-image-${widget.product.productId}',
              child: Image.network(
                widget.product.photoUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\u20B9${widget.product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isSoldOut)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'SOLD OUT',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildArtisanInfo(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildReviewsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isSoldOut ? null : _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _navigateToChat,
            child: const Text('Contact Artisan'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _orderService.createOrderAndPay(context, widget.product),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Buy Now (Online)'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _orderService.createOrderAndCashTransfer(context, widget.product),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pay via Cash Transfer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'About this product',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.product.audioDescriptionUrl != null)
              IconButton(
                icon: Icon(_isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_fill_rounded),
                tooltip: 'Hear from the Artisan',
                onPressed: _playAudio,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.description,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildArtisanInfo() {
    if (_artisan == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final artisan = _artisan!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sold by',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: artisan.profilePictureUrl != null
                ? NetworkImage(artisan.profilePictureUrl!)
                : null,
            child: artisan.profilePictureUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(artisan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(artisan.location),
          trailing: ElevatedButton(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Viewing ${artisan.name}\'s profile')),
              );
            },
            child: const Text('View Profile'),
          ),
        ),
         const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            artisan.story,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final reviewsQuery = FirebaseDatabase.instance
        .ref('reviews')
        .orderByChild('productId')
        .equalTo(widget.product.productId);

    return StreamBuilder<DatabaseEvent>(
      stream: reviewsQuery.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No reviews yet. Be the first!'));
        }

        final reviewsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final reviews = reviewsMap.entries.map((e) {
          return Review.fromMap(Map<String, dynamic>.from(e.value));
        }).toList();

        double averageRating = 0;
        if (reviews.isNotEmpty) {
          averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Reviews (${reviews.length})', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 16),
                const Icon(Icons.star, color: Colors.amber),
                Text(averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildReviewInput(), // Add review input section
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return ListTile(
                  title: Row(
                    children: [
                      Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ...List.generate(5, (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      )),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(review.comment),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Write a Review', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _currentRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () {
                setState(() {
                  _currentRating = index + 1;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          decoration: const InputDecoration(
            hintText: 'Share your thoughts...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _submitReview,
          child: const Text('Submit Review'),
        ),
      ],
    );
  }
}
