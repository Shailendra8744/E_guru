import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/features/student/pdf_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to fetch teacher material (internal notes) from the API.
final studentNotesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/student/notes', {
    'page': '1',
    'per_page': '200',
  });
  return res['items'] as List<dynamic>;
});

class StudyMaterialsPage extends ConsumerStatefulWidget {
  const StudyMaterialsPage({super.key});

  @override
  ConsumerState<StudyMaterialsPage> createState() =>
      _StudyMaterialsPageState();
}

class _StudyMaterialsPageState extends ConsumerState<StudyMaterialsPage> {
  String _searchQuery = '';
  String _selectedSubject = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notesAsync = ref.watch(studentNotesProvider);

    return Scaffold(
      backgroundColor:
          isDark ? theme.colorScheme.surface : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // ─── BEAUTIFUL APP BAR ───
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF0D1B2A)
                : theme.colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 10, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.assignment_ind_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Study Materials',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Browse all your learning resources',
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
          ),

          // ─── SEARCH BAR ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHigh
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade800.withAlpha(60)
                        : Colors.grey.shade200,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(
                    color:
                        isDark ? Colors.grey.shade200 : Colors.grey.shade900,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search materials...',
                    hintStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: theme.colorScheme.primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // ─── SUBJECT FILTER CHIPS ───
          SliverToBoxAdapter(
            child: notesAsync.when(
              data: (notes) {
                final subjects = <String>{'All'};
                for (final n in notes) {
                  if (n['subject_name'] != null) {
                    subjects.add(n['subject_name'] as String);
                  }
                }
                return SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: subjects.map((s) {
                      final isSelected = _selectedSubject == s;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(s),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedSubject = s),
                          selectedColor:
                              theme.colorScheme.primary.withAlpha(30),
                          checkmarkColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary.withAlpha(60)
                                : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300),
                          ),
                          backgroundColor: isDark
                              ? theme.colorScheme.surfaceContainerHigh
                              : Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
          ),

          // ─── NOTES LIST / GRID ───
          notesAsync.when(
            data: (notes) {
              var filtered = notes.where((n) {
                final title =
                    (n['title'] as String? ?? '').toLowerCase();
                final subject =
                    (n['subject_name'] as String? ?? '').toLowerCase();
                final matchesSearch =
                    _searchQuery.isEmpty ||
                    title.contains(_searchQuery.toLowerCase()) ||
                    subject.contains(_searchQuery.toLowerCase());
                final matchesSubject = _selectedSubject == 'All' ||
                    n['subject_name'] == _selectedSubject;
                return matchesSearch && matchesSubject;
              }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 64,
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No study materials found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final n = filtered[index];
                      return _NoteCard(
                        note: n,
                        isDark: isDark,
                        theme: theme,
                        index: index,
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                    color: theme.colorScheme.primary),
              ),
            ),
            error: (e, st) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load materials',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          ref.refresh(studentNotesProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  NOTE CARD WIDGET
// ═══════════════════════════════════════════════════
class _NoteCard extends StatelessWidget {
  final dynamic note;
  final bool isDark;
  final ThemeData theme;
  final int index;

  const _NoteCard({
    required this.note,
    required this.isDark,
    required this.theme,
    required this.index,
  });

  static const _accentColors = [
    Color(0xFFEF5350), // red
    Color(0xFF42A5F5), // blue
    Color(0xFF66BB6A), // green
    Color(0xFFAB47BC), // purple
    Color(0xFFFF7043), // orange
    Color(0xFF26C6DA), // cyan
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accentColors[index % _accentColors.length];
    final title = note['title'] as String? ?? 'Untitled';
    final subject = note['subject_name'] as String? ?? '';
    final createdAt = note['created_at'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            const String baseUrl =
                "https://engineerfarm.in/backend/public";
            final String relativePath = note['pdf_path'] as String;
            final String normalizedRelative = relativePath.startsWith('/')
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
                builder: (_) =>
                    PDFReaderPage(title: title, url: fullUrl),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.grey.shade800.withAlpha(60)
                    : Colors.grey.shade100,
              ),
            ),
            child: Row(
              children: [
                // PDF icon with accent bg
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(isDark ? 35 : 22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.picture_as_pdf_rounded,
                      color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                // Title + Subject
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark
                              ? Colors.grey.shade200
                              : Colors.grey.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    accent.withAlpha(isDark ? 25 : 15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: accent.withAlpha(isDark ? 220 : 255),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (createdAt.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              createdAt.length >= 10
                                  ? createdAt.substring(0, 10)
                                  : createdAt,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(isDark ? 25 : 12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
