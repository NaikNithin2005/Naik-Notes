import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/services/ai/ai_study_assistant_service.dart';

/// Global provider for the AiStudyAssistantService.
final aiStudyAssistantServiceProvider = Provider<AiStudyAssistantService>((
  ref,
) {
  final pageSearchRepo = ref.watch(pageSearchRepositoryProvider);
  return AiStudyAssistantService(pageSearchRepository: pageSearchRepo);
});

/// Asynchronous lecture summary data for a notebook.
final notebookSummaryProvider = FutureProvider.family<AiSummaryData, String>((
  ref,
  notebookId,
) async {
  final service = ref.watch(aiStudyAssistantServiceProvider);
  return service.summarizeNotebook(notebookId);
});

/// Asynchronous generated flashcard deck for a notebook.
final notebookFlashcardsProvider =
    FutureProvider.family<List<AiFlashcard>, String>((ref, notebookId) async {
      final service = ref.watch(aiStudyAssistantServiceProvider);
      return service.generateFlashcards(notebookId);
    });

/// Asynchronous generated practice quiz for a notebook.
final notebookQuizProvider =
    FutureProvider.family<List<AiQuizQuestion>, String>((
      ref,
      notebookId,
    ) async {
      final service = ref.watch(aiStudyAssistantServiceProvider);
      return service.generateQuiz(notebookId);
    });
