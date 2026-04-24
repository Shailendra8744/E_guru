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

class MyDoubtsPage extends ConsumerWidget {
  const MyDoubtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doubtsAsync = ref.watch(studentDoubtsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Doubts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(studentDoubtsProvider),
          ),
        ],
      ),
      body: doubtsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
        data: (doubts) {
          if (doubts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.speaker_notes_off_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No doubts posted yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                        // ignore: unused_result
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      color: statusColor,
                                      size: 12,
                                    ),
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
                          Text(
                            doubt['description'] ?? 'No description provided',
                            style: TextStyle(
                              color: Colors.grey[700],
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
                                color: Colors.grey[500],
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
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              if (doubt['image_path'] != null &&
                                  doubt['image_path'].toString().isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Has Image',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
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
    );
  }
}
