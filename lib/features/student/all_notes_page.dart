import 'package:e_guru/features/student/pdf_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Provider to fetch external notes (all notes) from engineerfarm.in API.
/// This is independent of the learningapp directory.
final externalNotesProvider = FutureProvider<List<dynamic>>((ref) async {
  // Use http directly for external API as it's outside the e_guru backend structure
  final response = await http
      .get(Uri.parse('https://engineerfarm.in/api/notes.php'))
      .timeout(const Duration(seconds: 30));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    // Based on legacy logic, data can be in 'notes', 'data', or the root
    final List<dynamic> notesList =
        data['notes'] ?? data['data'] ?? (data is List ? data : []);
    return notesList;
  } else {
    throw Exception('Failed to fetch external notes: ${response.statusCode}');
  }
});

class AllNotesPage extends ConsumerStatefulWidget {
  const AllNotesPage({super.key});

  @override
  ConsumerState<AllNotesPage> createState() => _AllNotesPageState();
}

class _AllNotesPageState extends ConsumerState<AllNotesPage> {
  String _searchQuery = '';
  // ignore: unused_field
  String _selectedSubject = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notesAsync = ref.watch(externalNotesProvider);

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // ─── BEAUTIFUL APP BAR ───
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF1A1A2E)
                : const Color(0xFF1A237E),
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
                            const Color(0xFF1A1A2E),
                            const Color(0xFF16213E),
                            const Color(0xFF0F3460),
                          ]
                        : [
                            const Color(0xFF1A237E),
                            const Color(0xFF283593),
                            const Color(0xFF3949AB),
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
                              child: const Icon(
                                Icons.library_books_rounded,
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
                                    'All Library Notes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    'External Study Materials',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(180),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
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

          // ─── SEARCH & FILTER ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search in library...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── NOTES LIST ───
          notesAsync.when(
            data: (notes) {
              final filteredNotes = notes.where((n) {
                final title = (n['title'] ?? '').toString().toLowerCase();
                final subject = (n['subject'] ?? '').toString().toLowerCase();
                final query = _searchQuery.toLowerCase();
                return title.contains(query) || subject.contains(query);
              }).toList();

              if (filteredNotes.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No notes found matching your search'),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final n = filteredNotes[index];
                    return _buildNoteItem(n, theme, isDark);
                  }, childCount: filteredNotes.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(Map<String, dynamic> n, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800.withAlpha(60)
              : Colors.grey.shade100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // URL Construction for external notes
            final String filePath = n['file_path'] ?? '';
            String fullUrl = '';
            if (filePath.startsWith('http')) {
              fullUrl = filePath;
            } else {
              const String baseDomain = "https://engineerfarm.in/";
              final String cleanPath = filePath.startsWith('/')
                  ? filePath.substring(1)
                  : filePath;
              fullUrl = "$baseDomain$cleanPath";
            }

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    PDFReaderPage(title: n['title'] ?? 'Note', url: fullUrl),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.blue.shade900 : Colors.blue.shade50)
                        .withAlpha(100),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['title'] ?? 'Untitled Note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.subject_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              n['subject'] ?? 'General',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.school_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              n['branch'] ?? 'All',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
