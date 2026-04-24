import 'package:e_guru/core/auth_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UploadNotePage extends ConsumerStatefulWidget {
  const UploadNotePage({super.key});

  @override
  ConsumerState<UploadNotePage> createState() => _UploadNotePageState();
}

class _UploadNotePageState extends ConsumerState<UploadNotePage> {
  final _titleController = TextEditingController();
  int? _selectedSubjectId;
  List<dynamic> _subjects = [];
  bool _isLoading = false;

  PlatformFile? _pickedFile;

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
          _subjects = res['items'] as List<dynamic>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load subjects: $e')));
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  Future<void> _upload() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }
    if (_pickedFile == null || _pickedFile!.bytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a PDF file')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);

      // Step 1: Upload the PDF
      final uploadRes = await api.uploadFile(
        '/uploads/note-pdf',
        'file',
        _pickedFile!.bytes!,
        _pickedFile!.name,
      );

      final pdfPath = uploadRes['path'] as String;

      // Step 2: Create the note record
      await api.post('/teacher/notes', {
        'subject_id': _selectedSubjectId,
        'title': _titleController.text.trim(),
        'pdf_path': pdfPath,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note uploaded successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Note')),
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
                    onChanged: (val) =>
                        setState(() => _selectedSubjectId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Note Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        if (_pickedFile != null)
                          Text(
                            'Selected: ${_pickedFile!.name}',
                            textAlign: TextAlign.center,
                          )
                        else
                          const Text(
                            'No PDF selected',
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Choose PDF'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _upload,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload to Server'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
