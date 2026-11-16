import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_canvas.dart';
import 'package:naik_notes/features/notebooks/data/page_provider.dart';

/// Interactive Reading Mode page-turn viewer simulating realistic 3D book page curvature,
/// spine shadow gradients, swipe turning, and keyboard arrow controls.
class ReadingModePageFlipView extends ConsumerStatefulWidget {
  final String notebookId;
  final List<NotebookPage> pages;
  final int initialPage;
  final VoidCallback onExitReadingMode;

  const ReadingModePageFlipView({
    super.key,
    required this.notebookId,
    required this.pages,
    required this.initialPage,
    required this.onExitReadingMode,
  });

  @override
  ConsumerState<ReadingModePageFlipView> createState() =>
      _ReadingModePageFlipViewState();
}

class _ReadingModePageFlipViewState
    extends ConsumerState<ReadingModePageFlipView> {
  late final PageController _pageController;
  late int _currentPage;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(
      1,
      math.max(1, widget.pages.length),
    );
    _pageController = PageController(initialPage: _currentPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToNextPage() {
    if (_currentPage < widget.pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.pageUp) {
        _goToPreviousPage();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.pageDown ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _goToNextPage();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onExitReadingMode();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = widget.pages.length;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Stack(
        children: [
          // Background reading ambience (Warm sepia paper / book desk)
          Container(color: const Color(0xFFEFE8D6)),

          // 3D Realistic Page-Turning View
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: totalPages,
            onPageChanged: (index) {
              setState(() => _currentPage = index + 1);
              ref.read(currentPageIndexProvider.notifier).setPage(index + 1);
            },
            itemBuilder: (context, index) {
              final page = widget.pages[index];

              return AnimatedBuilder(
                key: ValueKey('reading_page_${page.id}'),
                animation: _pageController,
                builder: (context, child) {
                  double value = 0.0;
                  if (_pageController.position.haveDimensions) {
                    value =
                        (_pageController.page ?? _currentPage - 1.0) - index;
                  }

                  // 3D Book Page Curl / Turn Perspective Transform
                  final isTurningLeft = value > 0;
                  final turnProgress = value.abs().clamp(0.0, 1.0);
                  // Clamp angle safely within [-pi/5, pi/5] to avoid inverted bleed-through
                  final angle = (value * (math.pi / 5.0)).clamp(
                    -math.pi / 4.0,
                    math.pi / 4.0,
                  );

                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // 3D camera perspective
                    ..rotateY(angle);

                  return ClipRect(
                    child: Center(
                      child: Transform(
                        transform: matrix,
                        alignment: isTurningLeft
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF8),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              // Page spine drop shadow
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.18 + (turnProgress * 0.15),
                                ),
                                blurRadius: 18 + (turnProgress * 12),
                                offset: Offset(isTurningLeft ? -8 : 8, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                // Layer 0: 100% Opaque Solid Paper Base (Eliminates page-tearing bleed-through)
                                const Positioned.fill(
                                  child: ColoredBox(color: Color(0xFFFFFDF8)),
                                ),

                                // Layer 1: Read-only canvas rendering page template and strokes
                                HandwritingCanvas(
                                  key: ValueKey('canvas_${page.id}'),
                                  pageId: page.id,
                                  type: page.templateType,
                                  properties: page.properties,
                                  width: page.width,
                                  height: page.height,
                                  readOnly: true,
                                ),

                                // Layer 2: Dynamic spine curvature lighting gradient
                                if (turnProgress > 0.01)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: isTurningLeft
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          end: isTurningLeft
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          colors: [
                                            Colors.black.withValues(
                                              alpha: 0.22 * turnProgress,
                                            ),
                                            Colors.transparent,
                                            Colors.white.withValues(
                                              alpha: 0.15 * turnProgress,
                                            ),
                                          ],
                                          stops: const [0.0, 0.25, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Top Header Overlay with Exit Reading Mode & Page Progress
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton.tonalIcon(
                  onPressed: widget.onExitReadingMode,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Exit Reading Mode'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF4E342E,
                    ).withValues(alpha: 0.85),
                    foregroundColor: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E342E).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Page $_currentPage of $totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Left / Right Quick Turn Touch Tap Zones
          Positioned(
            left: 12,
            bottom: 30,
            child: IconButton.filledTonal(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              tooltip: 'Previous Page (Left Arrow / Swipe)',
              style: IconButton.styleFrom(
                backgroundColor: const Color(
                  0xFF4E342E,
                ).withValues(alpha: 0.75),
                foregroundColor: Colors.white,
              ),
              onPressed: _currentPage > 1 ? _goToPreviousPage : null,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 30,
            child: IconButton.filledTonal(
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              tooltip: 'Next Page (Right Arrow / Swipe)',
              style: IconButton.styleFrom(
                backgroundColor: const Color(
                  0xFF4E342E,
                ).withValues(alpha: 0.75),
                foregroundColor: Colors.white,
              ),
              onPressed: _currentPage < totalPages ? _goToNextPage : null,
            ),
          ),
        ],
      ),
    );
  }
}
