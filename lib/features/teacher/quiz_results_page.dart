import 'package:e_guru/core/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quizResultsProvider =
    FutureProvider.family<List<dynamic>, ({int quizId, bool isAdmin})>(
        (ref, arg) async {
  final api = ref.read(apiClientProvider);
  final endpoint = arg.isAdmin
      ? '/admin/quizzes/${arg.quizId}/results'
      : '/teacher/quizzes/${arg.quizId}/results';
  final res = await api.get(endpoint);
  return (res['items'] as List<dynamic>?) ?? [];
});

class QuizResultsPage extends ConsumerWidget {
  final int quizId;
  final String quizTitle;
  final String? creatorName;
  final bool isAdmin;

  const QuizResultsPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
    this.creatorName,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync =
        ref.watch(quizResultsProvider((quizId: quizId, isAdmin: isAdmin)));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Participation'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quizTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (creatorName != null)
                  Text(
                    'Created by: $creatorName',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  'Student Performance History',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: resultsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('No students have attempted this quiz yet.'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final res = items[index];
                    final score = res['score'] ?? 0;
                    final total = res['total_marks'] ?? 0;
                    final percent = total > 0 ? (score / total) : 0.0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: _getScoreColor(percent).withOpacity(0.1),
                          child: Text(
                            res['student_name']?[0]?.toUpperCase() ?? 'S',
                            style: TextStyle(color: _getScoreColor(percent), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          res['student_name'] ?? 'Unknown Student',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(res['student_email'] ?? ''),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$score / $total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(percent),
                              ),
                            ),
                            Text(
                              '${(percent * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percent) {
    if (percent >= 0.8) return Colors.green;
    if (percent >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
