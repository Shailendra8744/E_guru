import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/core/quiz_store.dart';
import 'package:e_guru/features/student/quiz_analysis_page.dart';

final studentQuizHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/student/quiz-history');
  return (res['items'] as List<dynamic>?) ?? [];
});

class MyQuizHistoryPage extends ConsumerWidget {
  const MyQuizHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(studentQuizHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Quiz History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No quizzes taken yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final score = (item['score'] as num).toInt();
              final total = (item['total_marks'] as num).toInt();
              final percentage = total > 0 ? (score / total * 100).round() : 0;
              
              final date = DateTime.parse(item['submitted_at']);
              final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);

              final answersRaw = item['answers'];
              final Map<int, String> decodedAnswers = {};
              if (answersRaw != null && answersRaw is Map) {
                answersRaw.forEach((k, v) {
                  final qid = int.tryParse(k.toString());
                  if (qid != null) decodedAnswers[qid] = v.toString();
                });
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    // Show loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Loading quiz analysis...'), duration: Duration(seconds: 1)),
                    );
                    
                    try {
                      final quiz = await ref.read(quizDetailsProvider(item['quiz_id'] as int).future);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizAnalysisPage(
                            quiz: quiz,
                            answers: decodedAnswers,
                            score: score,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error loading analysis: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.assignment, color: theme.colorScheme.onPrimaryContainer, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['quiz_title'] ?? 'Quiz',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    item['subject_name'] ?? 'General',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: percentage >= 70 ? Colors.green.shade50 : (percentage >= 40 ? Colors.orange.shade50 : Colors.red.shade50),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: percentage >= 70 ? Colors.green : (percentage >= 40 ? Colors.orange : Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Score', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text('$score / $total', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Submitted On', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Tap to review →',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
