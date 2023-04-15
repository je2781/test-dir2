import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'package:sports_network/data/widget_keys.dart';
import 'package:sports_network/screens/verify_screen.dart';
import 'package:sports_network/screens/tabs_screen.dart';
import 'package:sports_network/widgets/auth_card.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sports_network/firebase_options.dart';

import './mocks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    //initializing firebase sdk in flutter app for android/IOS platform
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final mockObserver = MockNavigatorObserver();
  Widget _createAuthWidget() {
    return MaterialApp(
      routes: {
        '/': (_) => const Scaffold(
              body: AuthCard(),
            ),
        VerifyScreen.routeName: (_) => VerifyScreen(),
        TabsScreen.routeName: (_) => TabsScreen()
      },
      navigatorObservers: [mockObserver],
    );
  }

  testWidgets('switching to signup mode', (tester) async {
    await tester.pumpWidget(_createAuthWidget());

    expect(find.byKey(WidgetKey.emailTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.passwordTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.elevatedButton), findsOneWidget);

    //tap the signup/login text button and trigger frame
    await tester.tap(find.byKey(WidgetKey.textButton1));
    await tester.pump();

    expect(find.byKey(WidgetKey.emailTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.passwordTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.confirmPTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.mobileTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.interestsTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.elevatedButton), findsOneWidget);
    expect(find.byKey(WidgetKey.usernameTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.avatarPreview), findsOneWidget);
  });

  testWidgets('switching to forgot password mode', (tester) async {
    await tester.pumpWidget(_createAuthWidget());

    expect(find.byKey(WidgetKey.emailTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.passwordTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.elevatedButton), findsOneWidget);

    //tap the forgot password text button and trigger frame
    await tester.tap(find.byKey(WidgetKey.textButton2));
    await tester.pump();

    expect(find.byKey(WidgetKey.emailTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.passwordTextField), findsNothing);
    expect(find.byKey(WidgetKey.elevatedButton), findsOneWidget);
  });

  testWidgets('switching to login with mobile mode', (tester) async {
    await tester.pumpWidget(_createAuthWidget());

    expect(find.byKey(WidgetKey.emailTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.passwordTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.elevatedButton), findsOneWidget);

    //tap the popupmenu button and wait for all animations to be complete
    await tester.tap(find.byKey(WidgetKey.popupMenuButton));
    await tester.pumpAndSettle();

    //tap the popupmenu item and wait for all animations to be complete
    await tester.tap(find.byKey(WidgetKey.popupMenuItemLoginWithMobile));
    await tester.pumpAndSettle();

    expect(find.byKey(WidgetKey.emailTextField), findsNothing);
    expect(find.byKey(WidgetKey.passwordTextField), findsNothing);
    expect(find.byKey(WidgetKey.mobileTextField), findsOneWidget);
    expect(find.byKey(WidgetKey.elevatedButton), findsOneWidget);
  });

  testWidgets('to navigate to verify screen onClick of signup button',
      (tester) async {
    await tester.pumpWidget(_createAuthWidget());

    //tap the signup/login text button and trigger frame
    await tester.tap(find.byKey(WidgetKey.textButton1));
    await tester.pump();

    // populate text fields, and provide avatar preview.
    await tester.tap(find.byKey(WidgetKey.textIconButton));
    await tester.pump();
    await tester.enterText(
        find.byKey(WidgetKey.emailTextField), 'test@test.com');
    await tester.pump();
    await tester.enterText(find.byKey(WidgetKey.usernameTextField), 't2');
    await tester.pump();
    await tester.enterText(find.byKey(WidgetKey.passwordTextField), 'zoooo');
    await tester.pump();
    await tester.enterText(find.byKey(WidgetKey.confirmPTextField), 'zoooo');
    await tester.pump();
    await tester.enterText(
        find.byKey(WidgetKey.mobileTextField), '+234 703 637 4586');
    await tester.pump();
    await tester.enterText(
        find.byKey(WidgetKey.interestsTextField), 'Basketball');
    await tester.pump();

    //tap the signup button and wait for all animations to be complete
    await tester.tap(find.byKey(WidgetKey.elevatedButton));
    await tester.pumpAndSettle();
    //verify that a push event happened
    verify(() => mockObserver.didPush(any(), any()));

    //confirming that Verify screen is visible
    expect(find.byType(VerifyScreen), findsOneWidget);
  });
}
