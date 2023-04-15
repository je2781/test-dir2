import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Users with ChangeNotifier {
  final User user;
  Users(this.user);
  Future<DocumentSnapshot<Map<String, dynamic>>> get userData async {
    return FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
  }
}
