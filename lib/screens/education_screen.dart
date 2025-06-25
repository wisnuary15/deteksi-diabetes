import 'package:flutter/material.dart';
import '../models/education_article.dart';
import '../services/education_repository.dart';
import '../constants/app_colors.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_text_field.dart';
import 'article_detail_screen.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  List<EducationArticle> _articles = [];
  List<EducationArticle> _filteredArticles = [];
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Tips Kesehatan',
    'Nutrisi',
    'Olahraga',
    'Informasi Medis',
    'Berita Kesehatan',
  ];

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final articles = await EducationRepository.getArticles();
      setState(() {
        _articles = articles;
        _filteredArticles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat artikel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterArticles() {
    setState(() {
      _filteredArticles = _articles.where((article) {
        final matchesCategory =
            _selectedCategory == 'Semua' ||
            article.category == _selectedCategory;
        final matchesSearch =
            _searchController.text.isEmpty ||
            article.title.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Tips Kesehatan':
        return AppColors.success;
      case 'Nutrisi':
        return AppColors.warning;
      case 'Olahraga':
        return AppColors.primary;
      case 'Informasi Medis':
        return AppColors.error;
      case 'Berita Kesehatan':
        return Colors.purple;
      default:
        return AppColors.neutral500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModernAppBar(title: 'Edukasi Diabetes', centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _loadArticles,
        color: AppColors.primary,
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),

            const SizedBox(height: 16),

            // Category Filter
            _buildCategoryFilter(),

            const SizedBox(height: 24),

            // Articles List
            _buildArticlesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ModernSearchField(
        hint: 'Cari artikel edukasi...',
        controller: _searchController,
        onChanged: (_) => _filterArticles(),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
                _filterArticles();
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticlesList() {
    return Expanded(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _filteredArticles.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _filteredArticles.length,
              itemBuilder: (context, index) {
                final article = _filteredArticles[index];
                return _buildArticleCard(article);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.article_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tidak ada artikel',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba ubah kata kunci pencarian\natau kategori artikel',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(EducationArticle article) {
    final categoryColor = _getCategoryColor(article.category);

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
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
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  article.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: categoryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Content Preview
              Text(
                article.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 20),

              // Footer
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: article.isOffline
                          ? AppColors.successBackground
                          : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          article.isOffline
                              ? Icons.offline_pin
                              : Icons.language,
                          size: 12,
                          color: article.isOffline
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.isOffline ? 'Offline' : 'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: article.isOffline
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
