import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/quiz_store.dart';
import 'package:e_guru/core/auth_store.dart';
import 'quiz_analysis_page.dart';

class QuizTakingPage extends ConsumerStatefulWidget {
  final int quizId;
  const QuizTakingPage({super.key, required this.quizId});

  @override
  ConsumerState<QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends ConsumerState<QuizTakingPage> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  final Map<int, String> _answers =
      {}; // questionId -> selectedOption ('A','B','C','D')
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

      // Calculate score locally for the simple demo, or let backend do it
      int score = 0;
      for (var q in quiz.questions) {
        if (_answers[q.id] == q.correctOption) {
          score += q.marks;
        }
      }

      // Convert map keys to strings for JSON encoding
      final stringAnswers = _answers.map((key, value) => MapEntry(key.toString(), value));

      await api.post('/student/quizzes/${quiz.id}/submit', {
        'answers': stringAnswers,
        'score': score,
      });

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

  String _indexToOption(int index) {
    switch (index) {
      case 0:
        return 'A';
      case 1:
        return 'B';
      case 2:
        return 'C';
      case 3:
        return 'D';
      default:
        return 'A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizDetailsProvider(widget.quizId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Assessment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: quizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (quiz) {
          final totalQuestions = quiz.questions.length;
          if (totalQuestions == 0) {
            return const Center(child: Text("This quiz has no questions."));
          }

          final progress = (_currentQuestionIndex + 1) / totalQuestions;

          return Column(
            children: [
              // Progress Section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
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
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Question View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentQuestionIndex = index;
                    });
                  },
                  itemCount: totalQuestions,
                  itemBuilder: (context, qIndex) {
                    final question = quiz.questions[qIndex];
                    final String? selectedAnswerType = _answers[question.id];

                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.questionText,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 32),
                            ...question.optionsList.asMap().entries.map((
                              entry,
                            ) {
                              final optionIndex = entry.key;
                              final optionText = entry.value;
                              final optionLetter = _indexToOption(optionIndex);
                              final isSelected =
                                  selectedAnswerType == optionLetter;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _answers[question.id] = optionLetter;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.deepPurple[50]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.deepPurple
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.deepPurple
                                                : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? Colors.deepPurple
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          optionText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.deepPurple[900]
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Navigation Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Row(
                  children: [
                    if (_currentQuestionIndex > 0)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.deepPurple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Previous',
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isConverting
                            ? null
                            : (_answers[quiz
                                          .questions[_currentQuestionIndex]
                                          .id] !=
                                      null
                                  ? () {
                                      if (_currentQuestionIndex <
                                          totalQuestions - 1) {
                                        _pageController.nextPage(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      } else {
                                        _submitQuiz(quiz);
                                      }
                                    }
                                  : null),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isConverting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _currentQuestionIndex < totalQuestions - 1
                                    ? 'Next Question'
                                    : 'Finish Quiz',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
