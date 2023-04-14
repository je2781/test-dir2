import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './tabs_screen.dart';

class VerifyScreen extends StatefulWidget {
  VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  late Timer timer;
  // late NavigatorState navigator;
  final auth = FirebaseAuth.instance;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero).then((_) {
      // navigator = Navigator.of(context);
      auth.currentUser!.sendEmailVerification();
      timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _checkEmailIsVerified();
      });
    });
  }

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

  Future<void> _checkEmailIsVerified() async {
    await auth.currentUser!.reload();
    if (auth.currentUser!.emailVerified) {
      timer.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TabsScreen(),
        ),
      );
    }
  }
}
