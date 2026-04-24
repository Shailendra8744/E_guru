import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/auth_store.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

final doubtMessagesProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, doubtId) async {
      final api = ref.watch(apiClientProvider);
      final response = await api.get('/doubts/$doubtId/messages');
      if (response['items'] is List) {
        return response['items'] as List<dynamic>;
      }
      return [];
    });

class DoubtChatPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> doubt;

  const DoubtChatPage({super.key, required this.doubt});

  @override
  ConsumerState<DoubtChatPage> createState() => _DoubtChatPageState();
}

class _DoubtChatPageState extends ConsumerState<DoubtChatPage> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasRated = false;

  Future<void> _submitRating(int stars) async {
    try {
      await ref.read(apiClientProvider).post(
        '/student/doubts/${widget.doubt['id']}/rate',
        {'rating': stars, 'feedback': 'Rated via App UI'},
      );
      setState(() => _hasRated = true);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully!')),
        );
    } catch (e) {
      setState(
        () => _hasRated = true,
      ); // hide it even if error (e.g. already rated)
    }
  }

  Future<void> _sendMessage({String? imagePath}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imagePath == null) return;

    setState(() => _isSending = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/doubts/${widget.doubt['id']}/messages', {
        if (text.isNotEmpty) 'message_text': text,
        if (imagePath != null) 'image_path': imagePath,
      });
      _messageController.clear();
      ref.invalidate(doubtMessagesProvider(widget.doubt['id'] as int));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() => _isSending = true);
      try {
        final token = ref.read(authSessionProvider).value?.accessToken ?? '';
        final baseUrl = ref.read(apiClientProvider).baseUrl;

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/uploads/chat-image'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(
          await http.MultipartFile.fromPath('file', result.path),
        );

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          if (data['path'] != null) {
            await _sendMessage(imagePath: data['path']);
          }
        } else {
          throw Exception('Upload failed: ${response.body}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    }
  }

  Future<void> _resolveDoubt() async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/teacher/doubts/${widget.doubt['id']}/resolve', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doubt resolved seamlessly!')),
        );
        Navigator.pop(context, true); // Return true to refresh parent
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to resolve: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userRole = ref.watch(authSessionProvider).value?.role;
    final isResolved =
        widget.doubt['status'] == 'resolved' ||
        widget.doubt['status'] == 'closed';
    final currentUserId = ref.watch(authSessionProvider).value?.id ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doubt['title'] ?? 'Doubt Discussion'),
        actions: [
          if (!isResolved &&
              ref.watch(authSessionProvider).value?.role == 'teacher')
            TextButton.icon(
              onPressed: _resolveDoubt,
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              label: const Text(
                'Resolve',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original Question',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.doubt['description'] ?? 'No description',
                  style: theme.textTheme.bodyMedium,
                ),
                if (widget.doubt['image_path'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Has attachment',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ref
                .watch(doubtMessagesProvider(widget.doubt['id'] as int))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Error loading messages: $err')),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('No messages yet. Send a reply!'),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender_id'] == currentUserId;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: isMe
                                    ? const Radius.circular(4)
                                    : const Radius.circular(16),
                                bottomLeft: !isMe
                                    ? const Radius.circular(4)
                                    : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (msg['image_path'] != null &&
                                    msg['image_path'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.attachment, size: 16),
                                          SizedBox(width: 8),
                                          Text('Image Attachment'),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (msg['message_text'] != null &&
                                    msg['message_text'].toString().isNotEmpty)
                                  Text(
                                    msg['message_text'],
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isMe
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['sent_at'] != null
                                      ? DateFormat('HH:mm').format(
                                          DateTime.parse(
                                            msg['sent_at'],
                                          ).toLocal(),
                                        )
                                      : '',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isMe
                                        ? theme.colorScheme.onPrimaryContainer
                                              .withOpacity(0.6)
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
          if (!isResolved)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: _isSending ? null : _pickAndUploadImage,
                      color: theme.colorScheme.primary,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your reply...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      elevation: 0,
                      onPressed: _isSending ? null : _sendMessage,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          if (isResolved && userRole == 'student' && !_hasRated)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surfaceContainerHighest,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Rate your experience with this Teacher',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          icon: const Icon(
                            Icons.star,
                            size: 36,
                            color: Colors.blueGrey,
                          ),
                          onPressed: () => _submitRating(index + 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
