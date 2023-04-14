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

  Future<void> _showUpdateDialog(
      String field, TextEditingController controller) async {
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
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Done"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            onPressed: () async {
              final newValue = controller.text.trim();
              //using the firebaseauth package to update email/password
              //so you can sign in with the new email/password
              if (field == 'email') {
                await _auth.currentUser!.updateEmail(newValue);
              } else if (field == 'password') {
                await _auth.currentUser!.updatePassword(newValue);
              }
              //updating field in firebasestore with new value
              FirebaseFirestore.instance
                  .collection('Users')
                  .doc(_auth.currentUser!.uid)
                  .update({field: newValue}).then((_) {
                //UI dialog to inform user of  updated field
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$field has been updated!'),
                    duration: const Duration(
                      seconds: 2,
                    ),
                  ),
                );
                Navigator.of(context).pop();
              });
            },
          ),
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
                //UI dialog to inform user of  sent email
                scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('Reset Password email sent!'),
                    duration: Duration(
                      seconds: 1,
                    ),
                  ),
                );
                await _showUpdateDialog('password', _passwordController);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Update Email'),
              onTap: () async {
                await _showUpdateDialog('email', _emailController);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Update Username'),
              onTap: () async {
                await _showUpdateDialog('username', _usernameController);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _auth.signOut().then(
                    (_) => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
