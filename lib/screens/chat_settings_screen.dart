import 'package:flutter/material.dart';
import '../utils/chat_preferences.dart';

class ChatSettingsScreen extends StatefulWidget {
  final ChatPreferencesManager preferencesManager;

  const ChatSettingsScreen({super.key, required this.preferencesManager});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  late ChatPreferencesManager _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = widget.preferencesManager;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Pengaturan Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Reset ke Default'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'minimal',
                child: Row(
                  children: [
                    Icon(Icons.minimize, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Mode Minimal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rich',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Mode Lengkap'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResponseSection(),
            const SizedBox(height: 24),
            _buildDisplaySection(),
            const SizedBox(height: 24),
            _buildLanguageSection(),
            const SizedBox(height: 24),
            _buildAdvancedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseSection() {
    return _buildSection(
      title: 'Respons AI',
      icon: Icons.chat,
      children: [
        SwitchListTile(
          title: const Text('Mode Streaming'),
          subtitle: const Text('Tampilkan respons secara bertahap'),
          value: _prefs.isStreamingEnabled,
          onChanged: (value) async {
            await _prefs.setStreamingEnabled(value);
            setState(() {});
          },
          activeColor: Colors.blue.shade600,
        ),
        SwitchListTile(
          title: const Text('Indikator Mengetik'),
          subtitle: const Text('Tampilkan saat AI sedang mengetik'),
          value: _prefs.isTypingIndicatorEnabled,
          onChanged: (value) async {
            await _prefs.setTypingIndicatorEnabled(value);
            setState(() {});
          },
          activeColor: Colors.blue.shade600,
        ),
        // ENHANCED: Streaming Speed Settings
        ListTile(
          leading: const Icon(Icons.speed),
          title: const Text('Kecepatan Streaming'),
          subtitle: Text(_getSpeedDisplayName(_prefs.streamingSpeed)),
          trailing: DropdownButton<String>(
            value: _prefs.streamingSpeed,
            underline: Container(),
            items: const [
              DropdownMenuItem(value: 'instant', child: Text('Instan')),
              DropdownMenuItem(value: 'fast', child: Text('Cepat')),
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'slow', child: Text('Lambat')),
            ],
            onChanged: (value) async {
              if (value != null) {
                await _prefs.setStreamingSpeed(value);
                setState(() {});
                _showSnackBar(
                  'Kecepatan streaming diubah ke ${_getSpeedDisplayName(value)}',
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDisplaySection() {
    return _buildSection(
      title: 'Tampilan',
      icon: Icons.display_settings,
      children: [
        SwitchListTile(
          title: const Text('Auto Scroll'),
          subtitle: const Text('Scroll otomatis ke pesan terbaru'),
          value: _prefs.isAutoScrollEnabled,
          onChanged: (value) async {
            await _prefs.setAutoScrollEnabled(value);
            setState(() {});
          },
          activeColor: Colors.blue.shade600,
        ),
        ListTile(
          title: const Text('Ukuran Teks'),
          subtitle: Text('${_prefs.messageTextSize.toInt()}px'),
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: _prefs.messageTextSize,
              min: 10.0,
              max: 24.0,
              divisions: 14,
              onChanged: (value) async {
                await _prefs.setMessageTextSize(value);
                setState(() {});
              },
              activeColor: Colors.blue.shade600,
            ),
          ),
        ),
        ListTile(
          title: const Text('Tema'),
          subtitle: Text(_getThemeDisplayName(_prefs.chatTheme)),
          trailing: DropdownButton<String>(
            value: _prefs.chatTheme,
            items: _prefs.getSupportedThemes().map((theme) {
              return DropdownMenuItem(
                value: theme,
                child: Text(_getThemeDisplayName(theme)),
              );
            }).toList(),
            onChanged: (value) async {
              if (value != null) {
                await _prefs.setChatTheme(value);
                setState(() {});
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return _buildSection(
      title: 'Bahasa',
      icon: Icons.language,
      children: [
        ListTile(
          title: const Text('Bahasa Preferensi'),
          subtitle: Text(_prefs.getLanguageDisplayName()),
          trailing: DropdownButton<String>(
            value: _prefs.preferredLanguage,
            items: _prefs.getSupportedLanguages().map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Text(_getLanguageDisplayName(lang)),
              );
            }).toList(),
            onChanged: (value) async {
              if (value != null) {
                await _prefs.setPreferredLanguage(value);
                setState(() {});
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return _buildSection(
      title: 'Lanjutan',
      icon: Icons.settings,
      children: [
        ListTile(
          leading: const Icon(Icons.file_download, color: Colors.green),
          title: const Text('Export Pengaturan'),
          subtitle: const Text('Simpan pengaturan ke file'),
          onTap: _exportSettings,
        ),
        ListTile(
          leading: const Icon(Icons.file_upload, color: Colors.blue),
          title: const Text('Import Pengaturan'),
          subtitle: const Text('Muat pengaturan dari file'),
          onTap: _importSettings,
        ),
        ListTile(
          leading: const Icon(Icons.info, color: Colors.grey),
          title: const Text('Info Debug'),
          subtitle: const Text('Tampilkan informasi teknis'),
          onTap: _showDebugInfo,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'reset':
        await _showResetDialog();
        break;
      case 'minimal':
        await _prefs.applyMinimalSettings();
        setState(() {});
        _showSnackBar('Mode minimal diterapkan');
        break;
      case 'rich':
        await _prefs.applyRichSettings();
        setState(() {});
        _showSnackBar('Mode lengkap diterapkan');
        break;
    }
  }

  Future<void> _showResetDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Pengaturan'),
        content: const Text(
          'Semua pengaturan akan dikembalikan ke default. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _prefs.resetToDefaults();
      setState(() {});
      _showSnackBar('Pengaturan direset ke default');
    }
  }

  void _exportSettings() {
    _prefs.exportSettings();
    // Implementation for exporting settings
    _showSnackBar('Pengaturan berhasil diekspor');
  }

  void _importSettings() {
    // Implementation for importing settings
    _showSnackBar('Fitur import akan segera tersedia');
  }

  void _showDebugInfo() {
    final debugInfo = _prefs.getDebugInfo();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info Debug'),
        content: SingleChildScrollView(child: Text(debugInfo.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Terang';
      case 'dark':
        return 'Gelap';
      case 'system':
        return 'Mengikuti Sistem';
      default:
        return 'Terang';
    }
  }

  String _getLanguageDisplayName(String lang) {
    switch (lang) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      case 'jv':
        return 'Bahasa Jawa';
      default:
        return 'Bahasa Indonesia';
    }
  }

  String _getSpeedDisplayName(String speed) {
    switch (speed) {
      case 'instant':
        return 'Instan (langsung tampil)';
      case 'fast':
        return 'Cepat (rekomendasi)';
      case 'normal':
        return 'Normal (standard)';
      case 'slow':
        return 'Lambat (santai)';
      default:
        return 'Cepat';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
