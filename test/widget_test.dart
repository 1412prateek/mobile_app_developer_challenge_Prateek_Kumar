// This is a basic Flutter widget test for Peblo Story Buddy.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_story_buddy/main.dart';

void main() {
  testWidgets('Peblo Story Buddy smoke test', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: PebloApp()));

    // Verify that the title header is rendered.
    expect(find.text('Peblo Story Buddy'), findsOneWidget);

    // Verify that the "Read Me a Story" button is rendered.
    expect(find.text('Read Me a Story'), findsOneWidget);

    // Verify that the quiz card is NOT visible initially.
    expect(find.text('QUIZ TIME!'), findsNothing);
  });
}
