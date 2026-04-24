import 'package:flutter/material.dart';
import 'package:e_guru/core/quiz_store.dart';

class QuizAnalysisPage extends StatelessWidget {
  final QuizModel quiz;
  final Map<int, String> answers;
  final int score;

  const QuizAnalysisPage({
    super.key,
    required this.quiz,
    required this.answers,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final totalQuestions = quiz.questions.length;
    // ignore: unused_local_variable
    final totalMarks = quiz.totalMarks > 0 ? quiz.totalMarks : totalQuestions;

    // Calculate simple percentage based on score / total questions (if each is 1 mark)
    // or score / totalMarks. Using totalQuestions if marks aren't properly populated.
    final possibleMaxScore = quiz.questions.fold<int>(
      0,
      (sum, q) => sum + q.marks,
    );
    final maxScore = possibleMaxScore > 0 ? possibleMaxScore : 1;
    final percentage = (score / maxScore * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz Analysis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: percentage >= 70
                  ? Colors.green.shade50
                  : percentage >= 50
                  ? Colors.orange.shade50
                  : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Your Score',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$score / $maxScore',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        minHeight: 10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 70
                              ? Colors.green
                              : percentage >= 50
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Question-wise Analysis
            const Text(
              'Question-wise Analysis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...quiz.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final userAnswerType = answers[question.id];
              final isCorrect = userAnswerType == question.correctOption;

              String _getOptionText(String letter) {
                switch (letter) {
                  case 'A':
                    return question.optionA;
                  case 'B':
                    return question.optionB;
                  case 'C':
                    return question.optionC;
                  case 'D':
                    return question.optionD;
                  default:
                    return '';
                }
              }

              final userAnswerText = userAnswerType != null
                  ? _getOptionText(userAnswerType)
                  : 'Not answered';
              final correctAnswerText = _getOptionText(question.correctOption);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Question ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${question.marks} Marks',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.questionText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Answer: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                userAnswerText,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Correct Answer: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                correctAnswerText,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            // Action Buttons
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Go back to student home / list
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Back to Quizzes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
