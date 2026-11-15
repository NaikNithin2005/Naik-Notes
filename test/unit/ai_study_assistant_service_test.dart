import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/search_index_model.dart';
import 'package:naik_notes/data/repositories/page_search_repository.dart';
import 'package:naik_notes/services/ai/ai_study_assistant_service.dart';

void main() {
  group('AiStudyAssistantService Tests', () {
    late AppDatabase db;
    late DriftPageSearchRepository searchRepo;
    late AiStudyAssistantService aiService;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      searchRepo = DriftPageSearchRepository(db);
      aiService = AiStudyAssistantService(pageSearchRepository: searchRepo);

      // Seed note text in search index
      final now = DateTime.now();
      await searchRepo.indexPageContent(
        PageSearchEntry(
          id: 'idx-quantum',
          pageId: 'page-q1',
          notebookId: 'nb-quantum',
          sourceType: 'handwriting',
          textContent:
              ('The Schrodinger equation describes the wave function of a quantum-mechanical system. '
              'Hamiltonian operator represents total energy including kinetic and potential terms. '
              'Boundary conditions enforce normalization where total probability across all space equals one.'),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'collectNotebookContext gathers indexed text from page search repo',
      () async {
        final context = await aiService.collectNotebookContext('nb-quantum');
        expect(context.contains('Schrodinger equation'), true);
        expect(context.contains('Hamiltonian operator'), true);
      },
    );

    test(
      'summarizeNotebook returns structured summary and recommendations',
      () async {
        final summary = await aiService.summarizeNotebook('nb-quantum');
        expect(summary.notebookId, 'nb-quantum');
        expect(summary.title.isNotEmpty, true);
        expect(summary.summaryMarkdown.isNotEmpty, true);
        expect(summary.keyConcepts.isNotEmpty, true);
        expect(summary.studyRecommendations.isNotEmpty, true);
      },
    );

    test(
      'generateFlashcards produces flashcard deck with difficulty ratings',
      () async {
        final cards = await aiService.generateFlashcards(
          'nb-quantum',
          count: 3,
        );
        expect(cards.length, greaterThanOrEqualTo(2));
        final first = cards.first;
        expect(first.question.isNotEmpty, true);
        expect(first.answer.isNotEmpty, true);
        expect(['easy', 'medium', 'hard'].contains(first.difficulty), true);
      },
    );

    test(
      'generateQuiz produces multiple-choice questions with explanations',
      () async {
        final quiz = await aiService.generateQuiz('nb-quantum', count: 2);
        expect(quiz.isNotEmpty, true);
        final q = quiz.first;
        expect(q.options.length, 4);
        expect(q.correctAnswerIndex >= 0 && q.correctAnswerIndex < 4, true);
        expect(q.explanation.isNotEmpty, true);
      },
    );

    test(
      'explainFormula returns LaTeX formatting and variable definitions',
      () async {
        final explanation = await aiService.explainFormula('F = ma');
        expect(explanation.formulaLatex.contains('F = ma'), true);
        expect(explanation.explanation.isNotEmpty, true);
        expect(explanation.practicalApplication.isNotEmpty, true);
      },
    );

    test('askAssistant generates pedagogical reply and follow-ups', () async {
      final reply = await aiService.askAssistant(
        'nb-quantum',
        'Can you summarize the main theorem?',
      );
      expect(reply.isNotEmpty, true);
    });
  });
}
