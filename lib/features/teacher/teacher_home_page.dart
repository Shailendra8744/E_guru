import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/core/theme_provider.dart';
import 'package:e_guru/features/teacher/create_quiz_page.dart';
import 'package:e_guru/features/teacher/quiz_history_page.dart';
import 'package:e_guru/features/teacher/upload_note_page.dart';
import 'package:e_guru/features/teacher/doubt_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeacherHomePage extends ConsumerStatefulWidget {
  const TeacherHomePage({super.key});

  @override
  ConsumerState<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends ConsumerState<TeacherHomePage>
    with SingleTickerProviderStateMixin {
  List<dynamic> doubts = [];
  Map<String, dynamic>? metrics;
  bool _isLoading = false;
  String? _metricsError;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _metricsError = null;
    });
    final api = ref.read(apiClientProvider);

    try {
      final res = await api.get('/teacher/doubts', {
        'page': '1',
        'per_page': '50',
      });
      if (mounted) {
        setState(() {
          doubts = res['items'] as List<dynamic>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load doubts: $e')),
        );
      }
    }

    try {
      final m = await api.get('/teacher/metrics');
      if (mounted) {
        setState(() {
          metrics = m;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _metricsError = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load metrics: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _toggleTheme() {
    final current = ref.read(themeModeProvider);
    ref.read(themeModeProvider.notifier).state =
        current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? theme.colorScheme.surface : const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(theme, isDark)),
            SliverToBoxAdapter(child: _buildQuickActions(theme, isDark)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _ActionCard(
                  key: const Key('btn_quiz_history'),
                  icon: Icons.history_edu_rounded,
                  label: 'Quiz History & Participation',
                  color: isDark ? const Color(0xFF4895EF) : const Color(0xFF4361EE),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuizHistoryPage()),
                    );
                  },
                ),
              ),
            ),
            if (_metricsError != null)
              SliverToBoxAdapter(child: _buildMetricsError(isDark)),
            if (metrics != null)
              SliverToBoxAdapter(child: _buildMetrics(theme, isDark)),
            SliverToBoxAdapter(child: _buildDoubtsHeader(theme, isDark)),
            _buildDoubtsList(theme, isDark),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ─── GRADIENT HEADER ───
  Widget _buildHeader(ThemeData theme, bool isDark) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.of(context).padding.top + 16,
          24,
          24,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1040), const Color(0xFF2D1B69), const Color(0xFF16213E)]
                : [theme.colorScheme.primary, const Color(0xFF5C6BC0), const Color(0xFF7E57C2)],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha(isDark ? 30 : 60),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar + greeting
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: TextStyle(
                                color: Colors.white.withAlpha(190),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Teacher Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // ─── THEME TOGGLE ───
                Material(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: _toggleTheme,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            RotationTransition(turns: anim, child: child),
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          key: ValueKey(isDark),
                          color: Colors.white.withAlpha(210),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ─── LOGOUT ───
                Material(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () =>
                        ref.read(authSessionProvider.notifier).logout(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.white.withAlpha(210),
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: Colors.white.withAlpha(180), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Manage classes, doubts & quizzes',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── QUICK ACTIONS ───
  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              key: const Key('btn_upload_note'),
              icon: Icons.upload_file_rounded,
              label: 'Upload Note',
              color: theme.colorScheme.primary,
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (_) => const UploadNotePage()))
                    .then((_) => _load());
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              key: const Key('btn_create_quiz'),
              icon: Icons.quiz_rounded,
              label: 'Create Quiz',
              color: isDark ? const Color(0xFF9D4EDD) : const Color(0xFF7E57C2),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (_) => const CreateQuizPage()))
                    .then((_) => _load());
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── METRICS ERROR ───
  Widget _buildMetricsError(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.red.shade900.withAlpha(60) : Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.red.shade800.withAlpha(80) : Colors.red.shade100,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: isDark ? Colors.red.shade300 : Colors.red.shade400,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Could not load metrics',
                style: TextStyle(
                  color: isDark ? Colors.red.shade200 : Colors.red.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── METRICS GRID ───
  Widget _buildMetrics(ThemeData theme, bool isDark) {
    final items = [
      _MetricItem(
        title: 'Avg Rating',
        value: '${metrics!['avg_rating']}',
        icon: Icons.star_rounded,
        iconColor: const Color(0xFFFFA726),
        bgLight: const Color(0xFFFFF3E0),
        bgDark: const Color(0xFF2A2312),
      ),
      _MetricItem(
        title: 'Active Doubts',
        value: '${metrics!['active_doubts']}',
        icon: Icons.pending_actions_rounded,
        iconColor: const Color(0xFFEF5350),
        bgLight: const Color(0xFFFFEBEE),
        bgDark: const Color(0xFF2A1212),
      ),
      _MetricItem(
        title: 'Resolved',
        value: '${metrics!['resolved_doubts']}',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF66BB6A),
        bgLight: const Color(0xFFE8F5E9),
        bgDark: const Color(0xFF122A1C),
      ),
      _MetricItem(
        title: 'Avg Reply',
        value: '${metrics!['avg_first_reply_seconds']}s',
        icon: Icons.timer_rounded,
        iconColor: const Color(0xFF42A5F5),
        bgLight: const Color(0xFFE3F2FD),
        bgDark: const Color(0xFF0F1F2A),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Performance', Icons.insights_rounded, theme, isDark),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 12) / 2;
              const cardHeight = 110.0;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items.asMap().entries.map((entry) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 500 + (entry.key * 120)),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return Opacity(
                        opacity: val,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - val)),
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _MetricCard(data: entry.value, isDark: isDark),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── SECTION TITLE ───
  Widget _buildSectionTitle(
      String title, IconData icon, ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(isDark ? 40 : 20),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ─── DOUBTS HEADER ───
  Widget _buildDoubtsHeader(ThemeData theme, bool isDark) {
    final pendingCount =
        doubts.where((d) => d['status'] != 'resolved').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildSectionTitle(
                'Assigned Doubts', Icons.question_answer_rounded, theme, isDark),
          ),
          if (pendingCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.shade900.withAlpha(60)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.orange.shade700.withAlpha(60)
                      : Colors.orange.shade200,
                ),
              ),
              child: Text(
                '$pendingCount pending',
                style: TextStyle(
                  color: isDark
                      ? Colors.orange.shade300
                      : Colors.orange.shade800,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── DOUBTS LIST ───
  Widget _buildDoubtsList(ThemeData theme, bool isDark) {
    if (_isLoading && doubts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (doubts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inbox_rounded,
                    size: 44,
                    color:
                        isDark ? Colors.grey.shade500 : Colors.grey.shade400),
              ),
              const SizedBox(height: 18),
              Text(
                'No doubts assigned',
                style: TextStyle(
                  color:
                      isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You have resolved all your doubts!',
                style: TextStyle(
                    color: isDark
                        ? Colors.grey.shade500
                        : Colors.grey.shade500,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final d = doubts[index];
            final isResolved = d['status'] == 'resolved';

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + (index * 60)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHigh
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      final shouldRefresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DoubtChatPage(doubt: d)),
                      );
                      if (shouldRefresh == true) {
                        _load();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isResolved
                              ? (isDark
                                  ? Colors.green.shade800.withAlpha(80)
                                  : Colors.green.shade100)
                              : (isDark
                                  ? Colors.grey.shade700.withAlpha(60)
                                  : Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isResolved
                                      ? Colors.green.shade400
                                      : Colors.orange.shade400,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  d['title'] as String? ?? 'Untitled Doubt',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade100
                                        : Colors.grey.shade900,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isResolved
                                      ? (isDark
                                          ? Colors.green.shade900
                                              .withAlpha(70)
                                          : Colors.green.shade50)
                                      : (isDark
                                          ? Colors.orange.shade900
                                              .withAlpha(70)
                                          : Colors.orange.shade50),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (d['status'] as String).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: isResolved
                                        ? (isDark
                                            ? Colors.green.shade300
                                            : Colors.green.shade700)
                                        : (isDark
                                            ? Colors.orange.shade300
                                            : Colors.orange.shade700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.person_outline_rounded,
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade400,
                                        size: 14),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        '${d['student_name'] ?? 'Student'}',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade500,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '#${d['id']}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade600
                                            : Colors.grey.shade400,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.primary.withAlpha(isDark ? 35 : 18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Reply',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 12,
                                        color: theme.colorScheme.primary),
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
            );
          },
          childCount: doubts.length,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════

class _MetricItem {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgLight;
  final Color bgDark;

  const _MetricItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgLight,
    required this.bgDark,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricItem data;
  final bool isDark;

  const _MetricCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey.shade800.withAlpha(60) : Colors.grey.shade100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? data.bgDark : data.bgLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.title,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(70),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 19),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
