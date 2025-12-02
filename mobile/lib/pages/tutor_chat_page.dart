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

import 'dart:convert'; // For json serialization

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _backendUrl = 'http://10.0.2.2:8000/chat/completions';

/// Lightweight representation of a chat message for the scaffold.
/// Avoids pulling in full models until the API contract is finalized.
class _MessageEntry {
  String text;
  final bool isUser;
  bool isLoading;
  _MessageEntry({required this.text, required this.isUser, this.isLoading = false});
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

class _TutorChatPageState extends State<TutorChatPage> with AutomaticKeepAliveClientMixin<TutorChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _isReplying = false;

  // Start with a friendly system message so the UI has content on first run.
  final List<_MessageEntry> _messages = [
    _MessageEntry(
      text: 'Hi! I\'m your step-by-step tutor. Ask a question to begin.',
      isUser: false,
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // This is needed to keep the state alive.
    return Container(
      color: const Color.fromARGB(235, 129, 190, 255),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return _MessageBubble(text: m.text, isUser: m.isUser, isLoading: m.isLoading);
              },
            ),
          ),
          const Divider(height: 1),
          _Composer(
            controller: _controller,
            focusNode: _focusNode,
            onSend: _handleSend,
            isReplying: _isReplying,
          ),
        ],
      ),
    );
  }

  void _handleSend(String raw) async {
    // Refocus every time
    _focusNode.requestFocus();

    final text = raw.trim();
    if (text.isEmpty || _isReplying) return;

    // Clear if we sent the message
    _controller.clear();

    setState(() {
      _isReplying = true;
    });

    // Add the user's message to the list
    setState(() {
      _messages.add(_MessageEntry(text: text, isUser: true));
    });
    _scrollToEnd();

    // Add a placeholder for the tutor's response and get a reference to it.
    final tutorResponse = _MessageEntry(text: '', isUser: false, isLoading: true);
    setState(() {
      _messages.add(tutorResponse);
    });
    _scrollToEnd();

    // Call the backend
    try {
      final client = http.Client();
      final request = http.Request(
        'POST',
        Uri.parse(_backendUrl),
      );

      request.headers['Content-Type'] = 'application/json';
      // Encode the entire message history, excluding the loading placeholder
      request.body = jsonEncode({ // TODO: What happens when we reach the max context size? We need some way of "pruning" old messages.
        'messages': _messages
            .where((m) => !m.isLoading)
            .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
            .toList(),
        'stream': true,
      });

      final response = await client.send(request);

      if (response.statusCode == 200) {
        var isFirstChunk = true;
        // Listen to the stream of response chunks
        await for (var chunk in response.stream.transform(utf8.decoder)) {
          if (mounted) {
            setState(() {
              if (isFirstChunk) {
                tutorResponse.isLoading = false;
                isFirstChunk = false;
              }
              tutorResponse.text += chunk;
              _scrollToEnd();
            });
          }
        }
      } else {
        if (mounted) {
          setState(() { // TODO: Special message type for errors?
            tutorResponse.isLoading = false;
            tutorResponse.text = 'Error processing your request: ${response.reasonPhrase}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { // TODO: Special message type for errors?
          tutorResponse.isLoading = false;
          tutorResponse.text = 'Error connecting to the backend: $e';
        });
      }
    } finally {
      setState(() {
        _isReplying = false;
      });
      widget.onSend?.call(text);
    }
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
  final bool isReplying;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isReplying,
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
              onPressed: isReplying ? null : () => onSend(controller.text),
              icon: Icon(isReplying ? Icons.reply : Icons.send),
              label: Text(isReplying ? 'Replying' : 'Send'),
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
  final bool isLoading;
  const _MessageBubble({required this.text, required this.isUser, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Tutor avatar (left side, tutor messages only)
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/StemSproutLogoFinal.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
          // Message bubble
          Flexible(
            child: DecoratedBox(
              decoration: BoxDecoration(color: bg, borderRadius: radius),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: isLoading ?
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ) : Text(text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
