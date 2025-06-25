class EducationArticle {
  final String id;
  final String title;
  final String content;
  final String category;
  final String imageUrl;
  final String url;
  final bool isOffline;
  final DateTime? publishedAt;

  EducationArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl = '',
    this.url = '',
    this.isOffline = false,
    this.publishedAt,
  });

  factory EducationArticle.fromJson(Map<String, dynamic> json) {
    return EducationArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? json['description'] ?? '',
      category: json['category'] ?? 'Umum',
      imageUrl: json['imageUrl'] ?? json['urlToImage'] ?? '',
      url: json['url'] ?? '',
      isOffline: json['isOffline'] ?? false,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'url': url,
      'isOffline': isOffline,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }
}
