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
import 'package:e_guru/features/teacher/doubt_chat_page.dart';
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

  // Local To-Do state
  List<Map<String, dynamic>> todos = [];
  final _todoController = TextEditingController();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTodos();
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
      if (!mounted) return;
      setState(() {
        notes = (n['items'] as List<dynamic>?) ?? [];
        quizzes = (q['quizzes'] as List<dynamic>?) ?? [];
        quizInsights = (i['items'] as List<dynamic>?) ?? [];
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
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PostDoubtPage()));
              },
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Post Doubt'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: _currentIndex == 0
          ? _buildHomeTab(theme, isDark)
          : StudentProfilePage(quizzes: quizzes, quizInsights: quizInsights),
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
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
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

          // ─── STUDY MATERIALS ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Teacher Material', Icons.assignment_ind_rounded, theme, isDark),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudyMaterialsPage()),
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
                        Icon(Icons.arrow_forward_rounded, size: 16, color: theme.colorScheme.primary),
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
                  _buildSectionTitle('All Notes', Icons.library_books_rounded, theme, isDark),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllNotesPage()),
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
                        Icon(Icons.arrow_forward_rounded, size: 16, color: theme.colorScheme.primary),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.blue.withAlpha(30) : Colors.blue.withAlpha(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: isDark ? Colors.blue.shade200 : Colors.blue.shade700, size: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'General Library',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            'Access 1000+ study materials',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AllNotesPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Open'),
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
                  _buildSectionTitle('Active Quizzes', Icons.quiz_rounded, theme, isDark),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuizzesPage()),
                      ).then((_) => _loadData());
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
                        Icon(Icons.arrow_forward_rounded, size: 16, color: theme.colorScheme.primary),
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
                  'My To-Do List', Icons.task_alt_rounded, theme, isDark),
            ),
          ),
          SliverToBoxAdapter(child: _buildTodoCard(theme, isDark)),

          // ─── RECENT DOUBTS ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: _buildSectionTitle(
                  'Recent Doubts', Icons.history_rounded, theme, isDark),
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
              ? [const Color(0xFF0D1B2A), const Color(0xFF1B2838), const Color(0xFF1A1040)]
              : [theme.colorScheme.primary, const Color(0xFF5C6BC0), const Color(0xFF7E57C2)],
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
                child: const Icon(Icons.person_rounded,
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
                      'Student Dashboard',
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
              _HeaderIconButton(
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                onTap: _toggleTheme,
                animateRotation: true,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              // Leaderboard
              _HeaderIconButton(
                icon: Icons.emoji_events_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                  );
                },
                isDark: isDark,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              // Logout
              _HeaderIconButton(
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
                Icon(Icons.auto_awesome_rounded,
                    color: Colors.white.withAlpha(180), size: 14),
                const SizedBox(width: 8),
                Text(
                  'Study, quiz & clear your doubts',
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

  // ─── SECTION TITLE ───
  Widget _buildSectionTitle(
      String title, IconData icon, ThemeData theme, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

  // ─── NOTES CAROUSEL ───
  Widget _buildNotesCarousel(ThemeData theme, bool isDark) {
    if (notes.isEmpty) {
      return _buildEmptyHint('No study materials available', isDark);
    }

    return SizedBox(
      height: 155,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final n = notes[index];
          return Container(
            width: 135,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color:
                  isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  const String baseUrl =
                      "https://engineerfarm.in/backend/public";
                  final String relativePath = n['pdf_path'] as String;
                  final String normalizedRelative =
                      relativePath.startsWith('/')
                          ? relativePath.substring(1)
                          : relativePath;
                  final List<String> pathSegments =
                      normalizedRelative.split('/');
                  final String encodedRelativePath = pathSegments
                      .map((segment) => Uri.encodeComponent(segment))
                      .join('/');
                  final String fullUrl = "$baseUrl/$encodedRelativePath";

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PDFReaderPage(
                          title: n['title'] as String, url: fullUrl),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade800.withAlpha(60)
                          : Colors.grey.shade100,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.red.shade900.withAlpha(50)
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.red.shade400, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        n['title'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade200
                              : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        n['subject_name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500),
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

  // ─── QUIZ CAROUSEL ───
  Widget _buildQuizCarousel(ThemeData theme, bool isDark) {
    if (quizzes.isEmpty) {
      return _buildEmptyHint('No quizzes available', isDark);
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final q = quizzes[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color:
                  isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizTakingPage(quizId: q['id'] as int),
                    ),
                  ).then((_) => _loadData());
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.colorScheme.primary.withAlpha(30)
                              : theme.colorScheme.primary.withAlpha(18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.quiz_rounded,
                            color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              q['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              q['subject_name'] as String,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          size: 20),
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
                    color: theme.colorScheme.primary.withAlpha(isDark ? 35 : 18),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _addTodo(_todoController.text),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.add_rounded,
                            color: theme.colorScheme.primary, size: 22),
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
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400,
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
                                decoration:
                                    done ? TextDecoration.lineThrough : null,
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
                                child: Icon(Icons.close_rounded,
                                    size: 16,
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400),
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
      child: ref.watch(studentDoubtsProvider).when(
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
                                  doubt: d as Map<String, dynamic>)));
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
                                      ? Colors.green.shade900.withAlpha(50)
                                      : Colors.green.shade50)
                                  : (isDark
                                      ? Colors.orange.shade900.withAlpha(50)
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
                                Text(
                                  d['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isResolved
                                        ? Colors.green.shade400
                                        : Colors.orange.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                              size: 20),
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
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          ),
        ),
        error: (e, _) => _buildEmptyCard(
            'Failed to load recent doubts', isDark, theme),
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
  final Color? color;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.animateRotation = false,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final child = Icon(
      icon,
      key: ValueKey(icon),
      color: color ?? Colors.white.withAlpha(210),
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
