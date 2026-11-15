import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/core/presentation/responsive_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResponsiveLayout & Breakpoints Tests', () {
    testWidgets(
      'ResponsiveBuilder reports FormFactor.compact on narrow screens',
      (tester) async {
        tester.view.physicalSize = const Size(500, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        FormFactor? capturedFactor;

        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveBuilder(
              builder: (context, factor, constraints) {
                capturedFactor = factor;
                return Text('Factor: ${factor.name}');
              },
            ),
          ),
        );

        expect(capturedFactor, FormFactor.compact);
        expect(find.text('Factor: compact'), findsOneWidget);
      },
    );

    testWidgets(
      'ResponsiveBuilder reports FormFactor.medium on tablet screens',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        FormFactor? capturedFactor;

        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveBuilder(
              builder: (context, factor, constraints) {
                capturedFactor = factor;
                return Text('Factor: ${factor.name}');
              },
            ),
          ),
        );

        expect(capturedFactor, FormFactor.medium);
        expect(find.text('Factor: medium'), findsOneWidget);
      },
    );

    testWidgets(
      'ResponsiveBuilder reports FormFactor.expanded on desktop screens',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        FormFactor? capturedFactor;

        await tester.pumpWidget(
          MaterialApp(
            home: ResponsiveBuilder(
              builder: (context, factor, constraints) {
                capturedFactor = factor;
                return Text('Factor: ${factor.name}');
              },
            ),
          ),
        );

        expect(capturedFactor, FormFactor.expanded);
        expect(find.text('Factor: expanded'), findsOneWidget);
      },
    );

    testWidgets(
      'ResponsiveLayout selects appropriate widget tree per breakpoint',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1.0;

        // 1. Compact screen
        tester.view.physicalSize = const Size(450, 600);
        await tester.pumpWidget(
          const MaterialApp(
            home: ResponsiveLayout(
              compact: Text('Compact View'),
              medium: Text('Medium View'),
              expanded: Text('Expanded View'),
            ),
          ),
        );

        expect(find.text('Compact View'), findsOneWidget);
        expect(find.text('Medium View'), findsNothing);
        expect(find.text('Expanded View'), findsNothing);

        // 2. Medium tablet screen
        tester.view.physicalSize = const Size(750, 600);
        await tester.pumpWidget(
          const MaterialApp(
            home: ResponsiveLayout(
              compact: Text('Compact View'),
              medium: Text('Medium View'),
              expanded: Text('Expanded View'),
            ),
          ),
        );

        expect(find.text('Medium View'), findsOneWidget);
        expect(find.text('Compact View'), findsNothing);

        // 3. Expanded desktop screen
        tester.view.physicalSize = const Size(1400, 600);
        await tester.pumpWidget(
          const MaterialApp(
            home: ResponsiveLayout(
              compact: Text('Compact View'),
              medium: Text('Medium View'),
              expanded: Text('Expanded View'),
            ),
          ),
        );

        expect(find.text('Expanded View'), findsOneWidget);
        expect(find.text('Medium View'), findsNothing);
      },
    );

    testWidgets(
      'ResponsiveContext computes recommended grid columns correctly',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1.0;

        int? columns;

        tester.view.physicalSize = const Size(400, 800);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                columns = context.recommendedGridColumns;
                return Text('Cols: $columns');
              },
            ),
          ),
        );
        expect(columns, 1);

        tester.view.physicalSize = const Size(700, 900);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                columns = context.recommendedGridColumns;
                return Text('Cols: $columns');
              },
            ),
          ),
        );
        expect(columns, 2);

        tester.view.physicalSize = const Size(950, 900);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                columns = context.recommendedGridColumns;
                return Text('Cols: $columns');
              },
            ),
          ),
        );
        expect(columns, 3);

        tester.view.physicalSize = const Size(1300, 900);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                columns = context.recommendedGridColumns;
                return Text('Cols: $columns');
              },
            ),
          ),
        );
        expect(columns, 4);
      },
    );
  });
}
