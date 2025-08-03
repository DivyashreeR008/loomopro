
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/models/order_model.dart';
import 'package:loomopro/models/product_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class OrderService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Razorpay _razorpay = Razorpay();

  // WARNING: Do not ship your app with this key hardcoded.
  // This is a placeholder for development.
  // For production, use a secure method like a backend server or environment variables.
  static const _razorpayKey = 'YOUR_RAZORPAY_KEY_HERE';

  OrderService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  // This function will be called from the UI to start the payment process
  void createOrderAndPay(BuildContext context, Product product) {
    if (_razorpayKey == 'YOUR_RAZORPAY_KEY_HERE') {
       Fluttertoast.showToast(
        msg: "Payment gateway is not configured.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "You must be logged in to purchase.");
      return;
    }

    final options = {
      'key': _razorpayKey,
      'amount': (product.price * 100).toInt(), // Amount in paise
      'name': 'LoomoPro',
      'description': product.name,
      'prefill': {
        'contact': user.phoneNumber ?? '',
        'email': user.email ?? ''
      },
      // We pass the product and user info in the notes
      'notes': {
        'productId': product.productId,
        'artisanId': product.artisanId,
        'customerId': user.uid,
        'customerName': user.displayName ?? 'Anonymous',
        'customerPhone': user.phoneNumber ?? 'N/A',
        'productName': product.name,
        'productPhotoUrl': product.photoUrl,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Fluttertoast.showToast(
        msg: "SUCCESS: ${response.paymentId!}", toastLength: Toast.LENGTH_SHORT);
    
    // The metadata we passed comes back in the response.notes
    final notes = response.data!['notes'] as Map<String, dynamic>;

    // Create the order in Firebase Database
    final orderRef = _db.child('orders').push();
    final newOrder = Order(
      orderId: orderRef.key!,
      customerId: notes['customerId'],
      artisanId: notes['artisanId'],
      productId: notes['productId'],
      productName: notes['productName'],
      productPhotoUrl: notes['productPhotoUrl'],
      price: (response.data!['amount'] / 100).toDouble(),
      orderStatus: 'Paid',
      paymentId: response.paymentId!,
      createdAt: DateTime.now(),
      customerName: notes['customerName'],
      customerPhone: notes['customerPhone'],
    );

    orderRef.set(newOrder.toJson());

    // Also, update the product status to 'Sold Out'
    _db.child('products/${newOrder.productId}/status').set('Sold Out');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
        msg: "ERROR: ${response.code} - ${response.message!}",
        toastLength: Toast.LENGTH_LONG);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
        msg: "EXTERNAL WALLET: ${response.walletName!}",
        toastLength: Toast.LENGTH_SHORT);
  }

  // New method for cash transfer option
  Future<void> createOrderAndCashTransfer(BuildContext context, Product product) async {
    final user = _auth.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "You must be logged in to purchase.");
      return;
    }

    // Placeholder for app's bank details
    const String bankDetails = "Bank Name: ABC Bank\nAccount Number: 1234567890\nIFSC Code: ABC0001234";

    try {
      final orderRef = _db.child('orders').push();
      final newOrder = Order(
        orderId: orderRef.key!,
        customerId: user.uid,
        artisanId: product.artisanId,
        productId: product.productId,
        productName: product.name,
        productPhotoUrl: product.photoUrl,
        price: product.price,
        orderStatus: 'Pending Cash Transfer',
        paymentId: 'N/A', // No direct payment ID for cash transfer
        createdAt: DateTime.now(),
        customerName: user.displayName ?? 'Anonymous',
        customerPhone: user.phoneNumber ?? 'N/A',
      );

      await orderRef.set(newOrder.toJson());

      // Show instructions to the user
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Cash Transfer Instructions'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text('Please transfer the amount to the following account:'),
                    const SizedBox(height: 10),
                    Text(bankDetails, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text('Once transferred, please contact us with your order ID for confirmation.'),
                    const SizedBox(height: 10),
                    Text('Your Order ID: ${newOrder.orderId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }

      Fluttertoast.showToast(msg: "Order placed for cash transfer. Please follow instructions.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to place order for cash transfer: $e");
    }
  }
}
