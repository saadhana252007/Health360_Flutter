import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/assistant_repo.dart';

/// Provider for passing checkup context to the assistant.
final assistantCheckupIdProvider = StateProvider<String?>((ref) => null);

/// Represents a single chat message item in the assistant conversation.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
}

/// AI Health Assistant screen replicating Android `AssistantFragment.kt`
/// and `fragment_assistant.xml`.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.checkupId});

  final String? checkupId;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _messageInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void dispose() {
    _messageInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? get _activeCheckupId =>
      widget.checkupId ?? ref.read(assistantCheckupIdProvider);

  Future<void> _sendMessage([String? prefilledMessage]) async {
    final text = (prefilledMessage ?? _messageInputController.text).trim();
    if (text.isEmpty || _isSending) return;

    _messageInputController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final repository = ref.read(assistantRepositoryProvider);
      final response = await repository.chat(
        message: text,
        checkupId: _activeCheckupId,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
          if (response.status == 'completed') {
            _messages.add(ChatMessage(text: response.message, isUser: false));
          } else {
            _messages.add(
              const ChatMessage(
                text: "I couldn't process that request. Please try again.",
                isUser: false,
                isError: true,
              ),
            );
          }
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _messages.add(
            const ChatMessage(
              text: 'Something went wrong while connecting to Health360 AI. Please try again.',
              isUser: false,
              isError: true,
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkupContext = _activeCheckupId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Bar ────────────────────────────────────────────
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'AI Health Assistant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF17343B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Understand your Health360 results',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF71858A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF087C83),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Chat Messages & Suggestions View ──────────────────────────
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
                children: [
                  // ── Screening Context Banner (if checkup context active) ──
                  if (checkupContext != null && checkupContext.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFB9DDDB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'CURRENT HEALTH360 SCREENING',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF087C83),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Recent screening result',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF17343B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ask Health360 AI about your result',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF087C83),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Default Welcome Header & Bubble ─────────────────────
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
                    child: const Text(
                      'Health360 Intelligence  •  Now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF087C83),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 55, bottom: 14),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE1E8EA)),
                    ),
                    child: const Text(
                      'Hi! I can help you understand your Health360 screening result. '
                      'Ask me about your screening status, confidence, warning signs, or next steps.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF263C42),
                        height: 1.4,
                      ),
                    ),
                  ),

                  // ── Quick Prompt Chips ──────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPromptChip(
                          label: '✦ Explain my result',
                          color: const Color(0xFF087C83),
                          bgColor: const Color(0xFFEFF8F8),
                          onTap: () => _sendMessage(
                            'Explain my health screening result in simple words.',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPromptChip(
                          label: '⚠ What are my warning signs?',
                          color: const Color(0xFF4459B8),
                          bgColor: const Color(0xFFF5F6FF),
                          onTap: () =>
                              _sendMessage('What are my warning signs?'),
                        ),
                        const SizedBox(width: 8),
                        _buildPromptChip(
                          label: 'What does confidence mean?',
                          color: const Color(0xFF087C83),
                          bgColor: const Color(0xFFEFF8F8),
                          onTap: () => _sendMessage(
                            'What does my confidence and uncertainty mean?',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Dynamic Chat History Messages ───────────────────────
                  ..._messages.map(_buildMessageBubble),

                  // ── In-flight Loading Indicator ─────────────────────────
                  if (_isSending)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF087C83),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Thinking...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF71858A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Input Bar & Disclaimer ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.only(left: 16, right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F8),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageInputController,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Ask about your result...',
                              hintStyle: TextStyle(
                                color: Color(0xFF808080),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _isSending ? null : () => _sendMessage(),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFF087C83),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_upward,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Health360 AI provides guidance, not a medical diagnosis.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF71858A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip({
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSending ? null : onTap,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 70, right: 4, top: 6, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF087C83),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 4, right: 55, top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isError
              ? const Color(0xFFFFF0F0)
              : const Color(0xFFF0F8F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: msg.isError
                ? const Color(0xFFFCA5A5)
                : const Color(0xFFB9DDDB),
            width: 1,
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 15,
            color: msg.isError
                ? const Color(0xFFA32222)
                : const Color(0xFF263C42),
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
