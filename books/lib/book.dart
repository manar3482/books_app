class Book {
  final String id;
  final String title;
  final String? subtitle;
  final List<String>? authors;
  final String? description;
  final String? thumbnail;
  final String? publishedDate;
  final int? pageCount;
  final String? publisher;
  final String? previewLink;
  final String? infoLink;
  bool isFavorite;

  Book({
    required this.id,
    required this.title,
    this.subtitle,
    this.authors,
    this.description,
    this.thumbnail,
    this.publishedDate,
    this.pageCount,
    this.publisher,
    this.previewLink,
    this.infoLink,
    this.isFavorite = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};
    
    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'No Title',
      subtitle: volumeInfo['subtitle'],
      authors: volumeInfo['authors'] != null 
          ? List<String>.from(volumeInfo['authors']) 
          : null,
      description: volumeInfo['description'],
      thumbnail: imageLinks['thumbnail'],
      publishedDate: volumeInfo['publishedDate'],
      pageCount: volumeInfo['pageCount'],
      publisher: volumeInfo['publisher'],
      previewLink: volumeInfo['previewLink'],
      infoLink: volumeInfo['infoLink'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'authors': authors,
      'description': description,
      'thumbnail': thumbnail,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'publisher': publisher,
      'previewLink': previewLink,
      'infoLink': infoLink,
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<String>? authors,
    String? description,
    String? thumbnail,
    String? publishedDate,
    int? pageCount,
    String? publisher,
    String? previewLink,
    String? infoLink,
    bool? isFavorite,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      authors: authors ?? this.authors,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      publishedDate: publishedDate ?? this.publishedDate,
      pageCount: pageCount ?? this.pageCount,
      publisher: publisher ?? this.publisher,
      previewLink: previewLink ?? this.previewLink,
      infoLink: infoLink ?? this.infoLink,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}