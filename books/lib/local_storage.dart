import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user.dart';

class LocalStorage {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';
  static const String _favoritesKey = 'favorites_books';
static const String _customBooksKey = 'custom_books';

  static Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersString = prefs.getString(_usersKey);
    
    if (usersString == null) {
      final defaultUsers = [
        User(id: '1', name: 'Admin', email: 'admin@bookfinder.com', password: 'admin123', role: 'admin'),
        User(id: '2', name: 'John Doe', email: 'john@example.com', password: 'john123', role: 'user'),
        User(id: '3', name: 'Jane Smith', email: 'jane@example.com', password: 'jane123', role: 'user'),
      ];
      await saveUsers(defaultUsers);
      return defaultUsers;
    }
    
    List<dynamic> usersList = json.decode(usersString);
    return usersList.map((user) => User.fromMap(user)).toList();
  }

  static Future<void> saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersList = users.map((user) => user.toMap()).toList();
    await prefs.setString(_usersKey, json.encode(usersList));
  }

  static Future<void> addUser(User user) async {
    final users = await getUsers();
    users.add(user);
    await saveUsers(users);
  }

  static Future<void> updateUser(User updatedUser) async {
    final users = await getUsers();
    final index = users.indexWhere((user) => user.id == updatedUser.id);
    if (index != -1) {
      users[index] = updatedUser;
      await saveUsers(users);
    }
  }

  static Future<void> deleteUser(String userId) async {
    final users = await getUsers();
    users.removeWhere((user) => user.id == userId);
    await saveUsers(users);
  }

  static Future<void> setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toMap()));
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userString = prefs.getString(_currentUserKey);
    if (userString != null) {
      return User.fromMap(json.decode(userString));
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Favorites - Save full book objects
  static Future<List<Map<String, dynamic>>> getFavoritesBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesString = prefs.getString(_favoritesKey);
    if (favoritesString == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(favoritesString));
  }

  static Future<void> addToFavorites(Map<String, dynamic> book) async {
    final favorites = await getFavoritesBooks();
    final exists = favorites.any((fav) => fav['id'] == book['id']);
    if (!exists) {
      favorites.add(book);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favoritesKey, json.encode(favorites));
    }
  }

  static Future<void> removeFromFavorites(String bookId) async {
    final favorites = await getFavoritesBooks();
    favorites.removeWhere((book) => book['id'] == bookId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey, json.encode(favorites));
  }

  static Future<bool> isFavorite(String bookId) async {
    final favorites = await getFavoritesBooks();
    return favorites.any((book) => book['id'] == bookId);
  }
  // ================= CUSTOM BOOKS =================

static Future<List<Map<String, dynamic>>> getCustomBooks() async {
  final prefs = await SharedPreferences.getInstance();
  final String? booksString = prefs.getString(_customBooksKey);

  if (booksString == null) return [];

  return List<Map<String, dynamic>>.from(
    json.decode(booksString),
  );
}

static Future<void> addCustomBook(
  Map<String, dynamic> book,
) async {
  final books = await getCustomBooks();

  books.add(book);

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    _customBooksKey,
    json.encode(books),
  );
}

static Future<void> deleteCustomBook(String id) async {
  final books = await getCustomBooks();

  books.removeWhere((book) => book['id'] == id);

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    _customBooksKey,
    json.encode(books),
  );
}
}