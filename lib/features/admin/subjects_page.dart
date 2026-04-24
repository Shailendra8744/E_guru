import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/auth_store.dart';

class SubjectsPage extends ConsumerStatefulWidget {
  const SubjectsPage({super.key});

  @override
  ConsumerState<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends ConsumerState<SubjectsPage> {
  List<dynamic> _subjects = [];
  List<dynamic> _filteredSubjects = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final _subjectNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).get('/subjects');
      if (mounted) {
        setState(() {
          _subjects = res['items'] as List<dynamic>;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredSubjects = _subjects;
    } else {
      _filteredSubjects = _subjects
          .where((s) => s['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  void _showAddSubjectSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(isDark ? 40 : 20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_task_rounded,
                        color: theme.colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Create New Subject',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _subjectNameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'e.g. Mathematics II',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = _subjectNameController.text.trim();
                    if (name.isEmpty) return;
                    
                    try {
                      await ref.read(apiClientProvider).post('/admin/subjects', {'name': name});
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _subjectNameController.clear();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Subject created successfully!')),
                        );
                        _loadSubjects();
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Save Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Subject Management', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubjectSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Subject'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubjects,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (v) {
                  setState(() {
                    _searchQuery = v;
                    _applyFilter();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search subjects...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            
            Expanded(
              child: _isLoading && _subjects.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredSubjects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No subjects found',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filteredSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = _filteredSubjects[index];
                            final name = subject['name']?.toString() ?? 'Unnamed';
                            final id = subject['id']?.toString() ?? '?';
                            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? Colors.grey.shade800.withAlpha(60) : Colors.grey.shade100,
                                ),
                                boxShadow: isDark ? null : [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(isDark ? 40 : 20),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.grey.shade900,
                                  ),
                                ),
                                subtitle: Text(
                                  'Subject ID: #$id',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                                onTap: () {
                                  // Optional: View more details or edit
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
