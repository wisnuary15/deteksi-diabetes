import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/education_article.dart';

class ArticleDetailScreen extends StatefulWidget {
  final EducationArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  double _fontSize = 16.0;
  bool _isDarkMode = false;

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Tips Kesehatan':
        return Colors.green;
      case 'Nutrisi':
        return Colors.orange;
      case 'Olahraga':
        return Colors.blue;
      case 'Informasi Medis':
        return Colors.red;
      case 'Berita Kesehatan':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showTextSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengaturan Teks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 20),
              
              // Font Size
              Text(
                'Ukuran Teks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              Slider(
                value: _fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 6,
                label: _fontSize.round().toString(),
                onChanged: (value) {
                  setModalState(() {
                    _fontSize = value;
                  });
                  setState(() {
                    _fontSize = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Dark Mode Toggle
              SwitchListTile(
                title: Text(
                  'Mode Gelap',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                subtitle: const Text('Nyaman untuk mata di malam hari'),
                value: _isDarkMode,
                onChanged: (value) {
                  setModalState(() {
                    _isDarkMode = value;
                  });
                  setState(() {
                    _isDarkMode = value;
                  });
                },
                activeColor: Colors.blue.shade600,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _shareArticle() {
    final text = '''
${widget.article.title}

${widget.article.content}

---
Dibagikan dari Aplikasi Deteksi Diabetes
''';
    
    // Copy to clipboard (simple sharing)
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Artikel disalin ke clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode ? Colors.grey.shade900 : Colors.blue.shade50;
    final cardColor = _isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = _isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.article.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _getCategoryColor(widget.article.category),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: _showTextSettings,
            tooltip: 'Pengaturan Teks',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareArticle,
            tooltip: 'Bagikan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getCategoryColor(widget.article.category),
                    _getCategoryColor(widget.article.category).withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.article.isOffline 
                                  ? Icons.offline_pin 
                                  : Icons.language,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.article.isOffline ? 'Offline' : 'Online',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        widget.article.title,
                        style: TextStyle(
                          fontSize: _fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Meta Info
                      if (widget.article.publishedAt != null)
                        Text(
                          _formatDate(widget.article.publishedAt!),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Content Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content
                  SelectableText(
                    widget.article.content,
                    style: TextStyle(
                      fontSize: _fontSize,
                      color: textColor,
                      height: 1.6,
                      letterSpacing: 0.3,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Footer Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isDarkMode 
                          ? Colors.grey.shade700.withOpacity(0.3)
                          : Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Artikel ini hanya untuk tujuan edukasi. Konsultasikan dengan dokter untuk saran medis yang tepat.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtitleColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!widget.article.isOffline && widget.article.url.isNotEmpty)
                          const SizedBox(height: 12),
                        if (!widget.article.isOffline && widget.article.url.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Buka URL eksternal (implementasi nanti)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fitur buka link belum tersedia'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Baca Artikel Lengkap'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _getCategoryColor(widget.article.category),
                                side: BorderSide(
                                  color: _getCategoryColor(widget.article.category),
                                ),
                              ),
                            ),
                          ),
                      ],
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

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }
}