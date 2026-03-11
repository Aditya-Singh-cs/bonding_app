int globalSecondsRemaining = 300;
class Buddy {
  final String id;
  final String name;
  final String bio;
  final String imageUrl;
  final double price;
  final double rating;
  final bool isOnline;
 

  Buddy({
    required this.id,
    required this.name,
    required this.bio,
    required this.imageUrl,
    required this.price,
    required this.rating,
    this.isOnline = true,
  });
}

// Dummy data for testing the UI
final List<Buddy> mockBuddies = [
  Buddy(
    id: '1',
    name: 'Aarav Sharma',
    bio: 'Anime lover and tech enthusiast.',
    imageUrl: 'https://picsum.photos/seed/1/200',
    price: 2.0,
    rating: 4.5,
  ),
  Buddy(
    id: '2',
    name: 'Priya Rai',
    bio: 'Great listener, lets talk about your day.',
    imageUrl: 'https://picsum.photos/seed/2/200',
    price: 4.0,
    rating: 4.9,
  ),
];