import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/auth_store.dart';

class TeacherManagementPage extends ConsumerStatefulWidget {
  const TeacherManagementPage({super.key});

  @override
  ConsumerState<TeacherManagementPage> createState() =>
      _TeacherManagementPageState();
}

class _TeacherManagementPageState extends ConsumerState<TeacherManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _teachers = [];
  List<dynamic> _filteredTeachers = [];
  List<dynamic> _pendingRequests = [];
  bool _isLoadingTeachers = false;
  bool _isLoadingRequests = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadTeachers(),
      _loadPendingRequests(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    if (!mounted) return;
    setState(() => _isLoadingTeachers = true);
    try {
      final res = await ref.read(apiClientProvider).get('/admin/users', {
        'page': '1',
        'per_page': '1000',
      });
      if (mounted) {
        final allUsers = res['items'] as List<dynamic>;
        setState(() {
          _teachers = allUsers.where((u) => u['role'] == 'teacher').toList();
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load verified teachers: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingTeachers = false);
    }
  }

  Future<void> _loadPendingRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingRequests = true);
    try {
      final res = await ref.read(apiClientProvider).get('/admin/teacher-registrations');
      if (mounted) {
        setState(() {
          _pendingRequests = res['items'] as List<dynamic>;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load requests: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredTeachers = _teachers;
    } else {
      _filteredTeachers = _teachers.where((t) {
        final name = t['full_name']?.toString().toLowerCase() ?? '';
        final email = t['email']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }
  }

  Future<void> _handleRequest(int id, bool approve) async {
    setState(() => _isLoadingRequests = true);
    try {
      final endpoint = approve ? 'approve' : 'reject';
      await ref
          .read(apiClientProvider)
          .post('/admin/teacher-registrations/$id/$endpoint', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve ? 'Teacher Approved!' : 'Request Rejected!'),
          backgroundColor: approve ? Colors.green : Colors.red,
        ));
        _loadAll();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _updateStatus(int userId, String newStatus) async {
    try {
      await ref.read(apiClientProvider).post('/admin/users/$userId/status', {
        'status': newStatus,
      });
      _loadTeachers();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _assignSubjectToTeacher(int teacherId, int subjectId) async {
    try {
      await ref.read(apiClientProvider).post(
        '/admin/teachers/$teacherId/subjects',
        {'subject_id': subjectId, 'expertise_level': 1},
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject Assigned!')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showTeacherSubjects(int teacherId) async {
    try {
      final res = await ref.read(apiClientProvider).get('/subjects');
      final subjects = res['items'] as List;
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Assign Subject'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (c, i) => ListTile(
                title: Text(subjects[i]['name']),
                onTap: () {
                  Navigator.pop(ctx);
                  _assignSubjectToTeacher(teacherId, subjects[i]['id'] as int);
                },
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showEditOptions(Map<String, dynamic> teacher) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teacher['full_name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                teacher['email'],
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['active', 'suspended'].map((status) {
                  final isCurrent = teacher['status'] == status;
                  return ChoiceChip(
                    label: Text(status.toUpperCase()),
                    selected: isCurrent,
                    onSelected: isCurrent
                        ? null
                        : (_) {
                            Navigator.pop(ctx);
                            _updateStatus(teacher['id'] as int, status);
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.book, color: Colors.white, size: 20),
                ),
                title: const Text(
                  'Assign Subjects',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Required for auto-assignment'),
                trailing: const Icon(
                  Icons.add_circle,
                  color: Colors.deepPurple,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTeacherSubjects(teacher['id'] as int);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Teacher Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(text: 'Verified (${_teachers.length})'),
            Tab(text: 'Requests (${_pendingRequests.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVerifiedTab(theme, isDark),
          _buildRequestsTab(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildVerifiedTab(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (v) => setState(() {
              _searchQuery = v;
              _applyFilter();
            }),
            decoration: InputDecoration(
              hintText: 'Search verified teachers...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: isDark
                  ? theme.colorScheme.surfaceContainerHigh
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingTeachers && _teachers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadTeachers,
                  child: _filteredTeachers.isEmpty
                      ? const Center(child: Text('No verified teachers'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTeachers.length,
                          itemBuilder: (context, index) {
                            final t = _filteredTeachers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary
                                      .withAlpha(40),
                                  child: Text(t['full_name'][0].toUpperCase()),
                                ),
                                title: Text(
                                  t['full_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(t['email']),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.settings_suggest_rounded,
                                    color: Colors.deepPurple,
                                  ),
                                  onPressed: () => _showEditOptions(t),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab(ThemeData theme, bool isDark) {
    if (_isLoadingRequests && _pendingRequests.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (_pendingRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPendingRequests,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 300,
            alignment: Alignment.center,
            child: const Text('No pending approval requests'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final req = _pendingRequests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withAlpha(40),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(
                      req['full_name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(req['email']),
                    trailing: Text(
                      req['created_at'].toString().split(' ')[0],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _handleRequest(req['id'] as int, false),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _handleRequest(req['id'] as int, true),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
