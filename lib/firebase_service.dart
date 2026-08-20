import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<List<FirebaseBook>> getFirebaseBooks() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FirebaseBook(
          id: data['id'] ?? doc.id,
          title: data['title'] ?? 'No Title',
          author: data['author'] ?? 'Unknown',
          description: data['description'] ?? '',
          publisher: data['publisher'] ?? '',
          pageCount: data['pageCount'] ?? 0,
          imageUrl: data['imageUrl'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error getting firebase books: $e');
      return [];
    }
  }
}

class FirebaseBook {
  final String id;
  final String title;
  final String author;
  final String description;
  final String publisher;
  final int pageCount;
  final String imageUrl;
  
  FirebaseBook({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.publisher,
    required this.pageCount,
    required this.imageUrl,
  });
}