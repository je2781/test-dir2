import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingPrivacyScreen extends StatefulWidget {
  static const routeName = '/setting_privacy';

  @override
  State<SettingPrivacyScreen> createState() => _SettingPrivacyScreenState();
}

class _SettingPrivacyScreenState extends State<SettingPrivacyScreen> {
  final auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

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
              await FirebaseFirestore.instance
                  .collection('Products')
                  .doc(auth.currentUser!.uid)
                  .set({field: newValue});
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings And Privacy'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change Password'),
              onTap: () async {
                await auth.sendPasswordResetEmail(
                    email: auth.currentUser!.email!);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Update Email'),
              onTap: () async {
                await _showUpdateDialog('Email', _emailController);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Update Username'),
              onTap: () async {
                await _showUpdateDialog('Username', _usernameController);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
