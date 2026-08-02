import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

import '../constants/app_config.dart';
import '../services/ollama_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components/revive_card.dart';
import '../widgets/components/revive_state_view.dart';
import '../widgets/components/voice_activity_indicator.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser})
    : timestamp = DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final OllamaService _ollama = OllamaService();
  final SttService _stt = SttService();
  final TtsService _tts = TtsService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _isListening = false;
  bool _ollamaAvailable = false;
  bool _micDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final available = await _ollama.checkAvailability();
    await _tts.initialize();
    if (mounted) {
      setState(() {
        _ollamaAvailable = available;
        _messages.add(
          ChatMessage(
            text: available
                ? "I'm the Revive assistant. Ask me about CPR, choking, AED "
                      "use, or any first-aid question. Type, or tap the mic to "
                      "speak."
                : "I'm offline right now, so I can't answer questions. Training "
                      "Mode on the home screen has the full CPR protocol and "
                      "works without any connection.",
            isUser: false,
          ),
        );
      });
    }
  }

  static const String _offlineMessage =
      "AI is offline right now (no connection to the coach). "
      "For step-by-step guidance without AI, use Training Mode from the home screen — "
      "it works fully offline.";

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text.trim(), isUser: true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Recheck (fast, 5s timeout) rather than trusting the flag from
    // initState — connectivity to the ngrok tunnel can change mid-session.
    // If it's down, skip straight to the offline message instead of making
    // the user wait out chatAnswer's own 90s timeout for the same outcome.
    final available = await _ollama.checkAvailability();
    if (mounted && available != _ollamaAvailable) {
      setState(() => _ollamaAvailable = available);
    }

    final String? response = available
        ? await _ollama.chatAnswer(text.trim())
        : null;

    if (mounted) {
      final responseText = response ?? _offlineMessage;
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(text: responseText, isUser: false));
      });
      _scrollToBottom();

      // Speak the AI response out loud
      if (response != null) {
        await _tts.speak(response);
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stt.stopListening();
      setState(() => _isListening = false);
      return;
    }

    final ready = await _stt.initialize();
    if (!ready) {
      if (mounted) setState(() => _micDenied = true);
      return;
    }

    setState(() {
      _isListening = true;
      _micDenied = false;
    });

    await _stt.startListening(
      onResult: (recognizedText) {
        if (!mounted) return;
        setState(() => _isListening = false);
        if (recognizedText.isNotEmpty) {
          if (_isEmergencyPhrase(recognizedText)) {
            _handleEmergencyCall();
          } else {
            _sendMessage(recognizedText);
          }
        }
      },
    );
  }

  Future<void> _handleEmergencyCall() async {
    await FlutterPhoneDirectCaller.callNumber(AppConfig.emergencyNumber);
  }

  bool _isEmergencyPhrase(String text) {
    final lower = text.toLowerCase();
    return lower.contains(AppConfig.emergencyNumber) ||
        lower.contains('emergency') ||
        lower.contains('ambulance');
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppMotion.slow,
          curve: AppMotion.standard,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    _stt.stopListening();
    _tts.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _tts.stop();
      _stt.stopListening();
    }
  }

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.surfacePrimary,
      appBar: AppBar(
        backgroundColor: c.surfacePrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textSecondary),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'Assistant',
              style: context.text.titleLarge?.copyWith(color: c.textPrimary),
            ),
            AppSpacing.hGapMd,
            ReviveStatusPill(
              label: _ollamaAvailable ? 'ONLINE' : 'OFFLINE',
              icon: _ollamaAvailable ? Icons.cloud_done : Icons.cloud_off,
              tone: _ollamaAvailable
                  ? ReviveCardTone.success
                  : ReviveCardTone.caution,
              semanticLabel: _ollamaAvailable
                  ? 'Assistant is online'
                  : 'Assistant is offline',
            ),
          ],
        ),
      ),
      // top: false because the AppBar already clears the status bar / notch.
      // The bottom inset is handled here rather than by hand in the input bar,
      // so it cannot double-count against the keyboard inset.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ReviveLoadingView(size: 20),
                      ),
                    );
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            if (_micDenied)
              Padding(
                padding: AppSpacing.pagePadding,
                child: ReviveStateView.micPermissionDenied(),
              )
            else if (_isListening)
              Padding(
                padding: AppSpacing.pagePadding,
                child: const VoiceActivityIndicator(
                  state: VoiceActivityState.listening,
                ),
              ),
            if (_messages.length <= 1 && _ollamaAvailable) _buildSuggestions(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    const suggestions = [
      'How deep should compressions be?',
      'What is the CPR ratio for adults?',
      'How do I use an AED?',
      'What if the person is choking?',
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => AppSpacing.hGapSm,
        itemBuilder: (context, index) => ActionChip(
          label: Text(
            suggestions[index],
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          backgroundColor: context.colors.surfaceRaised,
          side: BorderSide(color: context.colors.borderSubtle),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderPill,
          ),
          onPressed: () => _sendMessage(suggestions[index]),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final c = context.colors;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.urgentActionSubtle,
                borderRadius: AppRadius.borderSm,
              ),
              child: Icon(
                Icons.health_and_safety_outlined,
                color: c.urgentAction,
                size: 18,
              ),
            ),
            AppSpacing.hGapSm,
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isUser ? c.urgentAction : c.surfaceRaised,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(
                    isUser ? AppRadius.lg : AppRadius.xs,
                  ),
                  bottomRight: Radius.circular(
                    isUser ? AppRadius.xs : AppRadius.lg,
                  ),
                ),
                border: isUser ? null : Border.all(color: c.borderSubtle),
              ),
              child: Text(
                message.text,
                style: context.text.bodyMedium?.copyWith(
                  color: isUser ? c.onUrgentAction : c.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final c = context.colors;

    return Container(
      // Bottom inset is now supplied by the SafeArea around the body, so this
      // only needs its own breathing room.
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.sm,
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        border: Border(top: BorderSide(color: c.borderSubtle)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: _isListening ? 'Stop listening' : 'Ask by voice',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _toggleListening,
              child: Container(
                width: AppTouchTarget.minimum,
                height: AppTouchTarget.minimum,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isListening ? c.urgentAction : c.surfaceRaised,
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(color: c.borderSubtle),
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? c.onUrgentAction : c.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: TextField(
              controller: _textController,
              style: context.text.bodyMedium?.copyWith(color: c.textPrimary),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: _isListening
                    ? 'Listening...'
                    : 'Ask about CPR or first aid',
                hintStyle: context.text.bodyMedium?.copyWith(
                  color: c.textTertiary,
                ),
                filled: true,
                fillColor: c.surfaceRaised,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderXl,
                  borderSide: BorderSide(color: c.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderXl,
                  borderSide: BorderSide(color: c.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderXl,
                  borderSide: BorderSide(color: c.urgentAction),
                ),
              ),
            ),
          ),
          AppSpacing.hGapSm,
          Semantics(
            button: true,
            label: 'Send message',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => _sendMessage(_textController.text),
              child: Container(
                width: AppTouchTarget.minimum,
                height: AppTouchTarget.minimum,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.urgentAction,
                  borderRadius: AppRadius.borderPill,
                ),
                child: Icon(Icons.send, color: c.onUrgentAction, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
