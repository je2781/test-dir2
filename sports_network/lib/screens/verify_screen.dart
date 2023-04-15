import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './tabs_screen.dart';

class VerifyScreen extends StatefulWidget {
  static const routeName = '/verify_screen';
  VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  late Timer timer;
  // creating an instance of firebaseauth using the api,
  final auth = FirebaseAuth.instance;
  NavigatorState? navigator;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero).then((_) {
      navigator = Navigator.of(context);
      auth.currentUser!.sendEmailVerification();
      //initializing timer to check if email is verified every 2 sec
      timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _checkEmailIsVerified(navigator!);
      });
    });
  }

  //disposing timer to prevent memory leaks
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'An email has been sent to ${auth.currentUser!.email}. Please verify',
          softWrap: true,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _checkEmailIsVerified(NavigatorState navigator) async {
    await auth.currentUser!.reload();
    if (auth.currentUser!.emailVerified) {
      //disposing timer to prevent memory leaks
      timer.cancel();
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => TabsScreen(),
        ),
      );
    }
  }
}
