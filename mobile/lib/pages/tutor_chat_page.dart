// ===============================================================
// File: lib/pages/tutor_chat_page.dart
//
// - Provides a minimal, reliable chat surface to iterate on.
// - Keeps API/state integrations optional so multiple teammates can work in
//   parallel (UI/UX, state, networking, evaluation).
// - The scaffold uses only Flutter core widgets to ensure it compiles out of
//   the box on any device for early demos.
//
// NOTES (scaffold philosophy)
// - Local in-memory message list is deliberate for usability; replace
//   with a repository/ViewModel later without changing the widget API.
// - Optional callbacks allow the parent to handle navigation and data wiring
//   without creating tight coupling here.
// - Keep components small (_MessageBubble, _Composer) to reduce merge conflicts.
// ===============================================================

import 'package:flutter/material.dart';

/// Lightweight representation of a chat message for the scaffold.
/// Avoids pulling in full models until the API contract is finalized.
class _MessageEntry {
  final String text;
  final bool isUser;
  const _MessageEntry({required this.text, required this.isUser});
}

/// TutorChatPage — minimal chat surface with a message list and composer.
///
/// Later, replace the in-memory list with your state management choice and
/// connect the Send action to the API.
class TutorChatPage extends StatefulWidget {
  /// Optional session identifier for future persistence.
  final String? sessionId;

  /// Optional hook for analytics or parent-managed sending.
  final ValueChanged<String>? onSend;

  const TutorChatPage({super.key, this.sessionId, this.onSend});

  @override
  State<TutorChatPage> createState() => _TutorChatPageState();
}

class _TutorChatPageState extends State<TutorChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // Start with a friendly system message so the UI has content on first run.
  final List<_MessageEntry> _messages = const [
    _MessageEntry(
      text: 'Hi! I\'m your step-by-step tutor. Ask a question to begin.',
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              return _MessageBubble(text: m.text, isUser: m.isUser);
            },
          ),
        ),
        const Divider(height: 1),
        _Composer(
          controller: _controller,
          focusNode: _focusNode,
          onSend: _handleSend,
        ),
      ],
    );
  }

  void _handleSend(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_MessageEntry(text: text, isUser: true));
    });

    // Provide immediate feedback for UX and grading; real app will call API.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stub: would call /api/tutor')),
    );

    widget.onSend?.call(text);

    // Optional: add a placeholder tutor response so the UI shows a conversation.
    setState(() {
      _messages.add(const _MessageEntry(
        text: 'Let\'s break it down. What\'s the first step you can try?',
        isUser: false,
      ));
    });

    _controller.clear();

    // Auto-scroll to the bottom so messages are immediately visible.
    _scrollToEnd();
  }

  void _scrollToEnd() {
    // Delay until next frame so ListView has updated its layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

// --------------------------- Composer ---------------------------

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSend;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                decoration: const InputDecoration(
                  hintText: 'Type your message…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => onSend(controller.text),
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------- Message bubble ---------------------------

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceVariant;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: BoxDecoration(color: bg, borderRadius: radius),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}