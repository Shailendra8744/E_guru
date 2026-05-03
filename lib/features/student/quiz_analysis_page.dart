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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final possibleMaxScore = quiz.questions.fold<int>(0, (sum, q) => sum + q.marks);
    final maxScore = possibleMaxScore > 0 ? possibleMaxScore : 1;
    final percentage = (score / maxScore * 100).round();
    final isPass = percentage >= 40;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: isDark ? const Color(0xFF0D1B2A) : Colors.deepPurple,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPass 
                      ? [Colors.deepPurple, Colors.blueAccent]
                      : [Colors.redAccent, Colors.orangeAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        isPass ? 'QUIZ COMPLETED! 🥳' : 'KEEP TRYING! 💪',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
                      ),
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: percentage / 100,
                              strokeWidth: 12,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$percentage%',
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                '$score/$maxScore',
                                style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
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
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'Detailed Insights',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 16),
                ...quiz.questions.asMap().entries.map((entry) => _buildQuestionAnalysis(entry.key, entry.value, isDark)),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                    shadowColor: Colors.deepPurple.withAlpha(50),
                  ),
                  child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionAnalysis(int index, QuestionModel q, bool isDark) {
    final userAnswer = answers[q.id];
    final isCorrect = userAnswer == q.correctOption;

    String _getOptionText(String? letter) {
      if (letter == 'A') return q.optionA;
      if (letter == 'B') return q.optionB;
      if (letter == 'C') return q.optionC;
      if (letter == 'D') return q.optionD;
      return 'Not answered';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isCorrect ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30), width: 1.5),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.withAlpha(15) : Colors.red.withAlpha(15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isCorrect ? Colors.green : Colors.red, size: 20),
                const SizedBox(width: 8),
                Text('QUESTION ${index + 1}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isCorrect ? Colors.green : Colors.red)),
                const Spacer(),
                Text('${q.marks} Marks', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.questionText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
                const SizedBox(height: 20),
                _buildOptionResult('Your Answer', _getOptionText(userAnswer), isCorrect ? Colors.green : Colors.red, isDark),
                if (!isCorrect) ...[
                  const SizedBox(height: 12),
                  _buildOptionResult('Correct Answer', _getOptionText(q.correctOption), Colors.green, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionResult(String label, String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
