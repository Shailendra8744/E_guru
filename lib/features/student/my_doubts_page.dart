import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/auth_store.dart';
import 'package:e_guru/features/teacher/doubt_chat_page.dart';
import 'package:intl/intl.dart';

// Provider to fetch student doubts
final studentDoubtsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/student/doubts');
  if (response['doubts'] is List) {
    return response['doubts'] as List<dynamic>;
  }
  return [];
});

class MyDoubtsPage extends ConsumerStatefulWidget {
  const MyDoubtsPage({super.key});

  @override
  ConsumerState<MyDoubtsPage> createState() => _MyDoubtsPageState();
}

class _MyDoubtsPageState extends ConsumerState<MyDoubtsPage> {
  String _selectedSubject = 'All';

  @override
  Widget build(BuildContext context) {
    final doubtsAsync = ref.watch(studentDoubtsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Doubt Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF0D1B2A) : theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(studentDoubtsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── SUBJECT FILTER CHIPS ───
          doubtsAsync.when(
            data: (doubts) {
              final subjects = <String>{'All'};
              for (final d in doubts) {
                if (d['subject_name'] != null) {
                  subjects.add(d['subject_name'] as String);
                }
              }
              return Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surface : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                ),
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
                        onSelected: (_) => setState(() => _selectedSubject = s),
                        selectedColor: theme.colorScheme.primary.withAlpha(40),
                        checkmarkColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected 
                              ? theme.colorScheme.primary 
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected 
                              ? theme.colorScheme.primary 
                              : (isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
          Expanded(
            child: doubtsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
        data: (allDoubts) {
          final doubts = allDoubts.where((d) {
            return _selectedSubject == 'All' ||
                d['subject_name'] == _selectedSubject;
          }).toList();

          if (doubts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.speaker_notes_off_outlined,
                    size: 80,
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No doubts found for this subject',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: doubts.length,
            itemBuilder: (context, index) {
              final doubt = doubts[index];
              final status = doubt['status'] ?? 'pending_assignment';

              Color statusColor = Colors.orange;
              String statusText = 'Pending';
              IconData statusIcon = Icons.pending_actions;

              if (status == 'resolved' || status == 'closed') {
                statusColor = Colors.green;
                statusText = 'Resolved';
                statusIcon = Icons.check_circle;
              } else if (status == 'assigned' || status == 'in_progress') {
                statusColor = Colors.blue;
                statusText = 'In Progress';
                statusIcon = Icons.hourglass_top;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final didResolve = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoubtChatPage(doubt: doubt),
                        ),
                      );
                      if (didResolve == true) {
                        ref.refresh(studentDoubtsProvider);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  doubt['title'] ?? 'Untitled Doubt',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(40),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withAlpha(80),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, color: statusColor, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: theme.colorScheme.primary.withAlpha(40),
                                child: Icon(Icons.person, size: 12, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                doubt['student_id'] == ref.watch(authSessionProvider).value?.id
                                    ? 'You asked this'
                                    : (doubt['student_name'] ?? 'Student'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            doubt['description'] ?? 'No description provided',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey[700],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: isDark ? Colors.white38 : Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                doubt['created_at'] != null
                                    ? DateFormat('MMM dd, yyyy').format(
                                        DateTime.parse(
                                          doubt['created_at'].toString(),
                                        ),
                                      )
                                    : 'Unknown date',
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (doubt['subject_name'] != null) ...[
                                Icon(
                                  Icons.subject,
                                  size: 14,
                                  color: isDark ? Colors.white38 : Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  doubt['subject_name'],
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (doubt['teacher_name'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_pin_rounded,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        doubt['teacher_name'].split(' ')[0],
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
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
              );
            },
          );
        },
      ),
    ),
  ],
),
);
}
}
