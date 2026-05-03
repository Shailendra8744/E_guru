import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/quiz_store.dart';
import 'package:e_guru/core/auth_store.dart';
import 'quiz_analysis_page.dart';

class QuizTakingPage extends ConsumerStatefulWidget {
  final int quizId;
  final String? quizTitle;
  const QuizTakingPage({super.key, required this.quizId, this.quizTitle});

  @override
  ConsumerState<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends ConsumerState<QuizTakingPage> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  final Map<int, String> _answers = {};
  bool _isConverting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _submitQuiz(QuizModel quiz) async {
    setState(() => _isConverting = true);
    try {
      final api = ref.read(apiClientProvider);

      int score = 0;
      for (var q in quiz.questions) {
        if (_answers[q.id] == q.correctOption) {
          score += q.marks;
        }
      }

      final stringAnswers = _answers.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      await api.post('/student/quizzes/${quiz.id}/submit', {
        'answers': stringAnswers,
        'score': score,
      });

      if (!mounted) return;
      await _showFeedbackDialog(quiz.id);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              QuizAnalysisPage(quiz: quiz, answers: _answers, score: score),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  Future<void> _showFeedbackDialog(int quizId) async {
    int rating = 5;
    final feedbackController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Great Job! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How was this quiz experience?'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => rating = index + 1),
                        child: Icon(
                          index < rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: feedbackController,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      filled: true,
                      fillColor: Colors.grey.withAlpha(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final api = ref.read(apiClientProvider);
                      await api.post('/student/quizzes/$quizId/feedback', {
                        'rating': rating,
                        'feedback': feedbackController.text.trim(),
                      });
                    } catch (_) {}
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Submit Feedback'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _indexToOption(int index) {
    return String.fromCharCode(65 + index); // 0 -> A, 1 -> B, etc.
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizDetailsProvider(widget.quizId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1B2A)
          : const Color(0xFFF8F9FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          widget.quizTitle ?? 'Assessment',
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0D1B2A), const Color(0xFF1B263B)]
                : [const Color(0xFFF8F9FE), Colors.white],
          ),
        ),
        child: SafeArea(
          child: quizAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (quiz) {
              final totalQuestions = quiz.questions.length;
              if (totalQuestions == 0)
                return const Center(child: Text("No questions."));

              final progress = (_currentQuestionIndex + 1) / totalQuestions;

              return Column(
                children: [
                  _buildHeader(progress, totalQuestions, isDark),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) =>
                          setState(() => _currentQuestionIndex = i),
                      itemCount: totalQuestions,
                      itemBuilder: (context, qIndex) =>
                          _buildQuestionView(quiz.questions[qIndex], isDark),
                    ),
                  ),
                  _buildNavigation(quiz, totalQuestions, isDark),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double progress, int total, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of $total',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView(QuestionModel question, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(5) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
              border: Border.all(color: Colors.deepPurple.withAlpha(20)),
            ),
            child: Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ...question.optionsList.asMap().entries.map((entry) {
            final optionLetter = _indexToOption(entry.key);
            final isSelected = _answers[question.id] == optionLetter;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () =>
                    setState(() => _answers[question.id] = optionLetter),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepPurple.withAlpha(15)
                        : (isDark ? Colors.white.withAlpha(5) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.deepPurple
                          : (isDark ? Colors.white10 : Colors.grey.shade200),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepPurple
                              : (isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          optionLetter,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isSelected ? Colors.deepPurple : null,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.deepPurple,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavigation(QuizModel quiz, int total, bool isDark) {
    final hasAnswered =
        _answers[quiz.questions[_currentQuestionIndex].id] != null;
    final isLast = _currentQuestionIndex == total - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B263B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentQuestionIndex > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Colors.deepPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Previous',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isConverting
                      ? null
                      : () {
                          if (!hasAnswered && !isLast) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                            return;
                          }
                          if (!hasAnswered && isLast) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select an answer for the last question!',
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            return;
                          }

                          if (_currentQuestionIndex < total - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _submitQuiz(quiz);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isConverting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isLast
                              ? 'Finish Quiz'
                              : (hasAnswered ? 'Next Question' : 'Skip & Next'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
