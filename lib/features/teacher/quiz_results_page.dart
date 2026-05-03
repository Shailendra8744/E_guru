import 'package:e_guru/core/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';

final quizResultsProvider =
    FutureProvider.family<List<dynamic>, ({int quizId, bool isAdmin})>((
      ref,
      arg,
    ) async {
      final api = ref.read(apiClientProvider);
      final endpoint = arg.isAdmin
          ? '/admin/quizzes/${arg.quizId}/results'
          : '/teacher/quizzes/${arg.quizId}/results';
      final res = await api.get(endpoint);
      return (res['items'] as List<dynamic>?) ?? [];
    });

final questionStatsProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  quizId,
) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/teacher/quizzes/$quizId/question-stats');
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
    final resultsAsync = ref.watch(
      quizResultsProvider((quizId: quizId, isAdmin: isAdmin)),
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statsAsync = ref.watch(questionStatsProvider(quizId));

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Participation'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _downloadReport(context, ref),
            tooltip: 'Download CSV Report',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
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
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _downloadReport(context, ref),
                      icon: const Icon(Icons.file_download, size: 18),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Question Struggle Heatmap/Chart ──
                const Text(
                  'Question Performance (Failure Rate)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: statsAsync.when(
                    data: (stats) =>
                        _QuestionPerformanceChart(stats: stats, isDark: isDark),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Error loading stats: $e')),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Student Performance History',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHigh
                          : Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _getScoreColor(
                            percent,
                          ).withOpacity(0.1),
                          child: Text(
                            res['student_name']?[0]?.toUpperCase() ?? 'S',
                            style: TextStyle(
                              color: _getScoreColor(percent),
                              fontWeight: FontWeight.bold,
                            ),
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

  Future<void> _downloadReport(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiClientProvider);
    final session = ref.read(authSessionProvider).value;
    final token = session?.accessToken ?? '';
    final url = Uri.parse(
      '${api.baseUrl}/teacher/quizzes/$quizId/report/download?token=$token',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening report download...')),
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch download URL')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _QuestionPerformanceChart extends StatelessWidget {
  final List<dynamic> stats;
  final bool isDark;

  const _QuestionPerformanceChart({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty)
      return const Center(child: Text('No question data available'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark ? Colors.blueGrey : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final q = stats[group.x.toInt()];
              return BarTooltipItem(
                'Q${group.x + 1}\nFailure: ${rod.toY}%\n${q['correct_count']}/${q['total_count']} Correct',
                const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  'Q${value.toInt() + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: stats.asMap().entries.map((e) {
          final failRate =
              (double.tryParse(e.value['fail_rate'].toString()) ?? 0)
                  .toDouble();
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: failRate,
                color: failRate > 70
                    ? Colors.redAccent
                    : (failRate > 40 ? Colors.orangeAccent : Colors.blueAccent),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
