import 'package:e_guru/core/auth_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AIPracticePage extends ConsumerStatefulWidget {
  const AIPracticePage({super.key});

  @override
  ConsumerState<AIPracticePage> createState() => _AIPracticePageState();
}

class _AIPracticePageState extends ConsumerState<AIPracticePage> {
  final _topicController = TextEditingController();
  final _subjectController = TextEditingController();
  int _questionCount = 5;
  String _difficulty = 'moderate';
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  List<dynamic>? _generatedQuestions;
  int _currentQuestionIndex = 0;
  Map<int, String> _userAnswers = {};
  bool _showResults = false;

  Future<void> _generateQuiz() async {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedQuestions = null;
      _showResults = false;
      _userAnswers = {};
      _currentQuestionIndex = 0;
    });

    try {
      final api = ref.read(apiClientProvider);
      Map<String, dynamic> res;

      if (_selectedFile != null && _selectedFile!.bytes != null) {
        res = await api.uploadFile(
          '/student/generate-practice-quiz',
          'reference_file',
          _selectedFile!.bytes!,
          _selectedFile!.name,
          {
            'topic': _topicController.text.trim(),
            'subject': _subjectController.text.trim(),
            'count': _questionCount.toString(),
            'difficulty': _difficulty,
          },
        );
      } else {
        res = await api.post('/student/generate-practice-quiz', {
          'topic': _topicController.text.trim(),
          'subject': _subjectController.text.trim(),
          'count': _questionCount,
          'difficulty': _difficulty,
        });
      }

      if (mounted) {
        setState(() {
          _generatedQuestions = res['questions'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Generation failed: $e')),
        );
      }
    }
  }

  void _submitPractice() {
    setState(() => _showResults = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Practice Lab', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: _generatedQuestions == null ? _buildSetupUI(theme, isDark) : _buildPracticeUI(theme, isDark),
        ),
      ),
    );
  }

  Widget _buildSetupUI(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 60, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Personalized AI Practice',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Generate custom quizzes from any topic or PDF',
              style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 40),
          _buildTextField('Topic to study', _topicController, Icons.topic_rounded, 'e.g. Quantum Physics or History of India'),
          const SizedBox(height: 20),
          _buildTextField('Subject (Optional)', _subjectController, Icons.book_rounded, 'e.g. Science'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.withAlpha(30)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _questionCount,
                          isExpanded: true,
                          items: [5, 10, 15, 20].map((e) => DropdownMenuItem(value: e, child: Text('$e Qs'))).toList(),
                          onChanged: (v) => setState(() => _questionCount = v ?? 5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(10) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.withAlpha(30)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _difficulty,
                          isExpanded: true,
                          items: ['basic', 'moderate', 'high'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                          onChanged: (v) => setState(() => _difficulty = v ?? 'moderate'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () async {
              final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
              if (result != null) setState(() => _selectedFile = result.files.single);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _selectedFile != null ? Colors.green.withAlpha(20) : theme.colorScheme.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _selectedFile != null ? Colors.green.withAlpha(50) : theme.colorScheme.primary.withAlpha(30), style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Icon(_selectedFile != null ? Icons.check_circle_rounded : Icons.upload_file_rounded, color: _selectedFile != null ? Colors.green : theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _selectedFile != null ? _selectedFile!.name : 'Upload Reference PDF (Recommended)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _selectedFile != null ? Colors.green : theme.colorScheme.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _generateQuiz,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: theme.colorScheme.primary,
              ),
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
              label: Text(_isLoading ? 'Generating Questions...' : 'Generate Practice Quiz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withAlpha(10) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeUI(ThemeData theme, bool isDark) {
    if (_showResults) return _buildResultsUI(theme, isDark);

    final q = _generatedQuestions![_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _generatedQuestions!.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${_currentQuestionIndex + 1}/${_generatedQuestions!.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => setState(() => _generatedQuestions = null), child: const Text('Exit Lab')),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, borderRadius: BorderRadius.circular(10), minHeight: 8),
          const SizedBox(height: 40),
          Text(q['question_text'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          ...['A', 'B', 'C', 'D'].map((opt) {
            final optionText = q['option_${opt.toLowerCase()}'];
            final isSelected = _userAnswers[_currentQuestionIndex] == opt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _userAnswers[_currentQuestionIndex] = opt),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary.withAlpha(20) : (isDark ? Colors.white.withAlpha(5) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.white12 : Colors.grey.shade200), width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.white10 : Colors.grey.shade100),
                          shape: BoxShape.circle,
                        ),
                        child: Text(opt, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(optionText, style: const TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentQuestionIndex--),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_currentQuestionIndex < _generatedQuestions!.length - 1) {
                      setState(() => _currentQuestionIndex++);
                    } else {
                      _submitPractice();
                    }
                  },
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(_currentQuestionIndex < _generatedQuestions!.length - 1 ? 'Next' : 'Finish Lab'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsUI(ThemeData theme, bool isDark) {
    int score = 0;
    for (int i = 0; i < _generatedQuestions!.length; i++) {
      if (_userAnswers[i] == _generatedQuestions![i]['correct_option']) score++;
    }
    final percent = (score / _generatedQuestions!.length * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('Practice Complete!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 150, height: 150, child: CircularProgressIndicator(value: score / _generatedQuestions!.length, strokeWidth: 12, backgroundColor: Colors.white10, color: Colors.green)),
              Column(
                children: [
                  Text('$percent%', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.green)),
                  const Text('Score', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withAlpha(isDark ? 10 : 100), borderRadius: BorderRadius.circular(24)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResStat('Total', _generatedQuestions!.length.toString(), Icons.quiz),
                _buildResStat('Correct', score.toString(), Icons.check_circle, Colors.green),
                _buildResStat('Wrong', (_generatedQuestions!.length - score).toString(), Icons.cancel, Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton(
              onPressed: () => setState(() => _generatedQuestions = null),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('Try Another Topic', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Home')),
        ],
      ),
    );
  }

  Widget _buildResStat(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
