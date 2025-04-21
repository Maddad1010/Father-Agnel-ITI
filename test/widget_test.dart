import 'package:flutter_test/flutter_test.dart';

import 'package:fragneliti_clone/main.dart'; // Ensure this import matches your project structure

void main() {
  testWidgets('Home Page loads and displays welcome message', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const FragnelITApp());

    // Verify that our initial state is correct.
    expect(find.text('Welcome to Fr. Agnel ITI'), findsOneWidget); // Check for welcome text
    expect(find.text('Learn. Grow. Succeed.'), findsOneWidget); // Check for secondary text
  });
}
