import 'dart:async';
import 'dart:convert';

import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/core/theme_provider.dart';
import 'package:e_guru/features/student/pdf_reader_page.dart';
import 'package:e_guru/features/student/post_doubt_page.dart';
import 'package:e_guru/features/student/my_doubts_page.dart';
import 'package:e_guru/features/student/quiz_taking_page.dart';
import 'package:e_guru/features/student/quizzes_page.dart';
import 'package:e_guru/features/student/student_profile_page.dart';
import 'package:e_guru/features/student/all_notes_page.dart';
import 'package:e_guru/features/student/leaderboard_page.dart';
import 'package:e_guru/features/student/study_materials_page.dart';
import 'package:e_guru/features/student/ai_practice_page.dart';
import 'package:e_guru/features/student/student_analytics_page.dart';
import 'package:e_guru/features/student/my_quiz_history_page.dart';
import 'package:e_guru/features/teacher/doubt_chat_page.dart';
import 'package:e_guru/features/student/widgets/study_timer_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentHomePage extends ConsumerStatefulWidget {
  const StudentHomePage({super.key});

  @override
  ConsumerState<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends ConsumerState<StudentHomePage> {
  List<dynamic> notes = [];
  List<dynamic> quizzes = [];
  List<dynamic> quizInsights = [];
  Map<String, dynamic>? metrics;
  List<dynamic> leaderboard = [];

  // Local To-Do state
  List<Map<String, dynamic>> todos = [];
  final _todoController = TextEditingController();

  int _currentIndex = 0;
  int _streak = 0;
  String _quote = "Loading inspiration...";

  final List<String> _quotes = [
    "Education is the most powerful weapon which you can use to change the world.",
    "The beautiful thing about learning is that no one can take it away from you.",
    "The mind is not a vessel to be filled, but a fire to be kindled.",
    "Procrastination is the thief of time. - Charles Dickens",
    "Believe you can and you're halfway there. - Theodore Roosevelt",
    "Your education is a dress rehearsal for a life that is yours to lead.",
    "Success is not final, failure is not fatal: it is the courage to continue that counts.",
    "The expert in anything was once a beginner.",
    "Don't let what you cannot do interfere with what you can do.",
    "Learning never exhausts the mind. - Leonardo da Vinci",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTodos();
    _updateStreak();
    _quote = _quotes[DateTime.now().day % _quotes.length];
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpen = prefs.getString('last_open_date');
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    int currentStreak = prefs.getInt('student_streak') ?? 0;

    if (lastOpen == null) {
      currentStreak = 1;
    } else {
      try {
        final lastDate = DateTime.parse(lastOpen);
        final difference = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;

        if (difference == 1) {
          currentStreak++;
        } else if (difference > 1) {
          currentStreak = 1;
        }
      } catch (_) {
        currentStreak = 1;
      }
    }

    await prefs.setString('last_open_date', today);
    await prefs.setInt('student_streak', currentStreak);

    if (mounted) {
      setState(() {
        _streak = currentStreak;
      });
    }
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosJson = prefs.getString('student_todos');
    if (todosJson != null) {
      final List<dynamic> decoded = jsonDecode(todosJson);
      setState(() {
        todos = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final api = ref.read(apiClientProvider);
      final n = await api.get('/student/notes', {
        'page': '1',
        'per_page': '50',
      });
      final q = await api.get('/student/quizzes', {
        'page': '1',
        'per_page': '50',
      });
      final i = await api.get('/student/quiz-insights');
      final m = await api.get('/student/metrics');
      final l = await api.get('/leaderboard');

      if (!mounted) return;
      setState(() {
        notes = (n['items'] as List<dynamic>?) ?? [];
        quizzes = (q['quizzes'] as List<dynamic>?) ?? [];
        quizInsights = (i['items'] as List<dynamic>?) ?? [];
        metrics = m;
        leaderboard = (l['items'] as List<dynamic>?) ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  @override
  void dispose() {
    _todoController.dispose();
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
    ref.read(themeModeProvider.notifier).state = current == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? theme.colorScheme.surface
        : const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PostDoubtPage()),
                );
              },
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Post Doubt'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(theme, isDark),
          const QuizzesPage(showBackButton: false),
          StudentProfilePage(quizzes: quizzes, quizInsights: quizInsights),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : Colors.white,
        indicatorColor: theme.colorScheme.primary.withAlpha(30),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz_rounded),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(ThemeData theme, bool isDark) {
    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── HEADER ───
          SliverToBoxAdapter(child: _buildHeader(theme, isDark)),

          // ─── QUICK ACTIONS ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: _buildQuickActions(theme, isDark),
            ),
          ),

          // ─── STUDY TIMER ───
          SliverToBoxAdapter(child: StudyTimerCard(isDark: isDark)),

          // ─── STUDY MATERIALS ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildSectionTitle(
                      'Teacher Material',
                      Icons.assignment_ind_rounded,
                      theme,
                      isDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudyMaterialsPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildNotesCarousel(theme, isDark)),

          // ─── ALL NOTES (EXTERNAL) ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildSectionTitle(
                      'All Notes',
                      Icons.library_books_rounded,
                      theme,
                      isDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllNotesPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF2C3E50), const Color(0xFF000000)]
                        : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.deepPurple)
                          .withAlpha(40),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 100,
                        color: Colors.white.withAlpha(20),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.library_books_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'General Library',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                'Explore 1000+ curated study materials',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withAlpha(180),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AllNotesPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF764ba2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'EXPLORE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── QUIZZES ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildSectionTitle(
                      'Active Quizzes',
                      Icons.quiz_rounded,
                      theme,
                      isDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _currentIndex = 1);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildQuizCarousel(theme, isDark)),

          // ─── TO-DO ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: _buildSectionTitle(
                'My To-Do List',
                Icons.task_alt_rounded,
                theme,
                isDark,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildTodoCard(theme, isDark)),

          // ─── RECENT DOUBTS ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildSectionTitle(
                      'Recent Doubts',
                      Icons.history_rounded,
                      theme,
                      isDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyDoubtsPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildRecentDoubts(theme, isDark)),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ─── GRADIENT HEADER ───
  Widget _buildHeader(ThemeData theme, bool isDark) {
    final user = ref.watch(authSessionProvider).value;
    final userName = user?.name ?? 'Student';

    // Find user's XP and Rank from leaderboard
    int userXp = 0;
    int userRank = 0;
    if (leaderboard.isNotEmpty && user != null) {
      for (int i = 0; i < leaderboard.length; i++) {
        if (leaderboard[i]['id'] == user.id) {
          userXp = leaderboard[i]['xp'] ?? 0;
          userRank = i + 1;
          break;
        }
      }
    }

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
              ? [
                  const Color(0xFF0D1B2A),
                  const Color(0xFF1B2838),
                  const Color(0xFF1A1040),
                ]
              : [
                  theme.colorScheme.primary,
                  const Color(0xFF5C6BC0),
                  const Color(0xFF7E57C2),
                ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(isDark ? 40 : 80),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with Rank Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withAlpha(50),
                          Colors.white.withAlpha(10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withAlpha(60),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        [
                          '👨‍🎓',
                          '👩‍🎓',
                          '🧑‍💻',
                          '🧠',
                          '🚀',
                          '📚',
                          '🏆',
                          '🌟',
                          '🎨',
                          '🧪',
                        ][ref.watch(userAvatarProvider)],
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  if (userRank > 0)
                    Positioned(
                      bottom: -8,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Text(
                          '#$userRank',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _greeting(),
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (_streak > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(40),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.orange.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$_streak',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Header Actions
              Row(
                children: [
                  _HeaderIconButton(
                    icon: isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    onTap: _toggleTheme,
                    animateRotation: true,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _HeaderIconButton(
                    icon: Icons.logout_rounded,
                    onTap: () =>
                        ref.read(authSessionProvider.notifier).logout(),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          // XP & Level Status Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Next Level Progress',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$userXp / ${((userXp / 100).floor() + 1) * 100} XP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: (userXp % 100) / 100.0,
                              backgroundColor: Colors.white.withAlpha(40),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'LEVEL',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${(userXp / 100).floor() + 1}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _quote,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
      {
        'icon': Icons.auto_awesome_rounded,
        'label': 'Ask AI',
        'color': Colors.purple,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIPracticePage()),
        ),
      },
      {
        'icon': Icons.support_agent_rounded,
        'label': 'Doubt Box',
        'color': Colors.blue,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostDoubtPage()),
        ),
      },
      {
        'icon': Icons.emoji_events_rounded,
        'label': 'Rankings',
        'color': Colors.amber,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardPage()),
        ),
      },
      {
        'icon': Icons.history_rounded,
        'label': 'History',
        'color': Colors.teal,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyQuizHistoryPage()),
        ),
      },
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          final color = action['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(isDark ? 20 : 40),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: isDark ? const Color(0xFF1B263B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: action['onTap'] as VoidCallback,
                      splashColor: color.withAlpha(30),
                      highlightColor: color.withAlpha(10),
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: color.withAlpha(isDark ? 40 : 20),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: color,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  action['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── SECTION TITLE ───
  Widget _buildSectionTitle(
    String title,
    IconData icon,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(isDark ? 40 : 20),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1A1C1E),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Container(
                height: 3,
                width: 30,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCarousel(ThemeData theme, bool isDark) {
    if (notes.isEmpty) {
      return _buildEmptyHint('No study materials available', isDark);
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final n = notes[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        theme.colorScheme.surfaceContainerHigh,
                        theme.colorScheme.surface,
                      ]
                    : [Colors.white, theme.colorScheme.primary.withAlpha(10)],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(isDark ? 10 : 20),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.white.withAlpha(isDark ? 10 : 50),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  const String baseUrl =
                      "https://engineerfarm.in/backend/public";
                  final String relativePath = n['pdf_path'] as String;
                  final String normalizedRelative = relativePath.startsWith('/')
                      ? relativePath.substring(1)
                      : relativePath;
                  final List<String> pathSegments = normalizedRelative.split(
                    '/',
                  );
                  final String encodedRelativePath = pathSegments
                      .map((segment) => Uri.encodeComponent(segment))
                      .join('/');
                  final String fullUrl = "$baseUrl/$encodedRelativePath";

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PDFReaderPage(
                        title: n['title'] as String,
                        url: fullUrl,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        n['title'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.blue.shade900,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n['subject_name']?.toString() ?? 'Subject',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizCarousel(ThemeData theme, bool isDark) {
    if (quizzes.isEmpty) {
      return _buildEmptyHint('No quizzes available', isDark);
    }

    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final q = quizzes[index];
          final difficulty =
              q['difficulty']?.toString().toLowerCase() ?? 'moderate';
          final difficultyColor = difficulty == 'basic'
              ? Colors.green
              : (difficulty == 'high' ? Colors.red : Colors.orange);

          return Container(
            width: 280,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF16213E), const Color(0xFF0F3460)]
                    : [Colors.white, Colors.blue.shade50.withAlpha(100)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 10),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.blue.withAlpha(isDark ? 20 : 10),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizTakingPage(
                        quizId: q['id'] as int,
                        quizTitle: q['title'] as String,
                      ),
                    ),
                  ).then((_) => _loadData());
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              difficulty.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: difficultyColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            '${q['total_marks'] ?? 0} Marks',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        q['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.blue.shade900,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_pin_rounded,
                            size: 12,
                            color: theme.colorScheme.primary.withAlpha(150),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              q['teacher_name'] ?? 'By Teacher',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── TODO CARD ───
  Widget _buildTodoCard(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _todoController,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade200
                            : Colors.grey.shade900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a new task...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (v) => _addTodo(v),
                    ),
                  ),
                  Material(
                    color: theme.colorScheme.primary.withAlpha(
                      isDark ? 35 : 18,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _addTodo(_todoController.text),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.add_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (todos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No tasks yet. Add one to stay organized!',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final done = todos[index]['isCompleted'] as bool;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Checkbox(
                            value: done,
                            activeColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (v) {
                              setState(() => todos[index]['isCompleted'] = v);
                              _saveTodos();
                            },
                          ),
                          Expanded(
                            child: Text(
                              todos[index]['title'] as String,
                              style: TextStyle(
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: done
                                    ? (isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400)
                                    : (isDark
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade800),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() => todos.removeAt(index));
                                _saveTodos();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTodo(String v) {
    if (v.trim().isEmpty) return;
    setState(() {
      todos.add({'title': v.trim(), 'isCompleted': false});
    });
    _saveTodos();
    _todoController.clear();
  }

  void _saveTodos() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('student_todos', jsonEncode(todos));
    });
  }

  // ─── RECENT DOUBTS ───
  Widget _buildRecentDoubts(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ref
          .watch(studentDoubtsProvider)
          .when(
            data: (doubts) {
              if (doubts.isEmpty) {
                return _buildEmptyCard('No doubts posted yet.', isDark, theme);
              }
              final recent = doubts.take(3).toList();
              return Column(
                children: recent.map((d) {
                  final isResolved =
                      d['status'] == 'resolved' || d['status'] == 'closed';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHigh
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoubtChatPage(
                                doubt: d as Map<String, dynamic>,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800.withAlpha(60)
                                  : Colors.grey.shade100,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isResolved
                                      ? (isDark
                                            ? Colors.green.shade900.withAlpha(
                                                50,
                                              )
                                            : Colors.green.shade50)
                                      : (isDark
                                            ? Colors.orange.shade900.withAlpha(
                                                50,
                                              )
                                            : Colors.orange.shade50),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isResolved
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_rounded,
                                  color: isResolved
                                      ? Colors.green.shade400
                                      : Colors.orange.shade400,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d['title'] ?? 'Doubt',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          d['subject_name'] ??
                                              d['status'].toString().toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isResolved
                                                ? Colors.green.shade400
                                                : Colors.orange.shade400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 3,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white24 : Colors.black12,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          d['student_id'] == ref.watch(authSessionProvider).value?.id
                                              ? 'You'
                                              : (d['student_name'] ?? 'Student'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white38 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            error: (e, _) =>
                _buildEmptyCard('Failed to load recent doubts', isDark, theme),
          ),
    );
  }

  // ─── HELPERS ───
  Widget _buildEmptyHint(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String text, bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800.withAlpha(60)
              : Colors.grey.shade100,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  HEADER ICON BUTTON
// ═══════════════════════════════════════════════════

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool animateRotation;
  final bool isDark;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.animateRotation = false,
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
          child: animateRotation
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
