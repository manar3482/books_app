import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'local_storage.dart';
import 'book_detail_screen.dart';
import 'firebase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _books = [];
  List<dynamic> _customBooks = [];
  bool _isLoading = false;
  bool _isGridView = true;
  String _currentQuery = '';
  String? _errorMessage;
  final String apiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? '';
  final List<String> _suggestions = [
    "The Hobbit",
    "Dune",
    "Jane Austen",
    "Atomic Habits",
    "Harry Potter",
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomBooks();
  }

  Future<void> _loadCustomBooks() async {
    final customBooks = await LocalStorage.getCustomBooks();
    setState(() {
      _customBooks = customBooks;
    });
  }

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentQuery = query;
      _errorMessage = null;
    });

    try {
      List<Map<String, dynamic>> allBooks = [];

      // 1️⃣ جلب من Google Books API
      final url = Uri.parse(
        "https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=20&key=$apiKey",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data["items"] ?? [];

        // إضافة كتب API
        for (var item in items) {
          allBooks.add(item as Map<String, dynamic>);
        }
      }

      // 2️⃣ جلب من Firebase
      try {
        final firebaseBooks = await FirebaseService.getFirebaseBooks();

        // فلترة Firebase حسب البحث
        final filteredFirebaseBooks = firebaseBooks.where((book) {
          return book.title.toLowerCase().contains(query.toLowerCase()) ||
              book.author.toLowerCase().contains(query.toLowerCase());
        }).toList();

        // تحويل Firebase إلى نفس تنسيق API
        for (var book in filteredFirebaseBooks) {
          allBooks.add({
            "id": book.id,
            "volumeInfo": {
              "title": book.title,
              "authors": [book.author],
              "description": book.description,
              "publisher": book.publisher,
              "pageCount": book.pageCount,
              "imageLinks": {"thumbnail": book.imageUrl},
            },
          });
        }
      } catch (e) {
        print('Firebase error: $e');
      }

      // 3️⃣ إضافة المفضلة
      final favorites = await LocalStorage.getFavoritesBooks();
      for (var i = 0; i < allBooks.length; i++) {
        final bookId = allBooks[i]["id"];
        allBooks[i]["isFavorite"] = favorites.any(
          (book) => book['id'] == bookId,
        );
      }

      setState(() {
        _books = allBooks;
        _isLoading = false;
      });

      if (allBooks.isEmpty && mounted) {
        setState(() {
          _errorMessage = "No books found";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error. Please check your internet.";
        _isLoading = false;
      });
    }
  }

  void _searchSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _searchBooks();
  }

  Future<void> _toggleFavorite(Map<String, dynamic> book, int index) async {
    final isFavorite = book["isFavorite"] ?? false;

    if (isFavorite) {
      await LocalStorage.removeFromFavorites(book["id"]);
    } else {
      await LocalStorage.addToFavorites(book);
    }

    setState(() {
      _books[index]["isFavorite"] = !isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: const Color(0xFFF7F6F2),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              // Logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E9B9),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  size: 45,
                  color: Color(0xFF9A4D00),
                ),
              ),

              const SizedBox(height: 25),

              // Title
              const Text(
                "BookFinder",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B1B),
                  fontFamily: 'Serif',
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              const Text(
                "Discover your next great read",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 45),

              _buildSearchBar(),

              const SizedBox(height: 45),

              _buildSuggestions(),

              const SizedBox(height: 30),

              if (_books.isNotEmpty) _buildViewToggle(),

              _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFFA8A29E)),

          const SizedBox(width: 12),

          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search by title, author, or ISBN...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Color(0xFFA8A29E)),
              ),
              onSubmitted: (_) => _searchBooks(),
            ),
          ),

          ElevatedButton(
            onPressed: _searchBooks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD6D3D1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    "Search",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 10,
      children: [
        const Text(
          'Try searching:',
          style: TextStyle(color: Colors.grey, fontSize: 17),
        ),

        ..._suggestions.map(
          (suggestion) => GestureDetector(
            onTap: () => _searchSuggestion(suggestion),
            child: Text(
              suggestion,
              style: const TextStyle(
                color: Color(0xFF78716C),
                fontSize: 17,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_list : Icons.grid_view,
            color: const Color(0xFF92400E),
          ),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final width = MediaQuery.of(context).size.width;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF92400E)),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF78716C)),
            ),
          ],
        ),
      );
    }
    if (_books.isEmpty && _currentQuery.isNotEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: Color(0xFFD6D3D1)),
            SizedBox(height: 16),
            Text(
              "No books found",
              style: TextStyle(color: Color(0xFF78716C), fontSize: 16),
            ),
          ],
        ),
      );
    }
    if (_books.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isGridView) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: width > 600 ? 4 : 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _books.length,
        itemBuilder: (context, index) => _buildGridCard(_books[index], index),
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _books.length,
        itemBuilder: (context, index) => _buildListCard(_books[index], index),
      );
    }
  }

  Widget _buildGridCard(Map<String, dynamic> book, int index) {
    final volumeInfo = book["volumeInfo"] ?? {};
    final isFavorite = book["isFavorite"] ?? false;
    final imageLinks = volumeInfo["imageLinks"] ?? {};
    final thumbnail = imageLinks["thumbnail"] ?? imageLinks["smallThumbnail"];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: thumbnail != null
                    ? Image.network(
                        thumbnail,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF5F5F4),
                            child: const Icon(
                              Icons.book,
                              size: 50,
                              color: Color(0xFF92400E),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFFF5F5F4),
                        child: const Icon(
                          Icons.book,
                          size: 50,
                          color: Color(0xFF92400E),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    volumeInfo["title"] ?? "Unknown",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1917),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (volumeInfo["authors"] as List?)?.join(", ") ?? "Unknown",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF78716C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _toggleFavorite(book, index),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : const Color(0xFFA8A29E),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> book, int index) {
    final volumeInfo = book["volumeInfo"] ?? {};
    final isFavorite = book["isFavorite"] ?? false;
    final imageLinks = volumeInfo["imageLinks"] ?? {};
    final thumbnail = imageLinks["thumbnail"] ?? imageLinks["smallThumbnail"];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: thumbnail != null
                  ? Image.network(
                      thumbnail,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 120,
                          color: const Color(0xFFF5F5F4),
                          child: const Icon(
                            Icons.book,
                            color: Color(0xFF92400E),
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 120,
                      color: const Color(0xFFF5F5F4),
                      child: const Icon(Icons.book, color: Color(0xFF92400E)),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volumeInfo["title"] ?? "Unknown",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1917),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (volumeInfo["authors"] as List?)?.join(", ") ?? "Unknown",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78716C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      volumeInfo["description"] ?? "No description",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA8A29E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _toggleFavorite(book, index),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? Colors.red
                            : const Color(0xFFA8A29E),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
