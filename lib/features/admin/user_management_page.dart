import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/auth_store.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  List<dynamic> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).get('/admin/users', {
        'page': '1',
        'per_page': '100', // Retrieve up to 100 for now.
      });
      if (mounted) {
        setState(() => _users = res['items'] as List<dynamic>);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRole(int userId, String newRole) async {
    try {
      await ref.read(apiClientProvider).post('/admin/users/$userId/role', {'role': newRole});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated')));
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateStatus(int userId, String newStatus) async {
    try {
      await ref.read(apiClientProvider).post('/admin/users/$userId/status', {'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated')));
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _assignSubjectToTeacher(int teacherId, int subjectId) async {
    try {
      await ref.read(apiClientProvider).post(
        '/admin/teachers/$teacherId/subjects',
        {'subject_id': subjectId, 'expertise_level': 1},
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject Assigned!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
          title: const Text('Assign Subject (Required for auto-assignment)'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subjects.length,
              itemBuilder: (c, i) {
                final name = subjects[i]['name']?.toString() ?? '';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                return ListTile(
                  leading: CircleAvatar(child: Text(initial)),
                  title: Text(name.isNotEmpty ? name : 'Unnamed Subject'),
                  subtitle: Text('ID: ${subjects[i]['id']}'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _assignSubjectToTeacher(teacherId, subjects[i]['id'] as int);
                  },
                );
              }
            )
          )
        )
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load subjects: $e')));
    }
  }

  void _showEditOptions(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['full_name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user['email'], style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                const Text('Change Role', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ['admin', 'teacher', 'student'].map((role) {
                    final isCurrent = user['role'] == role;
                    return ChoiceChip(
                      label: Text(role.toUpperCase()),
                      selected: isCurrent,
                      onSelected: isCurrent ? null : (_) {
                        Navigator.pop(ctx);
                        _updateRole(user['id'] as int, role);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Change Status', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ['active', 'suspended', 'pending_approval', 'rejected'].map((status) {
                    final isCurrent = user['status'] == status;
                    return ChoiceChip(
                      label: Text(status.toUpperCase()),
                      selected: isCurrent,
                      selectedColor: status == 'suspended' ? Colors.red.shade100 : Colors.blue.shade100,
                      onSelected: isCurrent ? null : (_) {
                        Navigator.pop(ctx);
                        _updateStatus(user['id'] as int, status);
                      },
                    );
                  }).toList(),
                ),
                if (user['role'] == 'teacher' && user['status'] == 'active') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.book, color: Colors.white, size: 20)),
                    title: const Text('Assign Subjects', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Required for doubt auto-assignment', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.add_circle, color: Colors.deepPurple),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showTeacherSubjects(user['id'] as int);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          )
        ],
      ),
      body: _isLoading && _users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isActive = user['status'] == 'active';
                  final roleColor = user['role'] == 'admin'
                      ? Colors.deepPurple
                      : (user['role'] == 'teacher' ? Colors.teal : Colors.blue.shade600);
                  
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: roleColor,
                        foregroundColor: Colors.white,
                        child: Text((user['full_name'] as String)[0].toUpperCase()),
                      ),
                      title: Text(user['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email']),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (user['role'] as String).toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (user['status'] as String).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditOptions(context, user),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
