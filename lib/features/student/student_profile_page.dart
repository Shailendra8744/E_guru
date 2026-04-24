import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/features/student/my_doubts_page.dart';
import 'package:e_guru/features/student/my_quiz_history_page.dart';
import 'package:e_guru/features/student/student_analytics_page.dart';

class StudentProfilePage extends ConsumerWidget {
  final List<dynamic> quizzes;
  final List<dynamic> quizInsights;

  const StudentProfilePage({
    super.key,
    required this.quizzes,
    required this.quizInsights,
  });

  String _formatPercent(dynamic v) {
    if (v == null) return '—';
    final n = v is num ? v.toDouble() : double.tryParse(v.toString());
    return n != null ? n.toStringAsFixed(1) : '—';
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider).value;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Student',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ID: #${user?.id ?? 0} | Student',
              style: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Analysis Section
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Performance Analytics',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ref.watch(studentMetricsProvider).when(
                      data: (metrics) => _buildStatCard(
                        context,
                        'My XP',
                        (metrics['xp'] ?? 0).toString(),
                        Icons.stars_rounded,
                        Colors.purple,
                      ),
                      loading: () => _buildStatCard(
                        context,
                        'My XP',
                        '...',
                        Icons.stars_rounded,
                        Colors.purple,
                      ),
                      error: (_, __) => _buildStatCard(
                        context,
                        'My XP',
                        '0',
                        Icons.stars_rounded,
                        Colors.purple,
                      ),
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                    context, 'Total Quizzes', quizzes.length.toString(), Icons.quiz, Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Avg. Score',
                  quizInsights.isNotEmpty
                      ? '${_formatPercent(quizInsights.first['avg_percent'])}%'
                      : '0%',
                  Icons.analytics,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ref.watch(studentDoubtsProvider).when(
                      data: (doubts) => _buildStatCard(context, 'Total Doubts',
                          doubts.length.toString(), Icons.help, Colors.orange),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _buildStatCard(
                          context, 'Total Doubts', '-', Icons.help, Colors.orange),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // All Doubt History Option
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history_edu, color: theme.colorScheme.onPrimaryContainer),
              ),
              title: const Text('All Doubt History', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('View your asked doubts and status.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyDoubtsPage()));
              },
            ),
          ),
          const SizedBox(height: 12),

          // Quiz History Option
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.quiz, color: Colors.blue.shade700),
              ),
              title: const Text('My Quiz History', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Review your previous scores and attempts.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyQuizHistoryPage()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
