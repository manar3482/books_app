import 'dart:convert';
import 'package:http/http.dart' as http;
import 'book.dart';

class ApiService {
  static const String baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];

    try {
      // ترميز الـ query وتحضير الـ URL
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$baseUrl?q=$encodedQuery&maxResults=20&orderBy=relevance';

      print('========== Searching for: $query ==========');
      print('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body Length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // طباعة أول 200 حرف من الـ response للتصحيح
        print(
          'Response Preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
        );

        final List<dynamic> items = data['items'] ?? [];

        print('Number of books found: ${items.length}');

        if (items.isEmpty) {
          print('No books found for query: $query');
          return [];
        }

        final books = items
            .map((item) {
              try {
                return Book.fromJson(item);
              } catch (e) {
                print('Error parsing book: $e');
                return null;
              }
            })
            .where((book) => book != null)
            .toList();

        print('Successfully parsed ${books.length} books');
        return books.cast<Book>();
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in searchBooks: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // دالة اختبار للتأكد من أن API يعمل
  Future<bool> testApi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?q=test&maxResults=1'),
      );
      print('Test API Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Test API Failed: $e');
      return false;
    }
  }
}
