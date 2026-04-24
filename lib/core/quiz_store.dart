import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_guru/core/auth_store.dart';

class QuestionModel {
  final int id;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final int marks;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.marks = 1,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      questionText: json['question_text'] ?? '',
      optionA: json['option_a'] ?? '',
      optionB: json['option_b'] ?? '',
      optionC: json['option_c'] ?? '',
      optionD: json['option_d'] ?? '',
      correctOption: json['correct_option'] ?? 'A',
      marks: int.tryParse(json['marks']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption,
      'marks': marks,
    };
  }

  List<String> get optionsList => [optionA, optionB, optionC, optionD];
}

class QuizModel {
  final int id;
  final String title;
  final String? description;
  final int subjectId;
  final int teacherId;
  final int totalMarks;
  final int? timeLimitMinutes;
  final bool isActive;
  final List<QuestionModel> questions;

  QuizModel({
    required this.id,
    required this.title,
    this.description,
    required this.subjectId,
    required this.teacherId,
    required this.totalMarks,
    this.timeLimitMinutes,
    required this.isActive,
    this.questions = const [],
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      subjectId: int.tryParse(json['subject_id']?.toString() ?? '0') ?? 0,
      teacherId: int.tryParse(json['teacher_id']?.toString() ?? '0') ?? 0,
      totalMarks: int.tryParse(json['total_marks']?.toString() ?? '0') ?? 0,
      timeLimitMinutes: json['time_limit_minutes'] != null
          ? int.tryParse(json['time_limit_minutes'].toString())
          : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      questions:
          (json['questions'] as List?)
              ?.map((q) => QuestionModel.fromJson(q))
              .toList() ??
          [],
    );
  }
}

// Provider to fetch list of active quizzes for a student
final studentQuizzesProvider = FutureProvider<List<QuizModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/student/quizzes'); // Example endpoint
  if (response['quizzes'] is List) {
    return (response['quizzes'] as List)
        .map((q) => QuizModel.fromJson(q))
        .toList();
  }
  return [];
});

// Provider to fetch a specific quiz details (with questions)
final quizDetailsProvider = FutureProvider.family<QuizModel, int>((
  ref,
  quizId,
) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get(
    '/student/quizzes/$quizId',
  ); // Example endpoint
  if (response['quiz'] != null) {
    return QuizModel.fromJson(response['quiz']);
  }
  throw Exception("Quiz details not found");
});
