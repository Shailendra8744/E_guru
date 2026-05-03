import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/auth_store.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminNotesPage extends ConsumerStatefulWidget {
  const AdminNotesPage({super.key});

  @override
  ConsumerState<AdminNotesPage> createState() => _AdminNotesPageState();
}

class _AdminNotesPageState extends ConsumerState<AdminNotesPage> {
  List<dynamic> _notes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).get('/admin/notes');
      if (mounted) {
        setState(() => _notes = res['items'] ?? []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    try {
      await ref.read(apiClientProvider).post('/admin/notes/$id/toggle', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? 'Note deactivated' : 'Note activated'),
            backgroundColor: currentStatus ? Colors.orange.shade700 : Colors.green.shade700,
          ),
        );
        _fetchNotes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _openPdf(String path) async {
    // Ensure we have an absolute URL
    final String baseUrl = 'https://engineerfarm.in/backend/public/';
    final String fullUrl = path.startsWith('http') ? path : '$baseUrl$path';

    if (!mounted) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('View Note'),
            backgroundColor: const Color(0xFF1A1040),
            foregroundColor: Colors.white,
          ),
          body: SfPdfViewer.network(fullUrl),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Manage Notes'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1A1040) : theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 64, color: isDark ? Colors.white30 : Colors.black26),
                      const SizedBox(height: 16),
                      Text('No notes found.',
                          style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final isActive = note['is_active'] == 1;
                      return Card(
                        elevation: isDark ? 0 : 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withAlpha(isDark ? 40 : 20),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.picture_as_pdf_rounded,
                                        color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          note['title'] ?? 'Untitled',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Subject: ${note['subject_name'] ?? 'Unknown'}\nTeacher: ${note['teacher_name'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _openPdf(note['pdf_path']),
                                    icon: const Icon(Icons.download_rounded, size: 18),
                                    label: const Text('View File'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isActive ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Switch(
                                        value: isActive,
                                        onChanged: (val) => _toggleStatus(note['id'], isActive),
                                        activeColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
