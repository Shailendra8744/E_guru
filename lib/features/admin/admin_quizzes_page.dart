import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/features/teacher/create_quiz_page.dart';

class AdminQuizzesPage extends ConsumerStatefulWidget {
  const AdminQuizzesPage({super.key});

  @override
  ConsumerState<AdminQuizzesPage> createState() => _AdminQuizzesPageState();
}

class _AdminQuizzesPageState extends ConsumerState<AdminQuizzesPage> {
  List<dynamic> _quizzes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).get('/admin/quizzes');
      if (mounted) {
        setState(() {
          _quizzes = res['items'] as List<dynamic>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load quizzes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuiz(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this quiz? (Soft Delete)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(apiClientProvider).post('/admin/quizzes/$id/delete', {});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz deleted.')));
        _loadQuizzes();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Quiz Management', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _loadQuizzes,
        child: _isLoading && _quizzes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _quizzes.isEmpty
                ? const Center(child: Text('No quizzes found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = _quizzes[index];
                      final title = quiz['title'] ?? 'Untitled';
                      final id = quiz['id'];
                      final teacher = quiz['teacher_name'] ?? 'Unknown Teacher';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('By: $teacher | ID: #$id'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                                onPressed: () async {
                                  final quizId = int.tryParse(id.toString());
                                  if (quizId == null) return;
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateQuizPage(quizId: quizId),
                                    ),
                                  );
                                  if (result == true) _loadQuizzes();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                onPressed: () {
                                  final quizId = int.tryParse(id.toString());
                                  if (quizId != null) _deleteQuiz(quizId);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
