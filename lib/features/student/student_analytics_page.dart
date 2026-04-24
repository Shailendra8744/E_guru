import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:e_guru/core/auth_store.dart';

// Provider to fetch student dashboard metrics
final studentMetricsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final api = ref.watch(apiClientProvider);
  return await api.get('/student/metrics');
});

class StudentAnalyticsPage extends ConsumerWidget {
  const StudentAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(studentMetricsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Learning Progress',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(studentMetricsProvider),
          ),
        ],
      ),
      body: metricsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
        data: (data) {
          // Fallback UI data if API is returning empty or hasn't updated yet.
          final avgScore = (data['average_score'] as num?)?.toDouble() ?? 0.0;
          final totalActivities = (data['total_activities'] as int?) ?? 0;
          final recentActivities = data['recent_activities'] as List? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Avg. Score',
                        '${avgScore.toStringAsFixed(1)}%',
                        Icons.analytics,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Activities',
                        totalActivities.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildScoreChart(avgScore),
                const SizedBox(height: 24),
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (recentActivities.isEmpty)
                  _buildEmptyState()
                else
                  _buildActivityList(recentActivities),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChart(double avgScore) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Quiz Performance Overview',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.deepPurple,
                    value: avgScore,
                    title: '${avgScore.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (100 - avgScore > 0)
                    PieChartSectionData(
                      color: Colors.grey[200]!,
                      value: 100 - avgScore,
                      title: '',
                      radius: 50,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your average score across all quizzes',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List activities) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length > 5 ? 5 : activities.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final progress = activities[index];
        final type = progress['type'] ?? 'activity';
        final title = type.toString().replaceAll('_', ' ').toUpperCase();
        final score = (progress['score'] as num?)?.toDouble();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.deepPurple.withOpacity(0.1),
            child: const Icon(Icons.star, color: Colors.deepPurple, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: progress['created_at'] != null
              ? Text(
                  DateFormat(
                    'MMM dd, yyyy',
                  ).format(DateTime.parse(progress['created_at'].toString())),
                )
              : null,
          trailing: score != null
              ? Text(
                  '${score.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No recent activity',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
