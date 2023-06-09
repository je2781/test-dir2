import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart' as flc;
import 'package:flutter_localizations/flutter_localizations.dart';

import './screens/auth_screen.dart';

import './provider/user_info.dart';
import './provider/country_info.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => Users(FirebaseAuth.instance.currentUser!),
        ),
        ChangeNotifierProvider(
          create: (_) => CountryInfo(),
        )
      ],
      child: MaterialApp(
        title: 'Sports Network',
        supportedLocales: flc.supportedLocales.map((e) => Locale(e)),
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          flc.CountryLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
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
        home: AuthScreen(),
      ),
    );
  }
}
