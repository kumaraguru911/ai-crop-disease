import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/chatbot_screen.dart';

void main() {
  testWidgets('answers a disease question from the offline guide', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChatbotScreen()));

    await tester.enterText(
      find.byType(TextField),
      'What are tomato early blight symptoms?',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(find.text('What are tomato early blight symptoms?'), findsOneWidget);
    expect(find.textContaining('concentric rings'), findsOneWidget);
    expect(find.textContaining('not a confirmed diagnosis'), findsOneWidget);
  });
}
