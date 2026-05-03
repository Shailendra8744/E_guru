import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:e_guru/core/auth_store.dart';

final studentMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return await api.get('/student/metrics');
});

class StudentAnalyticsPage extends ConsumerWidget {
  const StudentAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final metricsAsync = ref.watch(studentMetricsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0D1B2A) : theme.colorScheme.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Learning Journey', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF0D1B2A), const Color(0xFF1B263B)]
                      : [theme.colorScheme.primary, const Color(0xFF5C6BC0)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => ref.refresh(studentMetricsProvider),
              ),
            ],
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: metricsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) => _buildContent(context, data, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data, bool isDark) {
    final avgScore = (data['average_score'] as num?)?.toDouble() ?? 0.0;
    final totalActivities = (data['total_activities'] as num?)?.toInt() ?? 0;
    final recentActivities = data['recent_activities'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Performance', '${avgScore.toInt()}%', Icons.auto_awesome_rounded, Colors.amber, isDark)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Activities', totalActivities.toString(), Icons.rocket_launch_rounded, Colors.blue, isDark)),
            ],
          ),
          const SizedBox(height: 24),
          _buildPremiumChartCard(avgScore, recentActivities, isDark),
          const SizedBox(height: 24),
          const Text(
            'Recent Milestones',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          if (recentActivities.isEmpty)
            _buildEmptyState(isDark)
          else
            ...recentActivities.take(5).map((a) => _buildActivityTile(a, isDark)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(30)),
        boxShadow: isDark ? [] : [BoxShadow(color: color.withAlpha(10), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPremiumChartCard(double avgScore, List recent, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1B263B), const Color(0xFF0D1B2A)]
            : [Colors.white, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.blue.withAlpha(isDark ? 30 : 50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Score Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Last 5 quiz attempts', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Text('${avgScore.toInt()}% Avg', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: recent.take(5).toList().asMap().entries.map((e) {
                  final score = (e.value['score'] as num?)?.toDouble() ?? 0.0;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: score,
                        color: score > 70 ? Colors.green : (score > 40 ? Colors.orange : Colors.red),
                        width: 16,
                        borderRadius: BorderRadius.circular(8),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: isDark ? Colors.white10 : Colors.black.withAlpha(5)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(dynamic activity, bool isDark) {
    final type = activity['type']?.toString().toUpperCase() ?? 'QUIZ';
    final score = (activity['score'] as num?)?.toDouble();
    final date = activity['created_at'] != null ? DateTime.parse(activity['created_at'].toString()) : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withAlpha(isDark ? 20 : 50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withAlpha(20), shape: BoxShape.circle),
            child: const Icon(Icons.star_rounded, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: score > 70 ? Colors.green.withAlpha(20) : Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${score.toInt()}%', style: TextStyle(color: score > 70 ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.auto_graph_rounded, size: 64, color: isDark ? Colors.white12 : Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No data yet. Keep learning!', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
