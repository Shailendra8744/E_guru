import 'package:e_guru/core/auth_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateQuizPage extends ConsumerStatefulWidget {
  final int? quizId;
  const CreateQuizPage({super.key, this.quizId});

  @override
  ConsumerState<CreateQuizPage> createState() => _CreateQuizPageState();
}

class QuestionData {
  String questionText = '';
  String optionA = '';
  String optionB = '';
  String optionC = '';
  String optionD = '';
  String correctOption = 'A';
  int marks = 1;

  bool get isValid =>
      questionText.trim().isNotEmpty &&
      optionA.trim().isNotEmpty &&
      optionB.trim().isNotEmpty &&
      optionC.trim().isNotEmpty &&
      optionD.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'question_text': questionText.trim(),
    'option_a': optionA.trim(),
    'option_b': optionB.trim(),
    'option_c': optionC.trim(),
    'option_d': optionD.trim(),
    'correct_option': correctOption,
    'marks': marks,
  };
}

class _CreateQuizPageState extends ConsumerState<CreateQuizPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int? _selectedSubjectId;
  String _selectedDifficulty = 'moderate';
  List<dynamic> _subjects = [];
  bool _isLoading = false;
  bool _isFetchingQuiz = false;

  List<QuestionData> _questions = [QuestionData()];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    if (widget.quizId != null) {
      _loadQuizData();
    }
  }

  Future<void> _loadQuizData() async {
    setState(() => _isFetchingQuiz = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/teacher/quizzes/${widget.quizId}');
      final quiz = res['quiz'];
      if (quiz != null) {
        _titleController.text = quiz['title'] ?? '';
        _descController.text = quiz['description'] ?? '';
        _selectedSubjectId = quiz['subject_id'];
        _selectedDifficulty = quiz['difficulty'] ?? 'moderate';
        
        final questionsList = quiz['questions'] as List<dynamic>?;
        if (questionsList != null && questionsList.isNotEmpty) {
          _questions = questionsList.map((q) {
            final data = QuestionData();
            data.questionText = q['question_text'] ?? '';
            data.optionA = q['option_a'] ?? '';
            data.optionB = q['option_b'] ?? '';
            data.optionC = q['option_c'] ?? '';
            data.optionD = q['option_d'] ?? '';
            data.correctOption = q['correct_option'] ?? 'A';
            data.marks = q['marks'] ?? 1;
            return data;
          }).toList();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load quiz details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingQuiz = false);
      }
    }
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

  Future<void> _submitQuiz() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quiz title')),
      );
      return;
    }
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }

    if (_questions.isEmpty || _questions.any((q) => !q.isValid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all fields for all questions.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = {
        'subject_id': _selectedSubjectId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'difficulty': _selectedDifficulty,
        'questions': _questions.map((q) => q.toJson()).toList(),
      };

      if (widget.quizId != null) {
        await api.put('/teacher/quizzes/${widget.quizId}', data);
      } else {
        await api.post('/teacher/quizzes', data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quizId != null
                ? 'Quiz updated successfully!'
                : 'Quiz created successfully!'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operation failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAIGenerateDialog() async {
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first')),
      );
      return;
    }

    final topicController = TextEditingController();
    double count = 5;
    String dialogDifficulty = _selectedDifficulty;
    PlatformFile? selectedFile;

    final subjectMap = _subjects.firstWhere(
      (s) => int.tryParse(s['id'].toString()) == _selectedSubjectId,
      orElse: () => {'name': ''},
    );
    final subjectName = subjectMap['name'].toString();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Generate Quiz with AI ✨'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: topicController,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        hintText: 'e.g. Photosynthesis',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Number of Questions: ${count.toInt()}'),
                    Slider(
                      value: count,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: count.toInt().toString(),
                      onChanged: (val) {
                        setDialogState(() => count = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: dialogDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'basic', child: Text('Basic')),
                        DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                      ],
                      onChanged: (val) {
                        setDialogState(() => dialogDifficulty = val ?? 'moderate');
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                          withData: true,
                        );
                        if (result != null) {
                          setDialogState(() => selectedFile = result.files.single);
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        selectedFile != null ? 'Selected: ${selectedFile!.name}' : 'Upload Reference PDF (Optional)',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (topicController.text.trim().isEmpty) return;
                    Navigator.of(context).pop();
                    await _generateWithAI(topicController.text.trim(), subjectName, count.toInt(), dialogDifficulty, selectedFile);
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateWithAI(String topic, String subject, int count, String difficulty, PlatformFile? file) async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      
      Map<String, dynamic> res;
      if (file != null && file.bytes != null) {
        res = await api.uploadFile(
          '/teacher/generate-ai-quiz',
          'reference_file',
          file.bytes!,
          file.name,
          {
            'topic': topic,
            'subject': subject,
            'count': count.toString(),
            'difficulty': difficulty,
          }
        );
      } else {
        res = await api.post('/teacher/generate-ai-quiz', {
          'topic': topic,
          'subject': subject,
          'count': count,
          'difficulty': difficulty,
        });
      }

      if (res['questions'] != null) {
        final generatedQuestions = res['questions'] as List<dynamic>;
        setState(() {
          // If the list has only 1 question and it's completely empty, remove it
          if (_questions.length == 1 && _questions[0].questionText.trim().isEmpty) {
            _questions.clear();
          }

          for (var q in generatedQuestions) {
            final data = QuestionData();
            data.questionText = q['question_text'] ?? '';
            data.optionA = q['option_a'] ?? '';
            data.optionB = q['option_b'] ?? '';
            data.optionC = q['option_c'] ?? '';
            data.optionD = q['option_d'] ?? '';
            data.correctOption = q['correct_option'] ?? 'A';
            data.marks = q['marks'] ?? 1;
            _questions.add(data);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully added ${generatedQuestions.length} questions from AI.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Generation failed: $e')),
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

  Widget _buildQuestionCard(int index) {
    final q = _questions[index];
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_questions.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _questions.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: q.questionText,
              decoration: const InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (val) => q.questionText = val,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: q.optionA,
                    decoration: const InputDecoration(
                      labelText: 'Option A',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) => q.optionA = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: q.optionB,
                    decoration: const InputDecoration(
                      labelText: 'Option B',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) => q.optionB = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: q.optionC,
                    decoration: const InputDecoration(
                      labelText: 'Option C',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) => q.optionC = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: q.optionD,
                    decoration: const InputDecoration(
                      labelText: 'Option D',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) => q.optionD = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: q.correctOption,
                    decoration: const InputDecoration(
                      labelText: 'Correct Option',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['A', 'B', 'C', 'D'].map((opt) {
                      return DropdownMenuItem(
                        value: opt,
                        child: Text('Option $opt'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) q.correctOption = val;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: q.marks.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Marks',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      q.marks = int.tryParse(val) ?? 1;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.quizId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Quiz' : 'Create Quiz')),
      body: _isLoading || _isFetchingQuiz
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Quiz Details
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
                DropdownButtonFormField<String>(
                  initialValue: _selectedDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty Level',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'basic', child: Text('Basic')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (val) => setState(() => _selectedDifficulty = val ?? 'moderate'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Quiz Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Quiz Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const Divider(height: 48),

                // Questions list
                Text(
                  'Questions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  _questions.length,
                  (i) => _buildQuestionCard(i),
                ),

                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _questions.add(QuestionData());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withAlpha(128),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _showAIGenerateDialog,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate with AI'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: _isLoading || _isFetchingQuiz 
        ? null 
        : Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: FilledButton.icon(
                onPressed: _submitQuiz,
                icon: Icon(isEdit ? Icons.save_rounded : Icons.check_circle),
                label: Text(isEdit ? 'Update Quiz' : 'Submit Quiz', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
    );
  }
}
