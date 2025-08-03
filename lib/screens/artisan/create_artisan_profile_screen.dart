
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/models/artisan_model.dart';
import 'package:loomopro/screens/artisan/artisan_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateArtisanProfileScreen extends StatefulWidget {
  const CreateArtisanProfileScreen({super.key});

  @override
  State<CreateArtisanProfileScreen> createState() =>
      _CreateArtisanProfileScreenState();
}

class _CreateArtisanProfileScreenState
    extends State<CreateArtisanProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _storyController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception("No user logged in.");
        }

        final artisan = Artisan(
          uid: user.uid,
          name: _nameController.text.trim(),
          story: _storyController.text.trim(),
          location: _locationController.text.trim(),
        );

        DatabaseReference artisanRef =
            FirebaseDatabase.instance.ref('artisans/${user.uid}');
        await artisanRef.set(artisan.toJson());

        // Cache the fact that the profile is created
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_artisan_profile', true);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ArtisanDashboardScreen(),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create profile: $e')),
        );
      } finally {
        if(mounted) {
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
        title: const Text('Create Your Artisan Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _storyController,
                decoration: const InputDecoration(
                  labelText: 'Your Story',
                  hintText: 'Tell us a little about yourself and your craft.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please share your story';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Your Location (City, State)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Create Profile'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
