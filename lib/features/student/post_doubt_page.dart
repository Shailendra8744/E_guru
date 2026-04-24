import 'package:e_guru/core/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostDoubtPage extends ConsumerStatefulWidget {
  const PostDoubtPage({super.key});

  @override
  ConsumerState<PostDoubtPage> createState() => _PostDoubtPageState();
}

class _PostDoubtPageState extends ConsumerState<PostDoubtPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int? _selectedSubjectId;
  List<dynamic> _subjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/subjects');
      if (mounted) {
        setState(() {
          _subjects = (res['items'] as List<dynamic>?) ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: $e')),
        );
      }
    }
  }

  Future<void> _postDoubt() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a description')));
      return;
    }
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post('/student/doubts', {
        'subject_id': _selectedSubjectId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        // Omitting choosing a specific teacher for now to let automatic assignment take place
      });

      if (mounted) {
        final doubtId = res['doubt_id'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Doubt posted successfully! ID: $doubtId')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post doubt: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Doubt'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Select Subject',
                      border: OutlineInputBorder(),
                    ),
                    items: _subjects.map((sub) {
                      return DropdownMenuItem<int>(
                        value: int.tryParse(sub['id'].toString()),
                        child: Text(sub['name'].toString()),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSubjectId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Doubt Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _postDoubt,
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Doubt'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
