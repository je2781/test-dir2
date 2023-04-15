import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './auth_screen.dart';

class SettingPrivacyScreen extends StatefulWidget {
  static const routeName = '/setting_privacy';

  @override
  State<SettingPrivacyScreen> createState() => _SettingPrivacyScreenState();
}

class _SettingPrivacyScreenState extends State<SettingPrivacyScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  //disposing controllers to prevent memory leaks
  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
  }

  Future<void> _handleDialog(String field, TextEditingController controller,
      NavigatorState navigator, ScaffoldMessengerState scaffold) async {
    final newValue = controller.text.trim();

    try {
      //using the firebaseauth api to update email/username
      //so you can sign in with the new email/username
      if (field == 'email') {
        await _auth.currentUser!.updateEmail(newValue);
        //updating field in firebasestore with new value
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(_auth.currentUser!.uid)
            .update({field: newValue});
      } else if (field == 'password') {
        await _auth.currentUser!.updatePassword(newValue);
      } else {
        //updating field in firebasestore with new value
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(_auth.currentUser!.uid)
            .update({field: newValue});
      }

      //UI dialog to inform user of  updated field
      scaffold.showSnackBar(
        SnackBar(
          content: Text('$field has been updated!'),
          duration: const Duration(
            seconds: 2,
          ),
        ),
      );
      //clearing field controller
      controller.clear();
      //pop the dialog from the stack of routes

      navigator.pop();
    } on FirebaseAuthException catch (err) {
      var message = 'There was an error updating your credentials';

      if (err.message != null) {
        message = err.message!;
      }

      //scaffold page UI info dialog, informing on error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    }
  }

  Future<void> _showUpdateDialog(String field, TextEditingController controller,
      NavigatorState navigator, ScaffoldMessengerState scaffold) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Enter new value for $field"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              obscureText: field == 'password' ? true : false,
              onSubmitted: (_) =>
                  _handleDialog(field, controller, navigator, scaffold),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
              child: Text("Done"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              onPressed: () =>
                  _handleDialog(field, controller, navigator, scaffold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change Password'),
              onTap: () async {
                await _showUpdateDialog(
                    'password', _passwordController, navigator, scaffold);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Update Email'),
              onTap: () async {
                await _showUpdateDialog(
                    'email', _emailController, navigator, scaffold);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Update Username'),
              onTap: () async {
                await _showUpdateDialog(
                    'username', _usernameController, navigator, scaffold);
              },
            ),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await _auth.signOut();
                  navigator.pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => AuthScreen(),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }
}
