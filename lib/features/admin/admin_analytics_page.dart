import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/features/admin/user_management_page.dart';
import 'package:e_guru/features/teacher/quiz_results_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsPage extends ConsumerStatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  ConsumerState<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends ConsumerState<AdminAnalyticsPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? overview;
  Map<String, dynamic>? sla;
  List<dynamic> quizzes = [];
  List<dynamic> subjectPopularity = [];
  List<dynamic> platformProgress = [];
  String? error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      error = null;
      overview = null;
      sla = null;
      quizzes = [];
      subjectPopularity = [];
      platformProgress = [];
    });
    try {
      final api = ref.read(apiClientProvider);

      // Load everything in parallel
      final results = await Future.wait([
        api.get('/admin/analytics/overview'),
        api.get('/admin/analytics/doubts-sla'),
        api.get('/admin/analytics/quizzes', {'page': '1', 'per_page': '20'}),
        api.get('/admin/analytics/subject-popularity'),
        api.get('/admin/analytics/platform-progress'),
      ]);

      if (!mounted) return;
      setState(() {
        overview = results[0];
        sla = results[1];
        quizzes = results[2]['items'] as List<dynamic>;
        subjectPopularity = results[3]['items'] as List<dynamic>;
        platformProgress = results[4]['items'] as List<dynamic>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    }
  }

  // ─── HELPERS ───
  String _fmt(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      if (v == v.toInt()) return v.toInt().toString();
      return v.toStringAsFixed(1);
    }
    return v.toString();
  }

  Map<String, int> _parseUsersByRole(dynamic v) {
    if (v == null) return {};
    if (v is Map) {
      return v.map(
        (k, val) => MapEntry(k.toString(), int.tryParse(val.toString()) ?? 0),
      );
    }
    return {};
  }

  Map<String, int> _parseDoubtsByStatus(dynamic v) {
    if (v == null) return {};
    if (v is Map) {
      return v.map(
        (k, val) => MapEntry(k.toString(), int.tryParse(val.toString()) ?? 0),
      );
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScroll) => [
          // ─── GRADIENT APP BAR ───
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF1A1040)
                : const Color(0xFF303F9F),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _load,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1A1040),
                            const Color(0xFF2D1B69),
                            const Color(0xFF16213E),
                          ]
                        : [
                            const Color(0xFF303F9F),
                            theme.colorScheme.primary,
                            const Color(0xFF5C6BC0),
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 20, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.analytics_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Platform Analytics',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Monitor activity & performance',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(180),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: isDark
                    ? const Color(0xFF1A1040)
                    : const Color(0xFF303F9F),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withAlpha(140),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Doubts SLA'),
                    Tab(text: 'Quizzes'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _buildBody(theme, isDark),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                error!.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (overview == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(theme, isDark),
        _buildSlaTab(theme, isDark),
        _buildQuizzesTab(theme, isDark),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //  TAB 1: OVERVIEW
  // ═══════════════════════════════════════════════════
  Widget _buildOverviewTab(ThemeData theme, bool isDark) {
    final usersByRole = _parseUsersByRole(overview!['users_by_role']);
    final doubtsByStatus = _parseDoubtsByStatus(overview!['doubts_by_status']);
    final totalUsers =
        overview!['total_users'] ??
        usersByRole.values.fold<int>(0, (sum, v) => sum + v);
    final totalDoubts = doubtsByStatus.values.fold<int>(0, (sum, v) => sum + v);

    return RefreshIndicator(
      onRefresh: _load,
      color: theme.colorScheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── User stats row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel(
                title: 'Users',
                icon: Icons.people_rounded,
                isDark: isDark,
                theme: theme,
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UserManagementPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                label: const Text('Manage All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            children: [
              _StatMiniCard(
                label: 'Total Users',
                value: totalUsers.toString(),
                icon: Icons.group_rounded,
                color: const Color(0xFF5C6BC0),
                isDark: isDark,
                theme: theme,
              ),
              ...usersByRole.entries.map(
                (e) => _StatMiniCard(
                  label: _capitalize(e.key),
                  value: e.value.toString(),
                  icon: e.key == 'admin'
                      ? Icons.admin_panel_settings_rounded
                      : e.key == 'teacher'
                      ? Icons.school_rounded
                      : Icons.person_rounded,
                  color: e.key == 'admin'
                      ? const Color(0xFF7E57C2)
                      : e.key == 'teacher'
                      ? const Color(0xFF26A69A)
                      : const Color(0xFF42A5F5),
                  isDark: isDark,
                  theme: theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Subject Popularity Bar Chart ──
          _SectionLabel(
            title: 'Subject Popularity',
            icon: Icons.bar_chart_rounded,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _PopularityBarChart(
            data: subjectPopularity,
            isDark: isDark,
            theme: theme,
          ),

          const SizedBox(height: 28),

          // ── Platform Progress Line Chart ──
          _SectionLabel(
            title: 'Student Progress Trend',
            icon: Icons.trending_up_rounded,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _ProgressLineChart(
            data: platformProgress,
            isDark: isDark,
            theme: theme,
          ),

          const SizedBox(height: 28),

          // ── Quiz Attempts ──
          _SectionLabel(
            title: 'Quiz Performance',
            icon: Icons.quiz_rounded,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _InfoCard(
                    title: 'Total Attempts',
                    value: _fmt(overview!['quiz_attempts']),
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF66BB6A),
                    isDark: isDark,
                    theme: theme,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _InfoCard(
                    title: 'Avg Score Ratio',
                    value: '${_fmt(overview!['quiz_avg_score_ratio'])}%',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFFF7043),
                    isDark: isDark,
                    theme: theme,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Doubts ──
          _SectionLabel(
            title: 'Doubts',
            icon: Icons.support_agent_rounded,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _DoubtStatusBar(
            data: doubtsByStatus,
            total: totalDoubts,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _InfoCard(
                    title: 'Avg Resolve',
                    value:
                        '${_fmt(overview!['doubt_avg_resolve_minutes'])} min',
                    icon: Icons.timer_rounded,
                    color: const Color(0xFF26C6DA),
                    isDark: isDark,
                    theme: theme,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _InfoCard(
                    title: 'Avg 1st Reply',
                    value:
                        '${_fmt(overview!['doubt_avg_first_teacher_reply_seconds'])}s',
                    icon: Icons.reply_rounded,
                    color: const Color(0xFFAB47BC),
                    isDark: isDark,
                    theme: theme,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  TAB 2: DOUBTS SLA
  // ═══════════════════════════════════════════════════
  Widget _buildSlaTab(ThemeData theme, bool isDark) {
    if (sla == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    final pendingCount = sla!['pending_assignment_count'];
    final avgResolve = sla!['avg_resolve_minutes'];
    final avgFirstReply = sla!['avg_first_teacher_reply_seconds'];

    return RefreshIndicator(
      onRefresh: _load,
      color: theme.colorScheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── SLA status hero card ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1B2838), const Color(0xFF1A1040)]
                    : [const Color(0xFF5C6BC0), const Color(0xFF7E57C2)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color:
                      (isDark
                              ? const Color(0xFF5C6BC0)
                              : const Color(0xFF7E57C2))
                          .withAlpha(isDark ? 15 : 40),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Pending badge
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _fmt(pendingCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pending Assignment',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Doubts waiting to be assigned to a teacher',
                  style: TextStyle(
                    color: Colors.white.withAlpha(130),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── SLA metrics ──
          _SectionLabel(
            title: 'Response Metrics',
            icon: Icons.speed_rounded,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 12),

          _SlaMetricTile(
            title: 'Average Resolve Time',
            value: '${_fmt(avgResolve)} min',
            subtitle: 'Time from doubt creation to resolution',
            icon: Icons.timer_rounded,
            color: const Color(0xFF26A69A),
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _SlaMetricTile(
            title: 'Average First Reply',
            value: '${_fmt(avgFirstReply)} sec',
            subtitle: 'Time until teacher sends first response',
            icon: Icons.quickreply_rounded,
            color: const Color(0xFF5C6BC0),
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _SlaMetricTile(
            title: 'Pending Queue',
            value: _fmt(pendingCount),
            subtitle: 'Doubts not yet assigned to any teacher',
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFFF7043),
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  TAB 3: QUIZZES
  // ═══════════════════════════════════════════════════
  Widget _buildQuizzesTab(ThemeData theme, bool isDark) {
    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 56,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              'No quiz data available',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final q = quizzes[index];
          return _QuizAnalyticsCard(
            quiz: q,
            index: index,
            isDark: isDark,
            theme: theme,
          );
        },
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ═══════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════

// ─── SECTION LABEL ───
class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final ThemeData theme;

  const _SectionLabel({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(isDark ? 40 : 20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
          ),
        ),
      ],
    );
  }
}

// ─── SMALL STAT CARD ───
class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800.withAlpha(60)
              : Colors.grey.shade100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 30 : 18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── INFO CARD ───
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800.withAlpha(60)
              : Colors.grey.shade100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 30 : 18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DOUBT STATUS BAR (visual breakdown) ───
class _DoubtStatusBar extends StatelessWidget {
  final Map<String, int> data;
  final int total;
  final bool isDark;
  final ThemeData theme;

  const _DoubtStatusBar({
    required this.data,
    required this.total,
    required this.isDark,
    required this.theme,
  });

  static const _statusColors = {
    'open': Color(0xFF42A5F5),
    'pending': Color(0xFFFF9800),
    'assigned': Color(0xFF5C6BC0),
    'in_progress': Color(0xFF26A69A),
    'resolved': Color(0xFF66BB6A),
    'closed': Color(0xFF78909C),
  };

  Color _colorFor(String status) =>
      _statusColors[status] ?? const Color(0xFF90A4AE);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800.withAlpha(60)
              : Colors.grey.shade100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(isDark ? 30 : 15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Visual progress bar
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: data.entries.map((e) {
                    final pct = e.value / total;
                    return Expanded(
                      flex: (pct * 1000).round().clamp(1, 1000),
                      child: Container(color: _colorFor(e.key)),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 14),
          // Legend
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: data.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colorFor(e.key),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_capitalizeStatus(e.key)} (${e.value})',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _capitalizeStatus(String s) {
    return s
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

// ─── SLA METRIC TILE ───
class _SlaMetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  const _SlaMetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800.withAlpha(60)
              : Colors.grey.shade100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 30 : 18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 25 : 12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QUIZ ANALYTICS CARD ───
class _QuizAnalyticsCard extends StatelessWidget {
  final dynamic quiz;
  final int index;
  final bool isDark;
  final ThemeData theme;

  const _QuizAnalyticsCard({
    required this.quiz,
    required this.index,
    required this.isDark,
    required this.theme,
  });

  static const _accentColors = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFFFF7043),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accentColors[index % _accentColors.length];
    final title = quiz['title'] as String? ?? 'Untitled';
    final subject = quiz['subject_name'] as String? ?? '';
    final attempts = quiz['attempt_count'];
    final avgPercent = quiz['avg_percent'];
    final avgStr = avgPercent != null
        ? (avgPercent is num
              ? avgPercent.toStringAsFixed(1)
              : avgPercent.toString())
        : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.grey.shade800.withAlpha(60)
                : Colors.grey.shade100,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizResultsPage(
                  quizId: quiz['id'],
                  quizTitle: quiz['title'],
                  creatorName: quiz['teacher_name'],
                  isAdmin: true,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(isDark ? 30 : 18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.assignment_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade200
                              : Colors.grey.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Created by: ${quiz['teacher_name'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withAlpha(isDark ? 25 : 12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              subject,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_rounded,
                                size: 13,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${attempts ?? 0} attempts',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Avg %
                Column(
                  children: [
                    Text(
                      '$avgStr%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.grey.shade200
                            : Colors.grey.shade900,
                      ),
                    ),
                    Text(
                      'avg',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── POPULARITY BAR CHART ───
class _PopularityBarChart extends StatelessWidget {
  final List<dynamic> data;
  final bool isDark;
  final ThemeData theme;

  const _PopularityBarChart({
    required this.data,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('No data available')),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              data
                  .map(
                    (e) => (int.tryParse(e['attempt_count'].toString()) ?? 0),
                  )
                  .fold(0, (max, e) => e > max ? e : max)
                  .toDouble() *
              1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => isDark ? Colors.blueGrey : Colors.white,
              tooltipBorder: const BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    final name = data[index]['subject_name'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        name.length > 5 ? '${name.substring(0, 5)}..' : name,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (int.tryParse(e.value['attempt_count'].toString()) ?? 0)
                      .toDouble(),
                  color: theme.colorScheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── PROGRESS LINE CHART ───
class _ProgressLineChart extends StatelessWidget {
  final List<dynamic> data;
  final bool isDark;
  final ThemeData theme;

  const _ProgressLineChart({
    required this.data,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('No progress data yet')),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 8),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index % 5 == 0 && index >= 0 && index < data.length) {
                    final dateStr = data[index]['date'] ?? '';
                    if (dateStr.length >= 10) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          dateStr.substring(8, 10),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
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
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) {
                return FlSpot(
                  e.key.toDouble(),
                  (double.tryParse(e.value['avg_percent'].toString()) ?? 0)
                      .toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withAlpha(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
