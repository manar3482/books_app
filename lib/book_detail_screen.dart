import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'local_storage.dart';

class BookDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await LocalStorage.isFavorite(widget.book['id']);
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await LocalStorage.removeFromFavorites(widget.book['id']);
    } else {
      await LocalStorage.addToFavorites(widget.book);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final volumeInfo = widget.book["volumeInfo"] ?? {};
    final imageLinks = volumeInfo["imageLinks"] ?? {};
    final thumbnail = imageLinks["thumbnail"] ?? imageLinks["smallThumbnail"];
    final title = volumeInfo["title"] ?? "Unknown";
    final authors = volumeInfo["authors"] as List? ?? [];
    final description = volumeInfo["description"] ?? "No description available";
    final publisher = volumeInfo["publisher"] ?? "Unknown";
    final publishedDate = volumeInfo["publishedDate"] ?? "Unknown";
    final pageCount = volumeInfo["pageCount"] ?? 0;
    final categories = volumeInfo["categories"] as List? ?? [];
    final previewLink = volumeInfo["previewLink"];
    final infoLink = volumeInfo["infoLink"];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1C1917),
            flexibleSpace: FlexibleSpaceBar(
              background: thumbnail != null
                  ? Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF5F5F4),
                          child: const Icon(
                            Icons.book,
                            size: 80,
                            color: Color(0xFF92400E),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFFF5F5F4),
                      child: const Icon(
                        Icons.book,
                        size: 80,
                        color: Color(0xFF92400E),
                      ),
                    ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1917)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : const Color(0xFF1C1917),
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1917),
                    ),
                  ),
                  if (authors.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'by ${authors.join(', ')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildInfoChip(Icons.calendar_today, publishedDate),
                        if (pageCount > 0)
                          _buildInfoChip(Icons.layers, '$pageCount pages'),
                        _buildInfoChip(Icons.business, publisher),
                      ],
                    ),
                  ),
                  if (categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cat.toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF78716C),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFE7E5E4)),
                  const SizedBox(height: 16),
                  const Text(
                    'About this book',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1917),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description.replaceAll(RegExp(r'<[^>]*>'), ''),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF44403C),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (previewLink != null || infoLink != null) ...[
                    if (previewLink != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _launchURL(previewLink);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot open preview link'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.menu_book),
                          label: const Text("Read Preview"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF92400E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (infoLink != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await _launchURL(infoLink);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot open link'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text("View on Google Books"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF92400E),
                            side: const BorderSide(color: Color(0xFF92400E)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFA8A29E)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF57534E)),
          ),
        ],
      ),
    );
  }
}
