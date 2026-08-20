import 'package:flutter/material.dart';
import 'local_storage.dart';
import 'book_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _favoriteBooks = [];
  bool _isLoading = true;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    _favoriteBooks = await LocalStorage.getFavoritesBooks();
    setState(() => _isLoading = false);
  }

  Future<void> _removeFromFavorites(Map<String, dynamic> book) async {
    await LocalStorage.removeFromFavorites(book['id']);
    await _loadFavorites();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${book['volumeInfo']['title']} removed from favorites'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEADFBF),
        elevation: 0,
        // شيل الـ leading عشان ميبقاش فيه سهم رجوع
        // لأن الصفحة دي جزء من Bottom Navigation Bar
        title: const Text(
          "My Favorites",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4F2A),
          ),
        ),
        actions: [
          if (_favoriteBooks.isNotEmpty)
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteBooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        "No favorites yet",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Tap the heart icon on any book to add it here",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _favoriteBooks.length,
                      itemBuilder: (context, index) => _buildFavoriteCard(_favoriteBooks[index], index),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _favoriteBooks.length,
                      itemBuilder: (context, index) => _buildFavoriteCard(_favoriteBooks[index], index),
                    ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> book, int index) {
    final volumeInfo = book["volumeInfo"] ?? {};
    final imageLinks = volumeInfo["imageLinks"] ?? {};
    final thumbnail = imageLinks["thumbnail"];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailsScreen(book: book),
          ),
        ).then((_) => _loadFavorites());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFEADFBF),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnail != null
                    ? Image.network(thumbnail, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.book, size: 40, color: Color(0xFF6B4F2A));
                        })
                    : const Icon(Icons.book, size: 40, color: Color(0xFF6B4F2A)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    volumeInfo["title"] ?? "No Title",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E2A28)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    volumeInfo["authors"] != null ? (volumeInfo["authors"] as List).join(", ") : "Unknown Author",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    volumeInfo["description"] != null 
                        ? (volumeInfo["description"].length > 80 
                            ? volumeInfo["description"].substring(0, 80) + "..." 
                            : volumeInfo["description"])
                        : "No description available",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeFromFavorites(book),
            ),
          ],
        ),
      ),
    );
  }
}
