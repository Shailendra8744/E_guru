import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/core/theme_provider.dart';
import 'package:e_guru/features/admin/admin_analytics_page.dart';
import 'package:e_guru/features/admin/user_management_page.dart';
import 'package:e_guru/features/admin/subjects_page.dart';
import 'package:e_guru/features/admin/admin_notes_page.dart';
import 'package:e_guru/features/admin/admin_quizzes_page.dart';
import 'package:e_guru/features/admin/teacher_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  List<dynamic> pendingTeachers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).get('/admin/teachers/pending');
      if (!mounted) return;
      setState(() => pendingTeachers = res['items'] as List<dynamic>);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pending teachers: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _takeAction(int id, String action) async {
    try {
      await ref.read(apiClientProvider).post('/admin/teachers/$id/$action', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Teacher ${action}d successfully')),
        );
      }
      await _loadPending();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $action teacher: $e')),
        );
      }
    }
  }



  @override
  void dispose() {
    super.dispose();
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
        onRefresh: _loadPending,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── HEADER ───
            SliverToBoxAdapter(child: _buildHeader(theme, isDark)),
            // ─── QUICK ACTIONS ───
            SliverToBoxAdapter(child: _buildQuickActions(theme, isDark)),
            // ─── PENDING TEACHERS ───
            SliverToBoxAdapter(child: _buildPendingHeader(theme, isDark)),
            _buildPendingList(theme, isDark),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ─── GRADIENT HEADER ───
  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
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
              : [const Color(0xFF303F9F), theme.colorScheme.primary, const Color(0xFF5C6BC0)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(isDark ? 20 : 50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 24),
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
                      'Admin Console',
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
              const SizedBox(width: 6),
              // Theme toggle
              _AdminHeaderIcon(
                icon:
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                onTap: _toggleTheme,
                animate: true,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              // Analytics
              _AdminHeaderIcon(
                icon: Icons.analytics_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const AdminAnalyticsPage()),
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              // Logout
              _AdminHeaderIcon(
                icon: Icons.logout_rounded,
                onTap: () =>
                    ref.read(authSessionProvider.notifier).logout(),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded,
                    color: Colors.white.withAlpha(180), size: 14),
                const SizedBox(width: 8),
                Text(
                  'Manage users, subjects & platform activity',
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
    );
  }

  // ─── QUICK ACTIONS ───
  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    final actions = [
      _QuickAction(
        icon: Icons.school_rounded,
        label: 'Teachers',
        color: const Color(0xFF00897B),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => const TeacherManagementPage()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.book_rounded,
        label: 'Subjects',
        color: const Color(0xFF7E57C2),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SubjectsPage()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.monitor_rounded,
        label: 'Monitor',
        color: const Color(0xFF26A69A),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => const AdminAnalyticsPage()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.quiz_rounded,
        label: 'Quizzes',
        color: const Color(0xFFFFA000),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => const AdminQuizzesPage()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.description_rounded,
        label: 'Notes',
        color: const Color(0xFFEC407A),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => const AdminNotesPage()),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: actions.map((a) => _QuickActionCard(data: a, isDark: isDark)).toList(),
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

  // ─── PENDING HEADER ───
  Widget _buildPendingHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildSectionTitle(
                'Pending Teachers', Icons.pending_actions_rounded, theme, isDark),
          ),
          if (pendingTeachers.isNotEmpty)
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
                '${pendingTeachers.length} pending',
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

  // ─── PENDING LIST ───
  Widget _buildPendingList(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (pendingTeachers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.shade900.withAlpha(40)
                      : Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline_rounded,
                    size: 44, color: Colors.green.shade400),
              ),
              const SizedBox(height: 18),
              Text(
                'All caught up!',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No pending teacher approvals.',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13),
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
            final t = pendingTeachers[index];
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
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHigh
                        : Colors.white,
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withAlpha(isDark ? 40 : 20),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                (t['full_name'] as String).isNotEmpty
                                    ? (t['full_name'] as String)
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['full_name'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: isDark
                                        ? Colors.grey.shade200
                                        : Colors.grey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t['email'] as String,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _takeAction(t['id'] as int, 'reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade400,
                                side: BorderSide(
                                    color: isDark
                                        ? Colors.red.shade800
                                        : Colors.red.shade200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Reject',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  _takeAction(t['id'] as int, 'approve'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green.shade500,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Approve',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: pendingTeachers.length,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════

class _AdminHeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool animate;
  final bool isDark;

  const _AdminHeaderIcon({
    required this.icon,
    required this.onTap,
    this.animate = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final child = Icon(
      icon,
      key: ValueKey(icon),
      color: Colors.white.withAlpha(210),
      size: 20,
    );

    return Material(
      color: Colors.white.withAlpha(30),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: animate
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      RotationTransition(turns: anim, child: child),
                  child: child,
                )
              : child,
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatefulWidget {
  final _QuickAction data;
  final bool isDark;

  const _QuickActionCard({required this.data, required this.isDark});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.data.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.data.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.data.color.withAlpha(70),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(widget.data.icon, color: Colors.white, size: 22),
              const SizedBox(height: 8),
              Text(
                widget.data.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
