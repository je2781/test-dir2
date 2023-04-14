import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import './screens/auth_screen.dart';
import './screens/setting_privacy_screen.dart';
import './screens/buddies_screen.dart';
import './screens/discover_screen.dart';
import './screens/profile_screen.dart';
import './screens/tabs_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    //initializing firebase sdk in flutter app for android/IOS platform
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Network',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.purple,
        ).copyWith(
          secondary: Colors.deepOrange,
        ),
        fontFamily: 'Lato',
          textTheme: ThemeData.light().textTheme.copyWith(
                headline6: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Lato',
                ),
              ),
          appBarTheme: AppBarTheme(
            titleTextStyle: ThemeData.light()
                .textTheme
                .copyWith(
                  headline6: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Lato',
                  ),
                )
                .headline6,
          ),
      ),
      routes: {
        '/': (_) => AuthScreen(),
        TabsScreen.routeName: (_) => TabsScreen(),
        BuddiesScreen.routeName: (_) => BuddiesScreen(),
        DiscoverScreen.routeName: (_) => DiscoverScreen(),
        ProfileScreen.routeName: (_) => ProfileScreen(),
        SettingPrivacyScreen.routeName: (_) => SettingPrivacyScreen()
    },
    );
  }
}
