import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../repositories/chat_repository.dart';
import '../screens/user_profile_setup_screen.dart';
import '../screens/chat_settings_screen.dart';
import '../services/chat_service.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';
import '../models/detection_result.dart';
import '../utils/chat_preferences.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../widgets/chat_message_widget.dart';

class ChatScreen extends StatefulWidget {
  final DetectionResult? detectionResult;

  const ChatScreen({super.key, this.detectionResult});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ChatViewModel _viewModel;
  late ChatPreferencesManager _preferencesManager;
  bool _isInitialized = false;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeViewModel();
    _messageController.addListener(_onMessageChanged);

    // Auto-consultation for detection result
    if (widget.detectionResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoConsultation();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  void _onMessageChanged() {
    final isComposing = _messageController.text.trim().isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
  }

  Future<void> _initializeViewModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatPreferences = ChatPreferences(prefs);
      final preferencesManager = ChatPreferencesManager(chatPreferences);
      final userProfileService = UserProfileService(prefs);

      await preferencesManager.initialize();

      if (userProfileService.needsProfileRecovery) {
        final shouldRecover = await _showProfileRecoveryDialog();
        if (shouldRecover) {
          await _showProfileSetupForm(userProfileService);
        } else {
          await userProfileService.createDefaultProfile('User');
        }
        await userProfileService.markProfileRecoveryComplete();
      }      final chatService = ChatService();
      _preferencesManager = preferencesManager;

      _viewModel = ChatViewModel(
        chatRepository: ChatRepository(
          chatService: chatService,
          prefs: prefs,
        ),
        preferencesManager: preferencesManager,
      );

      try {
        final userProfile = await userProfileService.getUserProfile();
        final userName = userProfile?.name.isNotEmpty == true
            ? userProfile!.name
            : 'User';

        if (preferencesManager.isFirstTimeChat || _viewModel.messages.isEmpty) {
          _viewModel.addPersonalizedWelcomeMessages(userName);
          await preferencesManager.setFirstTimeChat(false);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottomImmediate();
          });
        }
      } catch (e) {
        print('Error setting up welcome messages: $e');
        if (preferencesManager.isFirstTimeChat || _viewModel.messages.isEmpty) {
          _viewModel.addSimpleWelcomeMessage();
          await preferencesManager.setFirstTimeChat(false);
        }
      }

      setState(() {
        _isInitialized = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_viewModel.messages.isNotEmpty) {
          _scrollToBottomImmediate();
        }
      });
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _isInitialized = false;
      });

      if (mounted) {
        _showInitializationError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isInitialized ? _buildChatInterface() : _buildLoadingState(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ModernAppBar(
      titleWidget: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DrAI Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Konsultasi Diabetes AI',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showChatSettings(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
          tooltip: 'Pengaturan Chat',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildChatInterface() {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          // Auto scroll when needed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (viewModel.shouldScrollToBottom) {
              _scrollToBottom();
              viewModel.scrollHandled();
            }
          });

          return Column(
            children: [
              // Chat Messages Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: viewModel.messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessagesList(viewModel),
                ),
              ),
              
              // Input Area
              _buildInputArea(viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Mempersiapkan DrAI...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mulai Percakapan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tanyakan apa saja tentang diabetes\nkepada DrAI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildQuickStartButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartButtons() {
    final suggestions = [
      'Apa itu diabetes?',
      'Bagaimana cara mencegah diabetes?',
      'Gejala diabetes pada lidah',
    ];

    return Column(
      children: suggestions.map((suggestion) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ModernButton(
            text: suggestion,
            variant: ModernButtonVariant.outlined,
            size: ModernButtonSize.small,
            onPressed: () {
              _messageController.text = suggestion;
              _sendMessage();
            },
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildMessagesList(ChatViewModel viewModel) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: viewModel.messages.length,
      itemBuilder: (context, index) {
        final message = viewModel.messages[index];
        return ChatMessageWidget(
          message: message,
          onRetry: message.hasError ? () => viewModel.retryMessage(message) : null,
          onStopGeneration: message.isStreaming 
              ? () => viewModel.stopGeneration(message.id) 
              : null,
        );
      },
    );
  }

  Widget _buildInputArea(ChatViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ModernTextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                hint: 'Tanyakan tentang diabetes...',
                maxLines: 4,
                enabled: !viewModel.isLoading,
                onSubmitted: (_) => _sendMessage(),
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(width: 12),
            _buildSendButton(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(ChatViewModel viewModel) {
    final canSend = _isComposing && !viewModel.isLoading;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      child: FloatingActionButton(
        onPressed: canSend ? _sendMessage : null,
        backgroundColor: canSend ? AppColors.primary : AppColors.border,
        foregroundColor: canSend ? Colors.white : AppColors.textSecondary,
        elevation: canSend ? 4 : 0,
        child: viewModel.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                _isComposing ? Icons.send_rounded : Icons.mic_rounded,
                size: 20,
              ),
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || _viewModel.isLoading) return;

    _messageController.clear();
    _messageFocusNode.unfocus();

    if (widget.detectionResult != null) {
      _viewModel.sendMessageWithDetectionContext(
        message,
        detectionResult: widget.detectionResult,
      );
    } else {
      _viewModel.sendMessage(message);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottomImmediate() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _startAutoConsultation() {
    if (widget.detectionResult == null) return;

    final result = widget.detectionResult!;
    final autoMessage = 'Halo DrAI, saya baru saja melakukan deteksi diabetes dan mendapat hasil ${result.className} dengan tingkat kepercayaan ${(result.confidence * 100).toStringAsFixed(1)}%. Bisakah Anda menjelaskan hasil ini dan memberikan saran?';

    _messageController.text = autoMessage;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendMessage();
    });
  }

  Future<bool> _showProfileRecoveryDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_rounded, color: AppColors.warning),
                const SizedBox(width: 12),
                const Text('Profil Perlu Dipulihkan'),
              ],
            ),
            content: const Text(
              'Data profil Anda mengalami masalah dan perlu dipulihkan. '
              'Apakah Anda ingin mengatur ulang profil sekarang?\n\n'
              'Jika tidak, profil default akan dibuat untuk Anda.',
            ),
            actions: [
              ModernButton(
                text: 'Gunakan Default',
                variant: ModernButtonVariant.text,
                onPressed: () => Navigator.pop(context, false),
              ),
              ModernButton(
                text: 'Setup Profil',
                variant: ModernButtonVariant.primary,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
  }
  Future<void> _showProfileSetupForm(UserProfileService userProfileService) async {
    final result = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileSetupScreen(
          userProfileService: userProfileService,
        ),
      ),
    );

    if (result != null) {
      await userProfileService.saveUserProfile(result);
    }
  }
  void _showChatSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatSettingsScreen(
          preferencesManager: _preferencesManager,
        ),
      ),
    );
  }

  void _showInitializationError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('Gagal Memuat Chat'),
          ],
        ),
        content: Text('Terjadi kesalahan saat memuat chat: $error'),
        actions: [
          ModernButton(
            text: 'Coba Lagi',
            variant: ModernButtonVariant.primary,
            onPressed: () {
              Navigator.pop(context);
              _initializeViewModel();
            },
          ),
        ],
      ),
    );
  }
}
