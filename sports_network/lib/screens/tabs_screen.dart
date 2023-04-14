import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './buddies_screen.dart';
import './discover_screen.dart';
import './profile_screen.dart';
import './setting_privacy_screen.dart';

class TabsScreen extends StatefulWidget {
  final User? user;
  TabsScreen({this.user});
  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  late List<Map<String, Object>> _pages;
  final _auth = FirebaseAuth.instance;
  final _codeController = TextEditingController();

  void _mobileVerificationFailed(FirebaseAuthException e) async {
    var errorMessage = 'Phone Verification Failed!';
    switch (e.code) {
      case 'invalid-phone-number':
        errorMessage = 'The provided phone number is not valid.';
        break;
      default:
        break;
    }

    await _showErrorDialog(errorMessage);
  }

  Future<void> _showErrorDialog(String errorMsg) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'An Error Occurred!',
          style: TextStyle(
            color: Colors.black87,
          ),
        ),
        content: Text(errorMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Okay'),
          )
        ],
      ),
    );
  }

  Future<void> _showSmsCodeDialog(String verificationId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Enter SMS Code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
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
              final smsCode = _codeController.text.trim();
              // Create a PhoneAuthCredential with the code
              final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId, smsCode: smsCode);
              //linking mobile to current user account
              _auth.currentUser!.linkWithCredential(credential).then((_) {
                Navigator.of(context).pop();
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _getAuthVerifyPhone(String mobile) async {
    await _auth.verifyPhoneNumber(
        phoneNumber: mobile,
        verificationCompleted: (credential) async {
          //linking phone auth provider to current user account
          await _auth.currentUser!.linkWithCredential(credential);
        },
        timeout: const Duration(seconds: 60),
        verificationFailed: (e) => _mobileVerificationFailed(e),
        codeSent: (String verificationId, int? forceResendingToken) async {
          //show dialog to take sms code from the user
          await _showSmsCodeDialog(verificationId);
        },
        codeAutoRetrievalTimeout: (_) {});
  }

  @override
  void initState() {
    // TODO: implement initStatel
    super.initState();
    //stopping phoneauthprovider from attempting to link with already linked provider
    if (widget.user == null) {
      //connecting to firebasestore api to retrieve user mobile, and link it to email/password auth provider
      FirebaseFirestore.instance
          .collection('Users')
          .doc(_auth.currentUser!.uid)
          .get()
          .then((doc) async {
        await _getAuthVerifyPhone(doc['mobile']);
      });
    }

    //setting up menus for tabscreen
    _pages = [
      {"page": ProfileScreen(), "title": 'Profile'},
      {"page": BuddiesScreen(), "title": 'Buddies'},
      {"page": DiscoverScreen(), "title": 'Discover'},
      {"page": SettingPrivacyScreen(), "title": 'Settings'}
    ];
  }

  //disposing controllers to prevent memory leaks
  @override
  void dispose() {
    super.dispose();
    _codeController.dispose();
  }

  //initializing page index
  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedPageIndex]['title'] as String),
      ),
      body: _pages[_selectedPageIndex]['page'] as Widget,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        backgroundColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.primary,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        currentIndex: _selectedPageIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake),
            label: 'Buddies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
