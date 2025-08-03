import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loomopro/models/product_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isRecording = false;
  String? _audioPath;
  final _recorder = AudioRecorder();

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final filePath = '${appDocDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: filePath);
        setState(() {
          _isRecording = true;
          _audioPath = null; // Clear previous audio path
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio recorded to: $path')),
        );
        _processAudioForDescription(path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
      );
    }
  }

  Future<void> _processAudioForDescription(String audioFilePath) async {
    setState(() {
      _isLoading = true; // Show loading while processing audio
    });
    try {
      // TODO: Implement actual call to Firebase Cloud Function for Speech-to-Text and Generative AI
      // For now, simulate a delay and set a dummy description
      await Future.delayed(const Duration(seconds: 3));
      _descriptionController.text = 'This is a generated description based on your voice input.';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description generated from voice.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process audio: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a product image.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('No user logged in.');
        }

        // Upload image to Firebase Storage
        final String productId = const Uuid().v4();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('product_images')
            .child(user.uid)
            .child('$productId.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        // Save product details to Firebase Realtime Database
        final product = Product(
          productId: productId,
          artisanId: user.uid,
          name: _productNameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          photoUrl: imageUrl,
          createdAt: DateTime.now(),
          status: 'Live', // Default status
        );

        final productRef =
            FirebaseDatabase.instance.ref('products').child(productId);
        await productRef.set(product.toJson());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully!')),
          );
          Navigator.of(context).pop(); // Go back to dashboard
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                              Text('Tap to select image'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (INR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Product Description',
                  hintText: 'Describe your product...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _isRecording
                  ? ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _startRecording,
                      icon: const Icon(Icons.mic),
                      label: const Text('Record Description'),
                    ),
              if (_audioPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Recorded: ${File(_audioPath!).path.split('/').last}'),
                ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Add Product'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
