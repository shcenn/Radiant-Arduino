import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radiant/screens/auth/login_screen.dart';

void main() {
  testWidgets('Validates credentials before calling sign-in', (tester) async {
    var called = false;
    await tester.pumpWidget(MaterialApp(home: LoginScreen(onSignIn: (_, _) async { called = true; })));
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(called, isFalse);
  });

  testWidgets('Passes trimmed email and exact password, then permits retry after failure', (tester) async {
    final attempts = <List<String>>[];
    await tester.pumpWidget(MaterialApp(home: LoginScreen(onSignIn: (email, password) async {
      attempts.add([email, password]);
      throw Exception('Sign-in unavailable');
    })));
    await tester.enterText(find.byType(TextFormField).at(0), ' dashboard@example.com ');
    await tester.enterText(find.byType(TextFormField).at(1), ' private password ');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(attempts.single, ['dashboard@example.com', ' private password ']);
    expect(find.text('Could not sign in. Please try again.'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(attempts.length, 2);
  });
}
