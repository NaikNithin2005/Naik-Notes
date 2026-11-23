import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Modal dialog for authoring and inserting clean LaTeX formulas
/// with quick-insert symbol chips and live Math.tex rendering.
class MathFormulaDialog extends StatefulWidget {
  final String initialFormula;

  const MathFormulaDialog({super.key, this.initialFormula = ''});

  static Future<String?> show(BuildContext context, {String initialFormula = ''}) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => MathFormulaDialog(initialFormula: initialFormula),
    );
  }

  @override
  State<MathFormulaDialog> createState() => _MathFormulaDialogState();
}

class _MathFormulaDialogState extends State<MathFormulaDialog> {
  late final TextEditingController _controller;
  String _currentLatex = '';

  final List<(String label, String code)> _chips = [
    ('Fraction', r'\frac{a}{b}'),
    ('Square Root', r'\sqrt{x}'),
    ('Summation', r'\sum_{i=1}^{n} x_i'),
    ('Integral', r'\int_{a}^{b} f(x) dx'),
    ('Power (^)', r'x^{2}'),
    ('Subscript (_)', r'x_{i}'),
    ('π (pi)', r'\pi'),
    ('θ (theta)', r'\theta'),
    ('α (alpha)', r'\alpha'),
    ('β (beta)', r'\beta'),
    ('∞ (infinity)', r'\infty'),
    ('± (plus-minus)', r'\pm'),
    ('× (times)', r'\times'),
    ('≤ (leq)', r'\leq'),
    ('≥ (geq)', r'\geq'),
    ('Δ (delta)', r'\Delta'),
    ('∂ (partial)', r'\partial'),
  ];

  @override
  void initState() {
    super.initState();
    _currentLatex = widget.initialFormula.isNotEmpty
        ? widget.initialFormula
        : r'E = mc^2';
    _controller = TextEditingController(text: _currentLatex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insertChip(String code) {
    final text = _controller.text;
    final selection = _controller.selection;
    final newText = selection.isValid
        ? text.replaceRange(selection.start, selection.end, code)
        : '$text $code';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.isValid ? selection.start + code.length : newText.length,
      ),
    );
    setState(() => _currentLatex = newText);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.functions_rounded, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text('Insert LaTeX Equation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live Equation Preview Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0x33FFFFFF) : const Color(0x18000000),
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Math.tex(
                    _currentLatex.trim().isEmpty ? r'\text{Type equation below}' : _currentLatex,
                    textStyle: TextStyle(
                      fontSize: 22,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onErrorFallback: (err) => Text(
                      'Invalid LaTeX syntax',
                      style: TextStyle(color: Colors.red[400], fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Quick Symbol Chips
            const Text(
              'Quick Symbol Chips',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _chips.map((c) {
                return ActionChip(
                  label: Text(c.$1, style: const TextStyle(fontSize: 11)),
                  onPressed: () => _insertChip(c.$2),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // LaTeX Input TextField
            TextField(
              controller: _controller,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'LaTeX Source',
                hintText: r'e.g. \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (val) => setState(() => _currentLatex = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Insert Equation'),
          onPressed: _currentLatex.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_currentLatex.trim()),
        ),
      ],
    );
  }
}

