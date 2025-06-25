import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_models.dart';
import '../constants/app_colors.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onStopGeneration;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.onStopGeneration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isFromUser) _buildAvatarAI(),
          if (!message.isFromUser) const SizedBox(width: 12),
          Expanded(
            child: message.isFromUser
                ? _buildUserMessage(context)
                : _buildAIMessage(context),
          ),
          if (message.isFromUser) const SizedBox(width: 12),
          if (message.isFromUser) _buildAvatarUser(),
        ],
      ),
    );
  }

  Widget _buildAvatarAI() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
    );
  }

  Widget _buildAvatarUser() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(Icons.done_all, color: AppColors.success, size: 14),
          ],
        ),
      ],
    );
  }

  Widget _buildAIMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAIMessageContent(context),
              if (_shouldShowActions()) ...[
                const SizedBox(height: 12),
                _buildMessageActions(context),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (!message.isLoading &&
                !message.hasError &&
                message.message.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(context, message.message),
                child: Icon(
                  Icons.copy_rounded,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAIMessageContent(BuildContext context) {
    if (message.isLoading && !message.isStreaming) {
      return _buildLoadingIndicator();
    }

    if (message.hasError) {
      return _buildErrorContent(context);
    }

    if (message.isStreaming) {
      return _buildStreamingContent();
    }

    return _buildStaticContent();
  }

  Widget _buildLoadingIndicator() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'DrAI sedang berpikir...',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.streamingText.isNotEmpty)
          _formatAIText(message.streamingText)
        else
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'DrAI sedang menulis...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        if (message.isStreaming && onStopGeneration != null) ...[
          const SizedBox(height: 8),
          _buildStopButton(),
        ],
      ],
    );
  }

  Widget _buildStaticContent() {
    return _formatAIText(message.message);
  }

  Widget _buildErrorContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.error.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Terjadi kesalahan saat memproses pesan',
                  style: TextStyle(color: AppColors.error, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          _buildRetryButton(),
        ],
      ],
    );
  }

  Widget _buildStopButton() {
    return ElevatedButton.icon(
      onPressed: onStopGeneration,
      icon: const Icon(Icons.stop_rounded, size: 16),
      label: const Text('Hentikan'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: const Text('Coba Lagi'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildMessageActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () => _copyToClipboard(context, message.message),
          icon: Icon(
            Icons.copy_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Salin pesan',
        ),
        IconButton(
          onPressed: () => _shareMessage(context, message.message),
          icon: Icon(
            Icons.share_rounded,
            color: AppColors.textSecondary,
            size: 18,
          ),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'Bagikan pesan',
        ),
      ],
    );
  }

  Widget _formatAIText(String text) {
    // Split text into paragraphs and format
    final paragraphs = text.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        if (paragraph.trim().isEmpty) return const SizedBox.shrink();

        // Check if it's a header (starts with #, **, etc.)
        if (paragraph.startsWith('**') && paragraph.endsWith('**')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              paragraph.replaceAll('**', ''),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }

        // Check if it's a bullet point
        if (paragraph.startsWith('•') || paragraph.startsWith('-')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 12),
            child: Text(
              paragraph,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          );
        }

        // Regular paragraph
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            paragraph,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _shouldShowActions() {
    return !message.isLoading &&
        !message.hasError &&
        !message.isStreaming &&
        message.message.isNotEmpty;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String timeString =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return timeString;
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Kemarin $timeString';
    } else {
      return '${dateTime.day}/${dateTime.month} $timeString';
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pesan disalin ke clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _shareMessage(BuildContext context, String text) {
    // Implementation for sharing message
    // You can use share_plus package here
    _copyToClipboard(context, text);
  }
}
