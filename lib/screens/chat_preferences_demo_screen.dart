import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/chat_preferences_service.dart';

class ChatPreferencesDemoScreen extends StatefulWidget {
  const ChatPreferencesDemoScreen({super.key});

  @override
  State<ChatPreferencesDemoScreen> createState() =>
      _ChatPreferencesDemoScreenState();
}

class _ChatPreferencesDemoScreenState extends State<ChatPreferencesDemoScreen> {
  Map<String, dynamic>? _chatPreferences;
  Map<String, dynamic>? _userChatContext;
  String? _personalizedPrompt;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Preferences Demo'),
        backgroundColor: Colors.blue.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDemoSection(),
            const SizedBox(height: 24),
            _buildCurrentPreferencesSection(),
            const SizedBox(height: 24),
            _buildPersonalizedPromptSection(),
            const SizedBox(height: 24),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demo: Chat Preferences Integration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sistem ini menunjukkan bagaimana data profil user dikonversi menjadi preferensi chat yang personal untuk AI.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _createDemoProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buat Demo Profile & Update Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat Preferences Saat Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_chatPreferences != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatJson(_chatPreferences!),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ] else ...[
              const Text(
                'Belum ada preferences. Buat demo profile terlebih dahulu.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedPromptSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalized System Prompt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_personalizedPrompt != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _personalizedPrompt!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ] else ...[
              const Text(
                'Prompt belum dibuat. Buat demo profile terlebih dahulu.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loadCurrentPreferences,
                    child: const Text('Load Preferences'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearPreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createDemoProfile() async {
    setState(() => _isLoading = true);

    try {
      // Buat demo profile
      final demoProfile = UserProfile(
        id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Budi Santoso',
        age: 45,
        gender: 'Laki-laki',
        weight: 78.5,
        height: 170.0,
        bloodType: 'B',
        medicalHistory: ['Hipertensi', 'Kolesterol tinggi'],
        currentMedications: ['Amlodipine 5mg'],
        allergies: ['Seafood'],
        familyDiabetesHistory: 'Ayah diabetes tipe 2 sejak usia 50 tahun',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update chat preferences berdasarkan profile
      final success =
          await ChatPreferencesService.updateChatPreferencesFromProfile(
            demoProfile,
          );

      if (success) {
        // Load preferences yang baru dibuat
        await _loadCurrentPreferences();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Demo profile berhasil dibuat dan preferences diupdate!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Gagal update preferences');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCurrentPreferences() async {
    try {
      final preferences = await ChatPreferencesService.getChatPreferences();
      final context = await ChatPreferencesService.getUserChatContext();
      final prompt = await ChatPreferencesService.getPersonalizedSystemPrompt();

      setState(() {
        _chatPreferences = preferences;
        _userChatContext = context;
        _personalizedPrompt = prompt;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearPreferences() async {
    try {
      final success = await ChatPreferencesService.clearChatPreferences();
      if (success) {
        setState(() {
          _chatPreferences = null;
          _userChatContext = null;
          _personalizedPrompt = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    json.forEach((key, value) {
      buffer.writeln('$key: ${value.toString()}');
    });
    return buffer.toString();
  }
}
