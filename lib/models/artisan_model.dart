
class Artisan {
  final String uid;
  final String name;
  final String story;
  final String location;
  final String? profilePictureUrl;

  Artisan({
    required this.uid,
    required this.name,
    required this.story,
    required this.location,
    this.profilePictureUrl,
  });

  // Method to convert an Artisan object to a map for Firebase
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'story': story,
      'location': location,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  // Factory method to create an Artisan object from a map (snapshot)
  factory Artisan.fromMap(Map<String, dynamic> map) {
    return Artisan(
      uid: map['uid'],
      name: map['name'],
      story: map['story'],
      location: map['location'],
      profilePictureUrl: map['profilePictureUrl'],
    );
  }
}
