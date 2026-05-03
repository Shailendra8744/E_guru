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

  static const List<String> avatars = [
    '👨‍🎓', '👩‍🎓', '🧑‍💻', '🧠', '🚀', '📚', '🏆', '🌟', '🎨', '🧪'
  ];

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
          // Profile Avatar with Selection
          Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: theme.colorScheme.primary.withAlpha(20),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    avatars[ref.watch(userAvatarProvider)],
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showAvatarPicker(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
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
          // Overall Performance Card
          ref.watch(studentMetricsProvider).when(
            data: (m) {
              final avgScore = (m['average_score'] as num?)?.toDouble() ?? 0.0;
              final isDark = theme.brightness == Brightness.dark;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [Colors.white, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.blue.withAlpha(30) : Colors.blue.withAlpha(20)),
                  boxShadow: isDark ? null : [
                    BoxShadow(color: Colors.blue.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 70,
                      width: 70,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: avgScore / 100,
                            backgroundColor: isDark ? Colors.white10 : Colors.blue.withAlpha(20),
                            color: Colors.blue,
                            strokeWidth: 8,
                          ),
                          Center(
                            child: Text(
                              '${avgScore.toInt()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Performance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your average score across all quizzes. Keep it up!',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAnalyticsPage())),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('View Detailed Analytics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: theme.colorScheme.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
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

  void _showAvatarPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Your Avatar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final isSelected = ref.watch(userAvatarProvider) == index;
                  return GestureDetector(
                    onTap: () {
                      ref.read(userAvatarProvider.notifier).setAvatar(index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(30) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withAlpha(30),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(avatars[index], style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
