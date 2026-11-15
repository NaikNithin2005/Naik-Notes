import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/features/ai_assistant/data/ai_study_assistant_provider.dart';
import 'package:naik_notes/services/ai/ai_study_assistant_service.dart';

/// Interactive AI Study Assistant modal sheet providing lecture summaries,
/// flip flashcards, multiple-choice practice quizzes, and formula Q&A.
class AiStudyAssistantSheet extends ConsumerStatefulWidget {
  final String notebookId;
  final String notebookTitle;

  const AiStudyAssistantSheet({
    super.key,
    required this.notebookId,
    required this.notebookTitle,
  });

  @override
  ConsumerState<AiStudyAssistantSheet> createState() =>
      _AiStudyAssistantSheetState();
}

class _AiStudyAssistantSheetState extends ConsumerState<AiStudyAssistantSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Flashcards state
  int _currentCardIndex = 0;
  bool _showAnswer = false;
  bool _showHint = false;

  // Quiz state
  int _currentQuizIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswerSubmitted = false;
  int _quizScore = 0;

  // Chat state
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [
    {
      'role': 'assistant',
      'content': 'Hello! I am your Naik Notes Study Assistant. Ask me anything about your lecture notes, equations, or exam preparation.',
    },
  ];
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header with Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Study Assistant',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.notebookTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.summarize_outlined, size: 20),
                  text: 'Summary',
                ),
                Tab(
                  icon: Icon(Icons.style_outlined, size: 20),
                  text: 'Flashcards',
                ),
                Tab(icon: Icon(Icons.quiz_outlined, size: 20), text: 'Quiz'),
                Tab(
                  icon: Icon(Icons.chat_outlined, size: 20),
                  text: 'Ask Notes',
                ),
              ],
            ),

            // Content Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(),
                  _buildFlashcardsTab(),
                  _buildQuizTab(),
                  _buildChatTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: Summary
  // ==========================================
  Widget _buildSummaryTab() {
    final summaryAsync = ref.watch(notebookSummaryProvider(widget.notebookId));

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading summary: $err')),
      data: (summary) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              summary.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                summary.summaryMarkdown,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Key Concepts Extracted:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.keyConcepts.map((concept) {
                return Chip(
                  avatar: const Icon(Icons.lightbulb_outline, size: 16),
                  label: Text(concept, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Actionable Review Topics:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...summary.studyRecommendations.map((rec) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(rec, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 2: Flashcards
  // ==========================================
  Widget _buildFlashcardsTab() {
    final flashcardsAsync = ref.watch(
      notebookFlashcardsProvider(widget.notebookId),
    );

    return flashcardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          Center(child: Text('Error generating flashcards: $err')),
      data: (cards) {
        if (cards.isEmpty) {
          return const Center(child: Text('No flashcards available.'));
        }

        final card = cards[_currentCardIndex.clamp(0, cards.length - 1)];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Card ${_currentCardIndex + 1} of ${cards.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: card.difficulty == 'easy'
                          ? Colors.green.withValues(alpha: 0.2)
                          : card.difficulty == 'hard'
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      card.difficulty.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: card.difficulty == 'easy'
                            ? Colors.green[800]
                            : card.difficulty == 'hard'
                            ? Colors.red[800]
                            : Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Flip Card
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showAnswer = !_showAnswer),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showAnswer
                                ? Icons.check_circle_outline
                                : Icons.help_outline,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showAnswer ? 'ANSWER:' : 'QUESTION:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _showAnswer ? card.answer : card.question,
                            style: const TextStyle(fontSize: 16, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _showAnswer
                                ? 'Tap to view question'
                                : 'Tap to reveal answer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Hint area
              if (card.hint != null) ...[
                const SizedBox(height: 10),
                if (_showHint)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '💡 Hint: ${card.hint}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                else
                  TextButton.icon(
                    icon: const Icon(Icons.lightbulb_outline, size: 16),
                    label: const Text(
                      'Show Hint',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => setState(() => _showHint = true),
                  ),
              ],

              const SizedBox(height: 16),

              // Prev / Next Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    onPressed: _currentCardIndex > 0
                        ? () {
                            setState(() {
                              _currentCardIndex--;
                              _showAnswer = false;
                              _showHint = false;
                            });
                          }
                        : null,
                  ),
                  FilledButton.icon(
                    label: const Text('Next Card'),
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _currentCardIndex < cards.length - 1
                        ? () {
                            setState(() {
                              _currentCardIndex++;
                              _showAnswer = false;
                              _showHint = false;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: Quiz
  // ==========================================
  Widget _buildQuizTab() {
    final quizAsync = ref.watch(notebookQuizProvider(widget.notebookId));

    return quizAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error generating quiz: $err')),
      data: (questions) {
        if (questions.isEmpty) {
          return const Center(child: Text('No quiz questions available.'));
        }

        final q = questions[_currentQuizIndex.clamp(0, questions.length - 1)];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuizIndex + 1} of ${questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Score: $_quizScore/${questions.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              q.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Options
            ...List.generate(q.options.length, (optIdx) {
              final optionText = q.options[optIdx];
              final isSelected = _selectedOptionIndex == optIdx;
              final isCorrect = optIdx == q.correctAnswerIndex;

              Color? tileColor;
              if (_isAnswerSubmitted) {
                if (isCorrect) {
                  tileColor = Colors.green.withValues(alpha: 0.2);
                } else if (isSelected) {
                  tileColor = Colors.red.withValues(alpha: 0.2);
                }
              } else if (isSelected) {
                tileColor = Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.1);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: tileColor ?? Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      optionText,
                      style: const TextStyle(fontSize: 14),
                    ),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.2),
                      child: Text(
                        String.fromCharCode(65 + optIdx),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    onTap: _isAnswerSubmitted
                        ? null
                        : () => setState(() => _selectedOptionIndex = optIdx),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Submit / Next Buttons
            if (!_isAnswerSubmitted)
              FilledButton(
                onPressed: _selectedOptionIndex != null
                    ? () {
                        setState(() {
                          _isAnswerSubmitted = true;
                          if (_selectedOptionIndex == q.correctAnswerIndex) {
                            _quizScore++;
                          }
                        });
                      }
                    : null,
                child: const Text('Check Answer'),
              )
            else ...[
              // Pedagogical Explanation Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 6),
                        Text(
                          'Explanation:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(q.explanation, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _currentQuizIndex < questions.length - 1
                    ? () {
                        setState(() {
                          _currentQuizIndex++;
                          _selectedOptionIndex = null;
                          _isAnswerSubmitted = false;
                        });
                      }
                    : null,
                child: Text(
                  _currentQuizIndex < questions.length - 1
                      ? 'Next Question'
                      : 'Quiz Completed!',
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 4: Ask Notes / Q&A
  // ==========================================
  Widget _buildChatTab() {
    final aiService = ref.watch(aiStudyAssistantServiceProvider);

    return Column(
      children: [
        // Quick Prompt Suggestions
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.functions, size: 14),
                label: const Text(
                  'Explain main formula',
                  style: TextStyle(fontSize: 11),
                ),
                onPressed: () => _sendChatMessage(
                  'Explain the primary mathematical formula in this notebook',
                  aiService,
                ),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.summarize, size: 14),
                label: const Text(
                  'Summarize this chapter',
                  style: TextStyle(fontSize: 11),
                ),
                onPressed: () => _sendChatMessage(
                  'Provide a 3-point summary of this chapter',
                  aiService,
                ),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.school, size: 14),
                label: const Text(
                  'Key exam tips',
                  style: TextStyle(fontSize: 11),
                ),
                onPressed: () => _sendChatMessage(
                  'What are the most likely exam topics from these notes?',
                  aiService,
                ),
              ),
            ],
          ),
        ),

        // Message List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _chatMessages.length,
            itemBuilder: (ctx, idx) {
              final msg = _chatMessages[idx];
              final isUser = msg['role'] == 'user';

              return Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    msg['content'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_isChatLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          ),

        // Input Field
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: 'Ask about notes, formulas, or theorems...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _sendChatMessage(val.trim(), aiService);
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: () {
                  final text = _chatController.text.trim();
                  if (text.isNotEmpty) {
                    _sendChatMessage(text, aiService);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendChatMessage(String message, AiStudyAssistantService service) async {
    _chatController.clear();
    setState(() {
      _chatMessages.add({'role': 'user', 'content': message});
      _isChatLoading = true;
    });

    try {
      final reply = await service.askAssistant(widget.notebookId, message);
      if (mounted) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': reply});
          _isChatLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'role': 'assistant',
            'content': 'Unable to process query right now. Please try again.',
          });
          _isChatLoading = false;
        });
      }
    }
  }
}
