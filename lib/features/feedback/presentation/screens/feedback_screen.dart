import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../data/feedback_service.dart';

/// Screen and dialog for submitting user feedback, bug reports, and ratings.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
          child: const FeedbackScreen(),
        ),
      ),
    );
  }

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Bug Report';
  int _selectedRating = 5;
  bool _isSubmitting = false;

  final List<String> _categories = const [
    'Bug Report',
    'Feature Request',
    'Apple Pencil & Stylus',
    'Sync & Performance',
    'General Feedback',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final service = ref.read(feedbackServiceProvider);
      await service.submitFeedback(
        category: _selectedCategory,
        rating: _selectedRating,
        description: _descriptionController.text,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your feedback has been submitted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go(RouteNames.dashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send App Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RouteNames.dashboard);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we make Naik Notes better?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your reports directly guide our iPadOS, Android, and Windows development roadmap.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              Text(
                'Feedback Category',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Rating Stars
              Text(
                'Overall Experience Rating',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 32,
                    icon: Icon(
                      starNum <= _selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber[700],
                    ),
                    onPressed: () => setState(() => _selectedRating = starNum),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Description Form Field
              Text(
                'Description & Details',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      'Describe what happened, what you expected, or your idea...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your comments or issue description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Sending...' : 'Submit Feedback'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
